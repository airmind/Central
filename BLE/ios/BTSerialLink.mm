//
//  BTSerialLink.m
//  qgroundcontrol
//
//  Created by ning roland on 10/13/15.
//
//



#include <QTimer>
#include <QList>
#include <QDebug>
#include <QMutexLocker>
#include <iostream>
#include "LinkManager.h"
#include "QGC.h"
#include <QHostInfo>
#include <QSignalSpy>

#import "BTSerialLink_objc.h"
#include "BTSerialLink.h"

#import "ConnectPopoverViewController.h"

static NSString * const kServiceUUID = @"FC00"; //mindstick
static NSString * const kCharacteristicUUID = @"FC20";
static NSString * const kCharacteristicInputstickUUID = @"FC21";  //inputstick
static NSString * const kCharacteristicCaliberationUUID = @"FC22";  //caliberation
static NSString * const kCharacteristicAltitudeUUID = @"FC24";  //parameter - altitude
static NSString * const kWrriteCharacteristicUUID = @"FC21";  //selectedobject
static NSString * const kWrriteCharacteristicConfigureUUID = @"FC26";  //selectedobject
static NSString * const kWrriteCharacteristicMAVDataUUID = @"FC28";  //selectedobject

/****
 
 Bluetooth peripheral looking for: MindStick
 
 Service 1. MAV data transfer
 Characteristic(write): tracking object,
 Characteristic(read): visual object trajectory.
 Characteristic(read): confidence
 Characteristic(write): setpoints
 Characteristic(write): subscribe(?)
 
 Service 2. Configuration
 Characteristic(read): result
 Characteristic(write): parameter/value (mode, name)
 
 Service 3. Calibration
 Characteristic(read): sensor data
 Characteristic(write): item
 
 Service 4. Joystick
 Characteristic(read): sensor data
 
 *****/



@interface BLEHelper_objc ()<CBCentralManagerDelegate,CBPeripheralDelegate>
{
    //CBCharacteristic *writeCharacteristic;
    CBCentralManager* centralmanager;
    dispatch_queue_t ble_q;
    dispatch_semaphore_t ble_q_Semaphore;
    BLE_Discovered_Peripheral_List* discoveredPeripherals;
    id delegatecontroller;

}
+(BLEHelper_objc*)sharedInstance;
-(CBCentralManager*)getBLECentralManager;
-(CBPeripheralManager*)getBLEPeripheralManager;

-(BOOL) setCallbackDelegate:(NSObject*)delegate;
-(BOOL) discover:(NSObject*)delegate;
-(BOOL) discoverServices:(NSObject*)delegate;
-(BOOL) discoverCharacteristics:(NSObject*)delegate;
-(void) stopScanning;

@end


@implementation BLE_LowPassFilter_objc

-(BLE_LowPassFilter_objc*)init {
    [super init];

    for (int i=0; i<LP_RSSI_WINDOW_LENGTH; i++) {
        lp_win[i] = -100;
    }
    rp = 0;
    return self;
}

-(int)filteredRssi {
    int x=0;
    for (int i=0; i<LP_RSSI_WINDOW_LENGTH; i++) {
        x += lp_win[i];
    }
    
    return x/LP_RSSI_WINDOW_LENGTH;
}

-(void)updateWindowWith:(int)rssi {
    if (rp<9) {
        rp = rp + 1;
        lp_win[rp] = rssi;
        
    }
    else {
        rp = 0;
        lp_win[rp] = rssi;
    }

}


@end

@implementation BLE_Discovered_Peripheral

-(BLE_Discovered_Peripheral*)init {
    [super init];
    
    lp_filter = [[BLE_LowPassFilter_objc alloc] init];
    inrange = NO;
    connected = NO;
    
    return self;
}

-(void)isInRange {
    inrange=YES;
}

-(void)outOfRange {
    inrange=NO;
}

-(void)isConnected {
    connected=YES;
}

-(void)isDisconnected {
    connected=NO;
}

-(int)getFilteredRssi:(int)rssi {
    [lp_filter updateWindowWith:rssi];
    return [lp_filter filteredRssi];
}


@end


@implementation BLE_Discovered_Peripheral_List

-(BLE_Discovered_Peripheral*)containsPeripheral:(CBPeripheral*)p {
    //BOOL found = NO;
    for (BLE_Discovered_Peripheral* btp in self) {
        if ([p isEqual:btp.peripheral]) {
            return btp;
            
        }
    }
    return nil;
}

-(NSUInteger)indexOfPeripheral:(CBPeripheral*)p {
    //BOOL found = NO;
    int idx = 0;
    for (BLE_Discovered_Peripheral* btp in self) {
        if ([p isEqual:btp.peripheral]) {
            return idx;
            
        }
        idx ++;
    }
    return NSNotFound;
}

-(BOOL)addPeripheral:(BLE_Discovered_Peripheral*)p {
    [self addObject:p];
    return YES;
}

-(BOOL)removePeripheral:(BLE_Discovered_Peripheral*)p {
    NSUInteger idx = [self indexOfPeripheral:p.peripheral];
    if (idx != NSNotFound) {
        [self removeObjectAtIndex:idx];
        return YES;
    }
    return NO;
    
}

-(NSArray*)getInRangePeripheralList {
    NSMutableArray* in_array = [[NSMutableArray alloc] initWithCapacity:0];
    for (BLE_Discovered_Peripheral* blep in self) {
        if (blep.inrange == YES) {
            [in_array addObject:blep];
        }
    }
    return in_array;
}

-(NSArray*)getOutOfRangePeripheralList {
    NSMutableArray* out_array = [[NSMutableArray alloc] initWithCapacity:0];
    for (BLE_Discovered_Peripheral* blep in self) {
        if (blep.inrange == NO) {
            [out_array addObject:blep];
        }
    }
    return out_array;

}



@end


@implementation BLEHelper_objc


+(BLEHelper_objc*)sharedInstance{
    static BLEHelper_objc* sharedInstance;
    
    @synchronized(self)
    {
        if (!sharedInstance) {
            sharedInstance = [[BLEHelper_objc alloc] init];
        }
        
        return sharedInstance;
    }

}

-(id)init {
    [super init];

    //create a queue;
    ble_q = dispatch_queue_create("bleQ", DISPATCH_QUEUE_SERIAL); //FIFO queue;

    //init cbcentralmanager;
    centralmanager = [[CBCentralManager alloc] initWithDelegate:self queue:ble_q];
    discoveredPeripherals = [[BLE_Discovered_Peripheral_List alloc] initWithCapacity:0];
    
    
    
    //init timer;
    t1 = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                     target:self
                                   selector:@selector(flipflag:)
                                   userInfo:nil
                                    repeats:YES];
    
    sync = NO;
    return self;
}

-(void)flipflag :(id)sender{
    sync = YES;
}

-(BOOL) setCallbackDelegate:(NSObject*)delegate{
    delegatecontroller = delegate;
    
}


-(BOOL) discover:(NSObject*)delegate{
    [self centralManagerDidUpdateState:centralmanager];
    
}

-(void) stopScanning {
    [centralmanager stopScan];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state)
    {
        case CBCentralManagerStatePoweredOn:
        {
            [centralmanager scanForPeripheralsWithServices:nil/*@[ [CBUUID UUIDWithString:kServiceUUID]]*/
                                                 options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
        }
            break;
        default:
        {
            NSLog(@"Central Manager did change state");
        }
            break;
    }
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (RSSI.integerValue > -15) {
        //not reasonable value, simply return;
        return;
    }

    BLE_Discovered_Peripheral* p = [discoveredPeripherals containsPeripheral:peripheral];
    if (p == nil) {
        //newly discovered, initialize;
        p = [[BLE_Discovered_Peripheral alloc] init];
        p.peripheral = peripheral;
        [discoveredPeripherals addPeripheral:p];
    }
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);

    int averagedRSSI = [p getFilteredRssi:RSSI.integerValue];

    
    // Reject any where the value is above reasonable range, or if the signal strength is too low to be close enough (Close is around -22dB)
    /*
    
    int averagedRSSI = [self lowpass_rssi:lp_win];
    */
    //if (check==YES) {
        
    
    if (averagedRSSI < -50/*-35*/)
    {
        //remove from in range list;
        NSLog(@"not in range, return ...");

        [p isInRange];
        /*
        if(seen==YES) {
            NSUInteger idx = [discoveredPeripherals indexOfPeripheral:peripheral];
            [discoveredPeripherals removeObjectAtIndex:idx];
            [(ConnectPopoverViewController*)delegatecontroller didDiscoverBTLinks:peripheral action:0];
        }
         */
        //return;
    }
    
    else {
        [p outOfRange];
    }
    /*
    // Ok, it's in range - have we already seen it?
    if ([discoveredPeripherals containsObject:peripheral]==NO)
    {
        
        // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
        [discoveredPeripherals addObject:peripheral];
        
        // call back;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            
            [(ConnectPopoverViewController*)delegatecontroller didDiscoverBTLinks:peripheral action:1];
            
            
        });
    }*/
    
    NSArray* p_in = [discoveredPeripherals getInRangePeripheralList];
    NSArray* p_out = [discoveredPeripherals getOutOfRangePeripheralList];
        
        if (sync == YES) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                
                [(ConnectPopoverViewController*)delegatecontroller didDiscoverBTLinksInRange:p_in outOfRange:p_out];
                
                
            });
            
        }
        sync = NO;
    
}


@end

@interface BTSerialLink_objc ()<CBCentralManagerDelegate,CBPeripheralDelegate>
{
    CBCharacteristic *writeCharacteristic;
    
}
@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSObject* centraldelegate;
@property (nonatomic, strong) NSObject* peripheraldelegate;


@end

/// @file
///     @brief TCP link type for SITL support
///
///     @author Don Gagne <don@thegagnes.com>

class BLEHelperWrapper {
    BLEHelper_objc* ble_objc;
public:
    BLEHelperWrapper();
    ~BLEHelperWrapper();
    
    void setCallbackDelegate(void*);
    void discover(void*);
    void discoverServices(void*);
    void discoverCharacteristics(void*);
    void stopScanning();
};

BLEHelperWrapper::BLEHelperWrapper () {
    ble_objc = [BLEHelper_objc sharedInstance];
}

BLEHelperWrapper::~BLEHelperWrapper () {

}

void BLEHelperWrapper::setCallbackDelegate(void* delegate) {
    [ble_objc setCallbackDelegate:(__bridge id)delegate];
}


void BLEHelperWrapper::discover(void*) {
    [ble_objc discover:nil];
}

void BLEHelperWrapper::discoverServices(void*) {
    [ble_objc discoverServices:nil];
}

void BLEHelperWrapper::discoverCharacteristics(void*) {
    [ble_objc discoverCharacteristics:nil];
}

void BLEHelperWrapper::stopScanning() {
    [ble_objc stopScanning];
}


/**
 BTSerialConfigurationWrapper
 
 **/

class BTSerialConfigurationWrapper {
    BTSerialConfiguration_objc* btc_objc;
public:
    BTSerialConfigurationWrapper();
    ~BTSerialConfigurationWrapper();
    
    
};

class BTSerialLinkWrapper {
    BTSerialLink_objc* btl_objc;
public:
    BTSerialLinkWrapper();
    ~BTSerialLinkWrapper();
    
    //bool _discover(void*);
    bool _connect();
};


BTSerialConfigurationWrapper::BTSerialConfigurationWrapper() {
    btc_objc = [[BTSerialConfiguration_objc alloc] init];
}

BTSerialLinkWrapper::BTSerialLinkWrapper() {
    btl_objc = [[BTSerialLink_objc alloc] init];
}

bool BTSerialLinkWrapper::_connect() {
    //btl_objc = [[BTSerialLink_objc alloc] init];
}


/**
 BLEHelper class
 **/

BLEHelper::BLEHelper(){
    ble_wrapper = new BLEHelperWrapper();

}

BLEHelper::~BLEHelper() {
    if (ble_wrapper != NULL) {
        delete ble_wrapper;
    }
}

void BLEHelper::setCallbackDelegate(void* delegate) {

    ble_wrapper->setCallbackDelegate(delegate);
}


void BLEHelper::discover(void*) {
    ble_wrapper->discover(nil);
}

void BLEHelper::discoverServices(void*){
    ble_wrapper->discoverServices(nil);
}

void BLEHelper::discoverCharacteristics(void*){
    ble_wrapper->discoverCharacteristics(nil);
}

void BLEHelper::stopScanning(){
    ble_wrapper->stopScanning();
}


/*
 BTSerialLink class;
 */
BTSerialLink::BTSerialLink(BTSerialConfiguration *config)
//, _socket(NULL)
//, _socketIsConnected(false)
{
    _config = config;
    Q_ASSERT(_config != NULL);

    btlwrapper = new BTSerialLinkWrapper();
    
    btlwrapper=new BTSerialLinkWrapper();
    // We're doing it wrong - because the Qt folks got the API wrong:
    // http://blog.qt.digia.com/blog/2010/06/17/youre-doing-it-wrong/
    //moveToThread(this);
    qDebug() << "Bluetooth serial comm Created " << _config->name();
}

BTSerialLink::~BTSerialLink()
{
    _disconnect();
    // Tell the thread to exit
    //quit();
    // Wait for it to exit
    //wait();
}

void BTSerialLink::run()
{
    /*
    _hardwareConnect();
    exec();
     */
}


#ifdef BTSERIALLINK_READWRITE_DEBUG
void BTSerialLink::_writeDebugBytes(const char *data, qint16 size)
{
    //[btcwrapper->btc_objc ]
    QString bytes;
    QString ascii;
    for (int i=0; i<size; i++)
    {
        unsigned char v = data[i];
        bytes.append(QString().sprintf("%02x ", v));
        if (data[i] > 31 && data[i] < 127)
        {
            ascii.append(data[i]);
        }
        else
        {
            ascii.append(219);
        }
    }
    qDebug() << "Sent" << size << "bytes to" << _config->address().toString() << ":" << _config->port() << "data:";
    qDebug() << bytes;
    qDebug() << "ASCII:" << ascii;
}
#endif



void BTSerialLink::writeBytes(const char* data, qint64 size)
{
    /*
#ifdef BTSERIALLINK_READWRITE_DEBUG
    _writeDebugBytes(data, size);
#endif
    _socket->write(data, size);
    _logOutputDataRate(size, QDateTime::currentMSecsSinceEpoch());
     */
}


void BTSerialLink::writeMAVDataBytes(const char* data, qint64 size) {
    
}


void BTSerialLink::writeBytes(QString characteristic, const char* data, qint64 size) {
    
}

/**
 * @brief Read a number of bytes from the interface.
 *
 * @param data Pointer to the data byte array to write the bytes to
 * @param maxLength The maximum number of bytes to write
 **/


void BTSerialLink::readBytes()
{
    /*
    qint64 byteCount = _socket->bytesAvailable();
    if (byteCount)
    {
        QByteArray buffer;
        buffer.resize(byteCount);
        _socket->read(buffer.data(), buffer.size());
        emit bytesReceived(this, buffer);
        _logInputDataRate(byteCount, QDateTime::currentMSecsSinceEpoch());
#ifdef TCPLINK_READWRITE_DEBUG
        writeDebugBytes(buffer.data(), buffer.size());
#endif
    }
     */
}


void BTSerialLink::readMAVDataBytes() {
    
}

void BTSerialLink::readBytes(QString characteristic) {
    
}

/**
 * @brief Disconnect the connection.
 *
 * @return True if connection has been disconnected, false if connection couldn't be disconnected.
 **/
bool BTSerialLink::_disconnect(void)
{
    //quit();
    //wait();
    /*
    if (_socket)
    {
        _socketIsConnected = false;
        _socket->deleteLater(); // Make sure delete happens on correct thread
        _socket = NULL;
        emit disconnected();
    }
     */
    return true;
}

/**
 * @brief Connect the connection.
 *
 * @return True if connection has been established, false if connection couldn't be established.
 **/
bool BTSerialLink::_connect(void)
{
    /*
    if (isRunning())
    {
        quit();
        wait();
    }
    start(HighPriority);
    return true;
     */
    
    
}

bool BTSerialLink::_hardwareConnect()
{
    /*
    Q_ASSERT(_socket == NULL);
    _socket = new QTcpSocket();
    QSignalSpy errorSpy(_socket, SIGNAL(error(QAbstractSocket::SocketError)));
    _socket->connectToHost(_config->address(), _config->port());
    QObject::connect(_socket, SIGNAL(readyRead()), this, SLOT(readBytes()));
    QObject::connect(_socket, SIGNAL(error(QAbstractSocket::SocketError)), this, SLOT(_socketError(QAbstractSocket::SocketError)));
    // Give the socket a second to connect to the other side otherwise error out
    if (!_socket->waitForConnected(1000))
    {
        // Whether a failed connection emits an error signal or not is platform specific.
        // So in cases where it is not emitted, we emit one ourselves.
        if (errorSpy.count() == 0) {
            emit communicationError(tr("Link Error"), QString("Error on link %1. Connection failed").arg(getName()));
        }
        delete _socket;
        _socket = NULL;
        return false;
    }
    _socketIsConnected = true;
    emit connected();
    return true;
     */
    
    return btlwrapper->_connect() ;
    
}

/*
bool BTSerialLink::scan ()
{
    [btlwrapper->btl_objc scan] ;
}
*/

bool BTSerialLink::_discover (void*)
{
    //btlwrapper->_discover(nil) ;
}



void BTSerialLink::_socketError(QAbstractSocket::SocketError socketError)
{
    Q_UNUSED(socketError);
    //emit communicationError(tr("Link Error"), QString("Error on link %1. Error on socket: %2.").arg(getName()).arg(_socket->errorString()));
}

/**
 * @brief Check if connection is active.
 *
 * @return True if link is connected, false otherwise.
 **/
bool BTSerialLink::isConnected() const
{
    return _socketIsConnected;
}

QString BTSerialLink::getName() const
{
    return _config->name();
}

qint64 BTSerialLink::getConnectionSpeed() const
{
    return 54000000; // 54 Mbit
}

qint64 BTSerialLink::getCurrentInDataRate() const
{
    return 0;
}

qint64 BTSerialLink::getCurrentOutDataRate() const
{
    return 0;
}


void BTSerialLink::waitForBytesWritten(int msecs)
{
    /*
    Q_ASSERT(_socket);
    _socket->waitForBytesWritten(msecs);
     */
}

void BTSerialLink::waitForReadyRead(int msecs)
{
    /*
    Q_ASSERT(_socket);
    _socket->waitForReadyRead(msecs);
     */
}

void BTSerialLink::_restartConnection()
{
    if(this->isConnected())
    {
        _disconnect();
        _connect();
    }
}

//--------------------------------------------------------------------------
//-- BTSerialConfiguration

BTSerialConfiguration::BTSerialConfiguration(const QString& name) : LinkConfiguration(name)
{
    //_port    = QGC_TCP_PORT;
    //_address = QHostAddress::Any;
}

BTSerialConfiguration::BTSerialConfiguration(BTSerialConfiguration* source) : LinkConfiguration(source)
{
    //_port    = source->port();
    //_address = source->address();
}

void BTSerialConfiguration::copyFrom(LinkConfiguration *source)
{
    LinkConfiguration::copyFrom(source);
    BTSerialConfiguration* usource = dynamic_cast<BTSerialConfiguration*>(source);
    Q_ASSERT(usource != NULL);
    //_port    = usource->port();
    //_address = usource->address();
}

/*
void BTSerialConfiguration::setPort(quint16 port)
{
    //_port = port;
}



void BTSerialConfiguration::setAddress(const QHostAddress& address)
{
    //_address = address;
}
*/

void BTSerialConfiguration::saveSettings(QSettings& settings, const QString& root)
{
    settings.beginGroup(root);
    //settings.setValue("port", (int)_port);
    //settings.setValue("host", address().toString());
    settings.endGroup();
}

void BTSerialConfiguration::loadSettings(QSettings& settings, const QString& root)
{
    settings.beginGroup(root);
    //_port = (quint16)settings.value("port", QGC_TCP_PORT).toUInt();
    //QString address = settings.value("host", _address.toString()).toString();
    //_address = address;
    settings.endGroup();
}

void BTSerialConfiguration::updateSettings()
{
    if(_link) {
        TCPLink* ulink = dynamic_cast<TCPLink*>(_link);
        if(ulink) {
            //ulink->_restartConnection();
        }
    }
}


@implementation BTSerialLink_objc

-(BTSerialLink_objc*)init {
    [super init];
    if (self)
    {
        self.centraldelegate = self;
        self.peripheraldelegate = self;
        
    }
    return self;
}

-(BOOL)connect {
    
}

-(BOOL)scan {
    //[self.centraldelegate centralManagerDidUpdateState:manager];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state)
    {
        case CBCentralManagerStatePoweredOn:
        {
            [self.manager scanForPeripheralsWithServices:@[ [CBUUID UUIDWithString:kServiceUUID]]
                                                 options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
        }
            break;
        default:
        {
            NSLog(@"Central Manager did change state");
        }
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    
    NSString *UUID = [peripheral.identifier UUIDString];
    NSString *UUID1 = CFBridgingRelease(CFUUIDCreateString(NULL, peripheral.UUID));
    NSLog(@"----发现外设----%@%@", UUID,UUID1);
    [self.manager stopScan];
    
    if (self.peripheral != peripheral)
    {
        self.peripheral = peripheral;
        NSLog(@"Connecting to peripheral %@", peripheral);
        [self.manager connectPeripheral:peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"----成功连接外设----");
    [self.peripheral setDelegate:self];
    [self.peripheral discoverServices:@[ [CBUUID UUIDWithString:kServiceUUID]]];
}



- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"----连接外设失败----Error:%@",error);
    [self cleanup];
}

- (void)peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"----didDiscoverServices----Error:%@",error);
    if (error)
    {
        NSLog(@"Error discovering service: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    for (CBService *service in aPeripheral.services)
    {
        NSLog(@"Service found with UUID: %@", service.UUID);
        if ([service.UUID isEqual:[CBUUID UUIDWithString:kServiceUUID]])
        {
            [self.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kCharacteristicUUID],[CBUUID UUIDWithString:kWrriteCharacteristicUUID]] forService:service];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"-----外设断开连接------%@",error);
    self.peripheral = nil;
    [self cleanup];
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error discovering characteristic: %@", [error localizedDescription]);
        return;
    }
    if ([service.UUID isEqual:[CBUUID UUIDWithString:kServiceUUID]])
    {
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            NSLog(@"----didDiscoverCharacteristicsForService---%@",characteristic);
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicUUID]])
            {
                [peripheral readValueForCharacteristic:characteristic];
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
            
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kWrriteCharacteristicUUID]])
            {
                writeCharacteristic = characteristic;
            }
            
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    
    // Exits if it's not the transfer characteristic
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicUUID]] )
    {
        // Notification has started
        if (characteristic.isNotifying)
        {
            NSLog(@"Notification began on %@", characteristic);
            [peripheral readValueForCharacteristic:characteristic];
        }
        else
        { // Notification has stopped
            // so disconnect from the peripheral
            NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
            [self.manager cancelPeripheralConnection:self.peripheral];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"----Value---%@",characteristic.value);
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicUUID]])
    {
        //        NSData *valueData = [characteristic value];
        //        Byte value[16] = {0};
        //        [valueData getBytes:&value length:sizeof(value)];
        //        for ( int istep1 = 0; istep1 < 16; istep1++ )
        //        {
        //            printf("%02x ",value[istep1]);
        //
        //        }
        //        printf("\n ");
        //        [peripheral setNotifyValue:NO forCharacteristic:characteristic];
        if (writeCharacteristic)
        {
            Byte ACkValue[3] = {0};
            ACkValue[0] = 0xe0; ACkValue[1] = 0x00; ACkValue[2] = ACkValue[0] + ACkValue[1];
            NSData *data = [NSData dataWithBytes:&ACkValue length:sizeof(ACkValue)];
            [self.peripheral writeValue:data
                      forCharacteristic:writeCharacteristic
                                   type:CBCharacteristicWriteWithoutResponse];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"---didWriteValueForCharacteristic-----");
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kWrriteCharacteristicUUID]])
    {
        NSLog(@"----value更新----");
        //         [peripheral readValueForCharacteristic:characteristic];
        
        //        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    }
}



@end


@implementation BTSerialConfiguration_objc



@end

