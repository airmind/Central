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
#include "qt2ioshelper.h"

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
    BLE_Discovered_Peripheral_List* connectedPeripheral;
    NSUInteger cr_polling_idx;
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
-(CBPeripheral*)getCBPeripheralFromIdentifier:(NSString*)identifier;

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

-(BLE_LowPassFilter_objc*)initWith:(int)rssi {
    [super init];
    
    for (int i=0; i<LP_RSSI_WINDOW_LENGTH; i++) {
        lp_win[i] = rssi;
    }
    rp = 0;
    return self;
   
}

-(int)filteredRssi {
    int x=0;
    for (int i=0; i<LP_RSSI_WINDOW_LENGTH; i++) {
        //NSLog(@"----->%d", lp_win[i]);
        x = x + lp_win[i];
    }
    
    //NSLog(@"++++++->%d", x/LP_RSSI_WINDOW_LENGTH);
    
    return x/LP_RSSI_WINDOW_LENGTH;
}

-(void)updateWindowWith:(int)rssi {
    if (rp<LP_RSSI_WINDOW_LENGTH-1) {
        lp_win[rp] = rssi;
        rp = rp + 1;
        
    }
    else {
        lp_win[rp] = rssi;
        rp = 0;

    }

}


@end

@implementation BLE_Discovered_Peripheral
@synthesize inrange, connected, peripheral;

-(BLE_Discovered_Peripheral*)init {
    [super init];
    
    lp_filter = [[BLE_LowPassFilter_objc alloc] init];
    inrange = NO;
    connected = NO;
    
    return self;
}

-(BLE_Discovered_Peripheral*)initWithCurrentRSSI:(int)rssi{
    [super init];
    
    lp_filter = [[BLE_LowPassFilter_objc alloc] initWith:rssi];
    inrange = NO;
    connected = NO;
    
    return self;
    
}

/*
-(BLE_Discovered_Peripheral*)BLEPeripheralFromCBPeripheral:(CBPeripheral*)p {

    BLE_Discovered_Peripheral* bp = [[BLE_Discovered_Peripheral alloc] initWithCurrentRSSI:p.RSSI.integerValue];
    bp.peripheral = p;
    
    
    return bp;
}
*/

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

-(void)dealloc {
    
    [lp_filter release];
    [super dealloc];
}

@end


@implementation BLE_Discovered_Peripheral_List

-(BLE_Discovered_Peripheral_List*)init {
    [super init];
    p_list = [[NSMutableArray alloc] initWithCapacity:0];
    
    return self;
}

-(void)emptyList {
    for (BLE_Discovered_Peripheral* p in p_list) {
        [p release];
    }
    [p_list removeAllObjects];

}

-(BLE_Discovered_Peripheral*)containsPeripheral:(CBPeripheral*)p {
    //BOOL found = NO;
    for (BLE_Discovered_Peripheral* btp in p_list) {
        if (p.identifier == btp.peripheral.identifier) {
            return btp;
            
        }
    }
    return nil;
}

-(NSUInteger)indexOfPeripheral:(CBPeripheral*)p {
    //BOOL found = NO;
    int idx = 0;
    for (BLE_Discovered_Peripheral* btp in p_list) {
        if (p.identifier == btp.peripheral.identifier) {
            return idx;
            
        }
        idx ++;
    }
    return NSNotFound;
}

-(BOOL)addPeripheral:(BLE_Discovered_Peripheral*)p {
    [p_list addObject:p];
    
    return YES;
}

-(BOOL)removePeripheral:(BLE_Discovered_Peripheral*)p {
    NSUInteger idx = [self indexOfPeripheral:p.peripheral];
    if (idx != NSNotFound) {
        [p_list removeObjectAtIndex:idx];
        return YES;
    }
    return NO;
    
}

-(NSArray*)getInRangePeripheralList {
    NSMutableArray* in_array = [[NSMutableArray alloc] initWithCapacity:0];
    for (BLE_Discovered_Peripheral* blep in p_list) {
        if (blep.inrange == YES) {
            [in_array addObject:blep.peripheral];
        }
    }
    return in_array;
}

-(NSArray*)getOutOfRangePeripheralList {
    NSMutableArray* out_array = [[NSMutableArray alloc] initWithCapacity:0];
    for (BLE_Discovered_Peripheral* blep in p_list) {
        if (blep.inrange == NO) {
            [out_array addObject:blep.peripheral];
        }
    }
    return out_array;

}

-(void)dealloc {
    
    
    for (BLE_Discovered_Peripheral* p in p_list) {
        [p release];
    }
    [p_list removeAllObjects];
    
    [super dealloc];
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
    discoveredPeripherals = [[BLE_Discovered_Peripheral_List alloc] init];
    connectedPeripheral = [[BLE_Discovered_Peripheral_List alloc] init];
    
    
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
    //for not connected devices;
    sync = YES;
    
    //for connected devices;
    //call readrssi one by one;
    
}

-(BOOL) setCallbackDelegate:(NSObject*)delegate{
    delegatecontroller = delegate;
    
}


-(BOOL) discover:(NSObject*)delegate{
    [self centralManagerDidUpdateState:centralmanager];
    
}

-(void) stopScanning {
    [centralmanager stopScan];
    [t1 invalidate];
    
    //empty discovered list - but not connected list;
    [discoveredPeripherals emptyList];
    
}

-(BOOL) connect : (NSString*) identifier {
    CBPeripheral* p = [self getCBPeripheralFromIdentifier:identifier];
    if (p != nil) {
        [centralmanager connectPeripheral:p options:nil];
        return YES;
    }
    else {
        return NO;
    }
    
    
    
}

-(CBPeripheral*)getCBPeripheralFromIdentifier:(NSString*)identifier {
    for (BLE_Discovered_Peripheral* bp in discoveredPeripherals) {
        if ([[bp.peripheral.identifier UUIDString] isEqual:identifier]) {
            return bp.peripheral;
        }
    }
    return nil;

}

-(void)dealloc{
    NSLog(@"ble helper dealloced...");
    if (discoveredPeripherals!=nil) {
    
        [discoveredPeripherals release];
        discoveredPeripherals = nil;
    }
    [super dealloc];
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
        NSLog(@"newly discovered *********%@", peripheral.identifier);
        p = [[BLE_Discovered_Peripheral alloc] init];
        p.peripheral = [peripheral copy];
        p.inrange=NO;
        //connected only by this app;
        p.connected=NO;
        [discoveredPeripherals addPeripheral:p];
    }

    int averagedRSSI = [p getFilteredRssi:RSSI.integerValue];

    //NSLog(@"Discovered %@ at %d", peripheral.name, averagedRSSI);
    
    // Reject any where the value is above reasonable range, or if the signal strength is too low to be close enough (Close is around -22dB)
    /*
    
    int averagedRSSI = [self lowpass_rssi:lp_win];
    */
    //if (check==YES) {
        
    
    if (averagedRSSI < -50/*-35*/)
    {
        //remove from in range list;
        NSLog(@"not in range, return ...");

        [p outOfRange];
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
        [p isInRange];
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
    
    
        if (sync == YES) {
            NSArray* p_in = [discoveredPeripherals getInRangePeripheralList];
            NSArray* p_out = [discoveredPeripherals getOutOfRangePeripheralList];

            NSLog(@"in range, call display...");
            dispatch_async(dispatch_get_main_queue(), ^{
                
                
                [(ConnectPopoverViewController*)delegatecontroller didDiscoverBTLinksInRange:p_in outOfRange:p_out];
                
                
            });
            
        }
        sync = NO;
    
}

/** If the connection fails for whatever reason, we need to deal with it.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [(ConnectPopoverViewController*)delegatecontroller didFailToConnectBTLink];
        
        
    });
}


/** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral Connected");
    
    // Stop scanning - ??
    [centralmanager stopScan];
    NSLog(@"Scanning stopped");
    
    // Make sure we get the discovery callbacks
    peripheral.delegate = self;
    
    NSLog(@"connected device RSSI: %d", peripheral.RSSI.integerValue);
    //start update rssi of connected devices;
    if ([connectedPeripheral counts]==0) {
        //first connected to this app;
        //init timer;
        t_connected = [NSTimer scheduledTimerWithTimeInterval:0.1f
                                              target:self
                                            selector:@selector(udpaterssi:)
                                            userInfo:nil
                                             repeats:YES];
        //add into list;
        BLE_Discovered_Peripheral* bp = [[BLE_Discovered_Peripheral alloc] initWithCurrentRSSI:peripheral.RSSI.integerValue];
        bp.peripheral = peripheral;
        [connectedPeripheral addPeripheral:bp];
    }
    else {
        if ([connectedPeripheral containsPeripheral:peripheral]==nil) {
            BLE_Discovered_Peripheral* bp = [[BLE_Discovered_Peripheral alloc] initWithCurrentRSSI:peripheral.RSSI.integerValue];
            bp.peripheral = peripheral;

            [connectedPeripheral addPeripheral:bp];
        }
        //already connnectd;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        
        [(ConnectPopoverViewController*)delegatecontroller didConnectedBTLink];
        
        
    });

    
    // Search only for services that match our UUID
    [peripheral discoverServices:@[[CBUUID UUIDWithString:MAV_TRANSFER_SERVICE_UUID]]];
}


/**
 start update rssi;
 
 **/

-(void)updaterssi : (id)sender {
    //check all connected devices;
    cr_polling_idx = 0;
    CBPeripheral* p = [connectedPeripheral peripheralAtIndex:0];
    [p readRSSI];
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error {
    int filteredvalue;
    
    BLE_Discovered_Peripheral* p = [connectedPeripheral containsPeripheral:peripheral];
    if (error == nil) {
        filteredvalue = [p getFilteredRssi:peripheral.RSSI.intValue];
        if (filteredvalue < -50 ) {
            //out of range;
            p.inrange = NO;
        }
        else {
            p.inrange = YES;
        }
    }

    //check next;
    if (cr_polling_idx < [connectedPeripheral count]-1) {
        CBPeripheral* p = [connectedPeripheral peripheralAtIndex:cr_polling_idx+1];
        [p readRSSI];
    }
    else {
        //reached end; notify UI;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            
            [(ConnectPopoverViewController*)delegatecontroller didReadConnectedBTLinkRSSI:p.inrange];
            
            
        });
    }
}


/** The Transfer Service was discovered
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    // Discover the characteristic we want...
    
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    for (CBService *service in peripheral.services)
    {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:MAV_TRANSFER_CHARACTERISTIC_UUID]] forService:service];
    }
}


/** The Transfer characteristic was discovered.
 *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // Deal with errors (if any)
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    // Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        
        // And check if it's the right one
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:MAV_TRANSFER_CHARACTERISTIC_UUID]]) {
            
            // If it is, subscribe to it
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
    
    // Once this is complete, we just need to wait for the data to come in.
}


/** This callback lets us know more data has arrived via notification on the characteristic
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    // Have we got everything we need?
    if ([stringFromData isEqualToString:@"EOM"])
    {
        
        // We have, so show the data,
        //[self.textview setText:[[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding]];
        
        // Cancel our subscription to the characteristic
        //[peripheral setNotifyValue:NO forCharacteristic:characteristic];
        
        // and disconnect from the peripehral
        //[self.centralManager cancelPeripheralConnection:peripheral];
    }
    
    // Otherwise, just add the data on to what we already have
    //[self.data appendData:characteristic.value];
    
    // Log it
    NSLog(@"Received: %@", stringFromData);
}


/** The peripheral letting us know whether our subscribe/unsubscribe happened or not
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    
    // Exit if it's not the transfer characteristic
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:MAV_TRANSFER_CHARACTERISTIC_UUID]]) {
        return;
    }
    
    // Notification has started
    if (characteristic.isNotifying)
    {
        NSLog(@"Notification began on %@", characteristic);
    }
    
    // Notification has stopped
    else {
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        [centralmanager cancelPeripheralConnection:peripheral];
    }
}


/** Once the disconnection happens, we need to clean up our local copy of the peripheral
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Peripheral Disconnected");
    //self.discoveredPeripheral = nil;
    
    // We're disconnected, so start scanning again
    [self scan];
}



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


/****************************
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


/**
 BTSerialConfigurationWrapper
 
 **/

class BTSerialConfigurationWrapper {
    BTSerialConfiguration_objc* btc_objc;
public:
    BTSerialConfigurationWrapper();
    ~BTSerialConfigurationWrapper();
    void configBLESerialLink(QString& linkid, QString& linkname, QString& sid, QString& cid);
    
};

BTSerialConfigurationWrapper::BTSerialConfigurationWrapper() {
    btc_objc = [[BTSerialConfiguration_objc alloc] init];
}

BTSerialConfigurationWrapper::~BTSerialConfigurationWrapper() {
    if (btc_objc!=nil) {
        
    
        [btc_objc release];
    }
}

void BTSerialConfigurationWrapper::configBLESerialLink(QString& linkid, QString& linkname, QString& sid, QString& cid) {
    NSString* identifier = qt2ioshelper::QString2NSString(&linkid);
    NSString* name = qt2ioshelper::QString2NSString(&linkname);
    NSString* serviceid = qt2ioshelper::QString2NSString(&sid);
    NSString* characteristicid = qt2ioshelper::QString2NSString(&cid);
    
    [btc_objc configLinkId:identifier linkname:name serviceid:serviceid characteristicid:characteristicid];
}

/**
 BTSerialLinkWrapper
 **/

class BTSerialLinkWrapper {
    BTSerialLink_objc* btl_objc;
public:
    BTSerialLinkWrapper(BTSerialConfiguration* config);
    ~BTSerialLinkWrapper();
    
    BTSerialConfiguration_objc* createObjCConfigObjectFromQObject(BTSerialConfiguration*);
    //bool _discover(void*);
    bool _connect();
    bool _hardwareConnect();
    bool _disconnect();
    void setCallbackDelegate (void*);
    
    //read/write;
    void writeBytes(QString characteristic, const char* data, qint64 size);
    void writeBytesNeedsAck(QString characteristic, const char* data, qint64 size);
    
    void writeBytes(const char* data, qint64 size);
    void writeBytesNeedsAck(const char* data, qint64 size);

    
    //void configBLESerialLink(QString& linkid, QString& linkname, QString& sid, QString& cid) ;
};



BTSerialLinkWrapper::BTSerialLinkWrapper(BTSerialConfiguration* config) {
    BTSerialConfiguration_objc* _config = createObjCConfigObjectFromQObject(config);
    btl_objc = [[BTSerialLink_objc alloc] initWith:_config];

}

BTSerialLinkWrapper::~BTSerialLinkWrapper() {
    if (btl_objc!=nil) {
        [btl_objc release];
    }
}

void BTSerialLinkWrapper::writeBytes(QString characteristic, const char* data, qint64 size) {
    NSString* cid = qt2ioshelper::QString2NSString(&characteristic);
    //[btl_objc writeBytes:data characteristic:cid size:(long long)size];
    
}

void BTSerialLinkWrapper::writeBytesNeedsAck(QString characteristic, const char* data, qint64 size) {
    NSString* cid = qt2ioshelper::QString2NSString(&characteristic);

    //[btl_objc writeBytesNeedsAck:data characteristic:cid size:(long long)size];
}

void BTSerialLinkWrapper::writeBytes(const char* data, qint64 size) {
    [btl_objc writeBytes:data size:(long long)size];
}

void BTSerialLinkWrapper::writeBytesNeedsAck(const char* data, qint64 size) {
    [btl_objc writeBytesNeedsAck:data size:(long long)size];
}



BTSerialConfiguration_objc* BTSerialLinkWrapper::createObjCConfigObjectFromQObject(BTSerialConfiguration* config) {
    QString qidentifier = config->getBLEPeripheralIdentifier();
    QString qname = config->getBLEPeripheralName();
    QString qserviceid = config->getBLEPeripheralServiceID();
    QString qcharacteristicid = config->getBLEPeripheralCharacteristicID();

    NSString* identifier = qt2ioshelper::QString2NSString(&qidentifier);
    NSString* name = qt2ioshelper::QString2NSString(&qname);
    NSString* serviceid = qt2ioshelper::QString2NSString(&qserviceid);
    NSString* characteristicid = qt2ioshelper::QString2NSString(&qcharacteristicid);

    BTSerialConfiguration_objc* config_obj = [[BTSerialConfiguration_objc alloc] init];

    [config_obj configLinkId:identifier linkname:name serviceid:serviceid characteristicid:characteristicid];

    //configBLESerialLink(identifier, name, serviceid, characteristicid);
    return config_obj;
}


bool BTSerialLinkWrapper::_connect() {
    //btl_objc = [[BTSerialLink_objc alloc] init];
    //NSString* nsidentifier = qt2ioshelper::QString2NSString(identifier);
    [btl_objc connect];
    return true;
}


void BTSerialLinkWrapper::setCallbackDelegate (void* delegate) {
    [btl_objc setCallbackDelegate:(__bridge id)delegate];
}


/******************************************
 BTSerialLink class;
 
 */

BTSerialLink::BTSerialLink(BTSerialConfiguration *config)
//, _socket(NULL)
//, _socketIsConnected(false)
{
    _config = config;
    Q_ASSERT(_config != NULL);

    btlwrapper = new BTSerialLinkWrapper(config);
    
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
    btlwrapper->writeBytes(data, size);
    
}


void BTSerialLink::writeMAVDataBytes(const char* data, qint64 size) {
    
}


void BTSerialLink::writeBytes(QString characteristic, const char* data, qint64 size) {
    
}


void writeBytes(QString characteristic, const char* data, qint64 size);
void writeBytesNeedsAck(QString characteristic, const char* data, qint64 size);

void writeBytes(const char* data, qint64 size);
void writeBytesNeedsAck(const char* data, qint64 size);


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
bool BTSerialLink::_connect()
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
    
    
    //connect to peripheral only?
    //QString identifier = _config->getBLEPeripheralIdentifier();
    //QString serviceid = _config->getBLEPeripheralServiceID();
    //QString cid = _config->getBLEPeripheralCharacteristicID();

    btlwrapper->_connect();
    
}

bool BTSerialLink::_hardwareConnect()
{
    //QString* identifier = _config->getBLEPeripheralIdentifier();
    
    return btlwrapper->_hardwareConnect();
    
}

void BTSerialLink::setCallbackDelegate(void* delegate) {
    btlwrapper->setCallbackDelegate(delegate);
}


/*
bool BTSerialLink::scan ()
{
    [btlwrapper->btl_objc scan] ;
}
*/




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
    if (_linkstatus == BLE_LINK_NOT_CONNECTED) {
        return false;
    }
    return true;
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
    btcwrapper =  new BTSerialConfigurationWrapper();
}

BTSerialConfiguration::BTSerialConfiguration(BTSerialConfiguration* source) : LinkConfiguration(source)
{
    //_port    = source->port();
    //_address = source->address();
    if (btcwrapper!=NULL) {
        delete btcwrapper;
    }
}

void BTSerialConfiguration::configBLESerialLink(QString& linkid, QString& linkname, QString& sid, QString& cid) {

    identifier = linkid;
    pname = linkname;
    serviceID = sid;
    characteristicID = cid;
    
    btcwrapper -> configBLESerialLink (identifier, pname, serviceID, characteristicID);
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

/***************************
 Objective C implementation
 
 ***************/

@interface BTSerialLink_objc ()<CBCentralManagerDelegate,CBPeripheralDelegate>
{
    CBCharacteristic *writeCharacteristic;
    
}
@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSObject* centraldelegate;
@property (nonatomic, strong) NSObject* peripheraldelegate;


@end


@implementation BTSerialLink_objc

-(BTSerialLink_objc*)init {
    [super init];
    if (self)
    {
        self.centraldelegate = self;
        self.peripheraldelegate = self;
        
    }
    cbmgr = [[BLEHelper_objc sharedInstance] getBLECentralManager];
    return self;
}


-(BTSerialLink_objc*)initWith:(BTSerialConfiguration_objc*)config {
    [super init];
    if (self)
    {
        self.centraldelegate = self;
        self.peripheraldelegate = self;
        
    }
    config_objc = config;
    cbmgr = [[BLEHelper_objc sharedInstance] getBLECentralManager];
    return self;
}

-(void)readBytes {
    [cbp readValueForCharacteristic:targetCharacteristic];
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        //[self cleanup];
        return;
    }
    
    //did write and call back;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        
        [(ConnectPopoverViewController*)delegatecontroller didReadBytes:characteristic.value];
        
        
    });
    

}

-(void)writeBytes:(const char*)data size:(int)size {
    
    //NSString* cid = [config_objc getCharacteristicId];
    NSData *ndata = [NSData dataWithBytes: data  length:size];
    [cbp writeValue:ndata forCharacteristic:targetCharacteristic type:CBCharacteristicWriteWithoutResponse];
}


-(void)writeBytesNeedsAck:(const char*)data size:(int)size {
    //NSString* cid = [config_objc getCharacteristicId];
    NSData *ndata = [NSData dataWithBytes: data  length:size];

    [cbp writeValue:ndata forCharacteristic:targetCharacteristic type:CBCharacteristicWriteWithResponse];
    
}


- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }

    //did write and call back;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        
        [(ConnectPopoverViewController*)delegatecontroller didConnectedBTLink];
        
        
    });
    

    
}

-(void)writeBytes:(const char*)data characteristic:(CBCharacteristic*)cid size:(int)size {
    
}

-(void)writeBytesNeedsAck:(const char *)data characteristic:(CBCharacteristic*)cid size:(int)size {
}


-(void)setCallbackDelegate:(NSObject*)delegate {
    delegatecontroller = delegate;
}


-(BOOL)connect {
    
    NSString* identifier = [config_objc getLinkId];
    connectstage = BLE_LINK_CONNECTED_CHARACTERISTIC;
    
    CBPeripheral* p =  [[BLEHelper_objc sharedInstance] getCBPeripheralFromIdentifier:(NSString*)identifier];
    
    [cbmgr connectPeripheral:p options:nil];
}

-(BOOL)hardwareConnect {
    NSString* identifier = [config_objc getLinkId];
    connectstage = BLE_LINK_CONNECTED_PERIPHERAL;
    
    CBPeripheral* p =  [[BLEHelper_objc sharedInstance] getCBPeripheralFromIdentifier:(NSString*)identifier];
    
    [cbmgr connectPeripheral:p options:nil];

}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    if (connectstage == BLE_LINK_CONNECTED_PERIPHERAL) {
        
        cbp = peripheral;
        //connected and call back;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [(ConnectPopoverViewController*)delegatecontroller didConnectedBTLink];
            
        });
        

    }
    else{
        
        //continue connect to services/characteristics;
        
        // Search only for services that match our UUID
        NSString* sid = [config_objc getServiceId];
        [peripheral discoverServices:@[[CBUUID UUIDWithString:sid]]];

        
    }

}

/** The Transfer Service was discovered
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    targetService = [peripheral.services objectAtIndex:0];
    
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    
    NSString* cid = [config_objc getCharacteristicId];
    for (CBService *service in peripheral.services)
    {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:cid]] forService:service];
    }
    

}


/** The Transfer characteristic was discovered.
 *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // Deal with errors (if any)
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    targetCharacteristic = [service.characteristics objectAtIndex:0];
    
    NSString* cid = [config_objc getCharacteristicId];

    // Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        
        // And check if it's the right one
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:cid]]) {
            
            // If it is, subscribe to it
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
    
    //reached the end of connection, call back;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        
        [(ConnectPopoverViewController*)delegatecontroller didConnectedBTLink];
        
        
    });

}




/** The peripheral letting us know whether our subscribe/unsubscribe happened or not
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    
    // Exit if it's not the transfer characteristic
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:MAV_TRANSFER_CHARACTERISTIC_UUID]]) {
        return;
    }
    
    // Notification has started
    if (characteristic.isNotifying)
    {
        NSLog(@"Notification began on %@", characteristic);
    }
    
    // Notification has stopped
    else {
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        [_manager cancelPeripheralConnection:peripheral];
    }
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


@end


@implementation BTSerialConfiguration_objc

-(void)configLinkId:(NSString*)linkid linkname:(NSString*)name serviceid:(NSString*)sid characteristicid:(NSString*)cid{
    link_identifier=linkid;
    link_name=name;
    link_service_id=sid;
    link_characteristic_id=cid;

}

-(NSString*)getLinkId {
    return link_identifier;
}

-(NSString*)getLinkName {
    return link_name;
}

-(NSString*)getServiceId {
    return link_service_id;
}

-(NSString*)getCharacteristicId {
    return link_characteristic_id;
}


@end

