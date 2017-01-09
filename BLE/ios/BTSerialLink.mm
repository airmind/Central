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

//#import "ConnectPopoverViewController.h"
#include "QGCApplication.h"


static NSString * const kServiceUUID = @"FC00"; //mindstick
static NSString * const kCharacteristicUUID = @"FC20";
static NSString * const kCharacteristicInputstickUUID = @"FC21";  //inputstick
static NSString * const kCharacteristicCaliberationUUID = @"FC22";  //caliberation
static NSString * const kCharacteristicAltitudeUUID = @"FC24";  //parameter - altitude
static NSString * const kWrriteCharacteristicUUID = @"FC21";  //selectedobject
static NSString * const kWrriteCharacteristicConfigureUUID = @"FC26";  //selectedobject
static NSString * const kWrriteCharacteristicMAVDataUUID = @"FC28";  //selectedobject


/****
 
 BLE routing table;
 
 each BLE_Discovered_peripheral has a routing table maps service/characteristic pair to a link;
 
 *****/

@implementation BLE_LinkRouting_Hashtable

-(instancetype)initWithCapacity:(NSUInteger)numItems {
    hashtable = [[NSMutableDictionary alloc] initWithCapacity:numItems];
    
    return self;
}


-(void)addMetaCharacteristic:(CBCharacteristic*)character forService:(CBService*)service {
    NSMutableDictionary* cid_links = [hashtable objectForKey:service.UUID];
    if (cid_links!=nil) {
        [cid_links setObject:nil forKey:character.UUID];
    }
    
    else { //no entry for service key yet, create one;
        NSMutableDictionary* p_cid_links = [[NSMutableDictionary alloc] initWithCapacity:0];
        [hashtable setObject:p_cid_links forKey:service.UUID];
        
        //[p_cid_links setObject:nil forKey:character.UUID];
        
    }
    
}


-(void)routingCharacteristic:(CBCharacteristic*)chara inService: (CBService*)service toLink:(BTSerialLink_objc*)link {
    NSMutableDictionary* p_cid_links = [hashtable objectForKey:service.UUID];
    
    //assert(p_cid_links != nil && [[p_cid_links allKeys] containsObject:chara.UUID]);
    
    [p_cid_links setObject:link forKey:chara.UUID];

}

-(void)removeRoutingEntryofLink:(BTSerialLink_objc*)link {
    NSEnumerator *enumerator = [hashtable keyEnumerator];
    id key;
    BOOL done = NO;
    
    while ((key = [enumerator nextObject])) {
        
        NSMutableDictionary* cid_links = [hashtable objectForKey:key];
        if (cid_links !=nil) {
            
            NSEnumerator *cenumerator = [cid_links keyEnumerator];
            id ckey;
            
            while (ckey = [cenumerator nextObject]) {
                if (link == [cid_links objectForKey:ckey]) {
                    [cid_links removeObjectForKey:ckey];
                }
                done = YES;
                break;
            }
            
        }
        if (done) {
            if ([cid_links count]<=0) {
                
                [hashtable removeObjectForKey:key];
                break;
            }
        }


    }
    
}

-(BTSerialLink_objc*)linkForCharacteristic:(CBCharacteristic*)character inService:(CBService*)service {
    if (hashtable == nil) {
        return nil;
    }
    NSDictionary* characteristics = [hashtable objectForKey:service.UUID];
    
    if (characteristics == nil) {
        return nil;
    }
    
    return [characteristics objectForKey:character.UUID];

}


-(void)dealloc {
    
    [hashtable removeAllObjects];
    [hashtable release];
    hashtable = nil;
    [super dealloc];
}

@end




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
    //id delegatecontroller;
    
    BLE_Peripheral_Links* peripherallinks;
    
    LinkManager* refQGCLinkManager;

}

+(BLEHelper_objc*)sharedInstance;
-(CBCentralManager*)getBLECentralManager;
-(CBPeripheralManager*)getBLEPeripheralManager;

-(BOOL) setCallbackDelegate:(NSObject*)delegate;
-(id) getUICallbackDelegate;
-(BOOL) discover:(NSObject*)delegate;
-(BOOL) discoverServices:(NSObject*)delegate;
-(BOOL) discoverCharacteristics:(NSObject*)delegate;
-(void) stopScanning;
-(CBPeripheral*)getDiscoveredCBPeripheralFromIdentifier:(NSString*)identifier;
-(CBPeripheral*)getConnectedCBPeripheralFromIdentifier:(NSString*)identifier;
-(BLE_Discovered_Peripheral*)getDiscoveredBLEPeripheralFromIdentifier:(NSString*)identifier;
-(BLE_Discovered_Peripheral*)getConnectedBLEPeripheralFromIdentifier:(NSString*)identifier;

-(BOOL) createBTSerialLinkFromConfig:(BTSerialConfiguration_objc*)btcfg;
//Obj-C does not support method overloading, so use different name;
-(BOOL) createBTSerialLinkFromPeripheral:(BLE_Discovered_Peripheral*)blep;

-(void)addLink:(BTSerialLink_objc*)link;
-(void)deleteLink:(BTSerialLink_objc*)link;
-(NSArray*)allLinks;
-(NSArray*)connectedLinks;

//multiple links?
-(BTSerialLink_objc*)linkForPeripheral:(CBPeripheral*)p ;
-(BLE_Discovered_Peripheral*)connectedPeripheralFromUUIDString : (NSString*)uuidstr;

-(void)disconnectLink:(BTSerialLink_objc*)link;
-(void)disconnectPeripheral:(CBPeripheral*)p ;
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
@synthesize inrange, connected, cbperipheral, advertisementdata;

-(BLE_Discovered_Peripheral*)init {
    [super init];
    
    lp_filter = [[BLE_LowPassFilter_objc alloc] init];
    inrange = NO;
    connected = NO;
    advertisementdata= nil;
    return self;
}

-(BLE_Discovered_Peripheral*)initWithCurrentRSSI:(int)rssi{
    [super init];
    
    lp_filter = [[BLE_LowPassFilter_objc alloc] initWith:rssi];
    inrange = NO;
    connected = NO;
    advertisementdata = nil;
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

-(BOOL)isConnected {
    //return connected;

    //TODO: check if multiple links exist for one peripheral;
    if ([[BLEHelper_objc sharedInstance] linkForPeripheral:cbperipheral]) {
        return YES;
    }
    
    return NO;
    
}

-(void)isDisconnected {
    connected=NO;
}

-(BLE_Peripheral_HARDWARECONNECT_STATUS)hardwareConnectStatus {
    return connectStatus;
}

-(void)setHardwareConnectStatus:(BLE_Peripheral_HARDWARECONNECT_STATUS)status{
    connectStatus = status;
}


/** AS CBPeripheral delegate; The Transfer Service was discovered
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        //clean up all entries under this service
        return;
    }
    
    NSArray* sarray = peripheral.services;
    assert([sarray count]<=1);
    CBService* service = [sarray objectAtIndex:0];

    //iterate throught the try list;
    for(BTSerialLink_objc* blink in servicetryconnectionlist) {
        NSString* sid = [[blink configuration] getServiceId];
        if ([sid compare:[service.UUID UUIDString]] == NSOrderedSame) {
            //[blink didFoundServices:sarray];
            NSString* cid = [[blink configuration] getCharacteristicId];
            
            //add to characteristic trylist;
            if (characteristictryconnectionlist==nil) {
                characteristictryconnectionlist = [[NSMutableArray alloc] initWithCapacity:0];
            }
            [characteristictryconnectionlist addObject:blink];

            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:cid]] forService:service];
            [servicetryconnectionlist removeObject:blink];
        }
    }
/*
    //TODO: what if multiple links?
    BTSerialLink_objc* link = [self linkForPeripheral:peripheral];
    
    // Discover the characteristic we want...
    
    NSArray* sarray = peripheral.services;
    
    link.targetService = [peripheral.services objectAtIndex:0];
    
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    
    NSString* cid = [[link configuration] getCharacteristicId];
    NSLog(@"Characteristic ID: %@", cid);
    
    for (CBService *service in peripheral.services)
    {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:cid]] forService:service];
    }
 */
}


/** The Transfer characteristic was discovered.
 *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // Deal with errors (if any)
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);

        // just wait for time out for the moment.
        [self cleanup];
        return;
    }
    
    NSArray* carray = service.characteristics;
    NSLog(@"service contains %d characteristics.", [carray count]);
    assert([carray count]<=1);
    
    CBCharacteristic* characteristic = [carray objectAtIndex:0];
    
    if (rtable==nil) {
        rtable = [[BLE_LinkRouting_Hashtable alloc] initWithCapacity:0];
    }
    
    for(BTSerialLink_objc* blink in characteristictryconnectionlist) {
        
        NSString* cid = [[blink configuration] getCharacteristicId];
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:cid]]) {
            // found, subscribe to it
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            // build routing table for it
            
            [rtable addMetaCharacteristic:characteristic forService:service];
            [rtable routingCharacteristic:characteristic inService:service toLink:blink];

            //remove entry in try list;
            [characteristictryconnectionlist removeObject:blink];
            
            blink.targetService = service;
            blink.targetCharacteristic = characteristic;
            
            //did connect call back;
            [blink didConnect];

            
        }
    }
    
    NSLog(@"connected device RSSI: %d", peripheral.RSSI.integerValue);
    //start update rssi of connected devices;
    if (rtable == nil) {
    //if ([[peripherallinks allLinks] count]==1) {
        //first connected to this app;
        //init timer;
        //start
        
    }
    
    
    
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
    
    //routing data to the correct link;
    CBService* service = characteristic.service;
    BTSerialLink_objc* link = [self linkForCharacteristic:characteristic inService: service];
    
    
    //[(ConnectPopoverViewController*)delegatecontroller didReadBytes:characteristic.value];
    NSData* data = characteristic.value;
    ((__bridge BTSerialLink*)([link getCallerLinkPointer]))->didReadBytes((const char*)[data bytes], [data length]);
    //});
    
    NSString* aStr= [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSLog(@"%@, %d", aStr, [characteristic.value length]);
    /*
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
     */
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
        //[centralmanager cancelPeripheralConnection:peripheral];
    }
    
}


/**
 start update rssi;
 
 **/

-(void)updaterssi : (id)sender {
    assert(cbperipheral!=nil);
    [cbperipheral readRSSI];
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error {
    int filteredvalue;
    if (error == nil) {
        filteredvalue = [self getFilteredRssi:peripheral.RSSI.intValue];
        //make a UUID Qlist of connected peripherals that has link quality status flipped;
        
    }
    
    
}


-(BLE_LINK_QUALITY)linkQuality {
    return linkquality;
}

-(void)setLinkQuality : (BLE_LINK_QUALITY) quality {
    linkquality = quality;
}

-(int)getFilteredRssi:(int)rssi {
    [lp_filter updateWindowWith:rssi];
    return [lp_filter filteredRssi];
}

-(int)currentFilteredRssi {
    return [lp_filter filteredRssi];
}


-(BOOL)buildMetaRoutingTable {
    
    //build routing table of the peripheral;
    if (rtable != nil) {
        //not empty table, abort;
        return NO;
    }
    
    NSArray* sarray = cbperipheral.services;
    if (sarray != nil) {
        rtable = [[BLE_LinkRouting_Hashtable alloc] initWithCapacity:0];
        for (CBService *service in cbperipheral.services)
        {
            NSArray* carray = service.characteristics;
            
            for (CBCharacteristic *character in carray)
            {
                [rtable addMetaCharacteristic:character forService: service];
                
            }

        }
        return YES;
    }
    
    return NO;
    
    
}

-(BTSerialLink_objc*)linkForCharacteristic:(CBCharacteristic*)characteristic inService: (CBService*)service {
    
    return [rtable linkForCharacteristic:characteristic inService:service];
}

-(BOOL)buildConnectionForLink:(BTSerialLink_objc*)link {
    //[rtable updateLinkWith:link forService: service characteristic:chara];
    //add to try list;
    if (servicetryconnectionlist==nil) {
        servicetryconnectionlist = [[NSMutableArray alloc] initWithCapacity:0];
    }
    
    //call discover;
    NSString* sid = [[link configuration] getServiceId];
    //NSString* cid = [[link configuration] getCharacteristicId];
    
    [servicetryconnectionlist addObject:link];

    NSLog(@"Discovering service: %@ for device %@", sid, self);
    //NSArray* cid_array = [NSArray arrayWithObject:@[[CBUUID UUIDWithString:cid]]];
    [cbperipheral discoverServices:@[[CBUUID UUIDWithString:sid]]];

    //add to connecting peripheral list;
    //[[BLEHelper_objc sharedInstance] addLink:self];

}

-(void)failedBuildLinkConnection:(BTSerialLink_objc*)link {
    assert(servicetryconnectionlist!=nil);
    
    if ([servicetryconnectionlist indexOfObject:link]) {
        [servicetryconnectionlist removeObject:link];
    }
    
    if (characteristictryconnectionlist==nil) {
        return;
    }
    
    if ([characteristictryconnectionlist indexOfObject:link]) {
        [characteristictryconnectionlist removeObject:link];
    }
    
}


-(void)removeLink:(BTSerialLink_objc*)link {
    // remove link entry in rtable;
    //[rtable updateLinkWith:link forService: service characteristic:chara];
    [rtable removeRoutingEntryofLink:link];

}


-(BOOL)insertLinkRouting:(BTSerialLink_objc*)link forService:(CBService*)service characteristic:(CBCharacteristic*)chara {
    //[rtable updateLinkWith:link forService: service characteristic:chara];
    [rtable routingCharacteristic:chara inService:service toLink:link];

}


-(void)dealloc {
    if (advertisementdata!=nil) {
        [advertisementdata release];
    }
    
    [lp_filter release];
    
    if (servicetryconnectionlist!=nil) {
        [servicetryconnectionlist removeAllObjects];
        [servicetryconnectionlist release];
    }
    if (characteristictryconnectionlist!=nil) {
        [characteristictryconnectionlist removeAllObjects];
        [characteristictryconnectionlist release];

    }
    if (rtable!=nil) {
        [rtable removeAllObjects];
        [rtable release];
    }
    
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

-(NSUInteger)count{
    return [p_list count];
}

-(BLE_Discovered_Peripheral*)containsPeripheral:(CBPeripheral*)p {
    //BOOL found = NO;
    for (BLE_Discovered_Peripheral* btp in p_list) {
        if (p.identifier == btp.cbperipheral.identifier) {
            return btp;
            
        }
    }
    return nil;
}

-(NSUInteger)indexOfPeripheral:(CBPeripheral*)p {
    //BOOL found = NO;
    int idx = 0;
    for (BLE_Discovered_Peripheral* btp in p_list) {
        if (p.identifier == btp.cbperipheral.identifier) {
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
    NSUInteger idx = [self indexOfPeripheral:p.cbperipheral];
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
            [in_array addObject:blep];
        }
    }
    return in_array;
}

-(NSArray*)getOutOfRangePeripheralList {
    NSMutableArray* out_array = [[NSMutableArray alloc] initWithCapacity:0];
    for (BLE_Discovered_Peripheral* blep in p_list) {
        if (blep.inrange == NO) {
            [out_array addObject:blep];
        }
    }
    return out_array;

}


-(NSArray*)getPeripheralList {
    return p_list;
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
    peripherallinks = [[BLE_Peripheral_Links alloc] init];
    
    refQGCLinkManager = qgcApp()->toolbox()->linkManager();
    
    //init timer;
    t1 = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                     target:self
                                   selector:@selector(flipflag:)
                                   userInfo:nil
                                    repeats:YES];
    
    sync = NO;
    tt_update = NO;
    return self;
}


-(BOOL) createBTSerialLinkFromConfig:(BTSerialConfiguration_objc*)btcfg {
    
    QString ident = QString::fromNSString([btcfg getLinkId]);
    QString name = QString::fromNSString([btcfg getName]);

    BTSerialConfiguration* btconfig = new BTSerialConfiguration(QString::fromNSString([btcfg getName]));
    QString sid = QString::fromNSString(MAV_TRANSFER_SERVICE_UUID);
    QString cid = QString::fromNSString(MAV_TRANSFER_CHARACTERISTIC_UUID);
    
    btconfig->configBLESerialLink(ident, name, sid, cid, BLE_LINK_CONNECT_CHARACTERISTIC);

    refQGCLinkManager->createConnectedBLELink(btconfig);
    return YES;
    
}

-(BOOL) createBTSerialLinkFromPeripheral:(BLE_Discovered_Peripheral *)blep {
    
    //get the best display name of this device;
    QString ident = QString::fromNSString([blep.cbperipheral.identifier UUIDString]);
    QString name;
    
    NSString* blename;
    if (blep.advertisementdata==nil) {
        
        if (blep.cbperipheral.name == nil || [blep.cbperipheral.name compare:@""]==NSOrderedSame) {
            name = ident;
        }
        else {
            name = QString::fromNSString(blep.cbperipheral.name);
        }
        
    }
    else {
        blename = [(NSDictionary*)(blep.advertisementdata) valueForKey:CBAdvertisementDataLocalNameKey];
        if (blename != nil && [blename compare:@""]!=NSOrderedSame) {
            name = QString::fromNSString(blename);
        }
        else {
            if (blep.cbperipheral.name == nil || [blep.cbperipheral.name compare:@""]==NSOrderedSame) {
                name = ident;
            }
            else {
                name = QString::fromNSString(blep.cbperipheral.name);
            }
            
        }
    }
    
    BTSerialConfiguration* btconfig = new BTSerialConfiguration(name);
    QString sid = QString::fromNSString(MAV_TRANSFER_SERVICE_UUID);
    QString cid = QString::fromNSString(MAV_TRANSFER_CHARACTERISTIC_UUID);
    
    btconfig->configBLESerialLink(ident, name, sid, cid, BLE_LINK_CONNECT_CHARACTERISTIC);

    refQGCLinkManager->createConnectedBLELink(btconfig);
    return YES;

    
}


-(void)addLink:(BTSerialLink_objc*)link {
    [peripherallinks addLink:link];
}

-(void)deleteLink:(BTSerialLink_objc*)link {
    [peripherallinks deleteLink:link];
    
}

-(NSArray*)allLinks {
    return [peripherallinks allLinks];
}

-(NSArray*)connectedLinks {
    return [peripherallinks connectedLinks];
}

-(BTSerialLink_objc*)linkForPeripheral:(CBPeripheral*)p {
    return [peripherallinks linkForPeripheral:p];
}


-(CBCentralManager*)getBLECentralManager {
    return centralmanager;
}

-(void)flipflag :(id)sender{
    //for not connected devices;
    sync = YES;
    
    //for connected devices;
    tt_update = YES;
    //call readrssi one by one;
    
}

-(BOOL) setCallbackDelegate:(NSObject*)delegate{
    delegatecontroller = delegate;
    
}

-(id) getUICallbackDelegate {
    return delegatecontroller;
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
    CBPeripheral* p = [self getDiscoveredCBPeripheralFromIdentifier:identifier];
    if (p != nil) {
        [centralmanager connectPeripheral:p options:nil];
        return YES;
    }
    else {
        return NO;
    }
    
    
    
}

-(BLE_Discovered_Peripheral*)getDiscoveredBLEPeripheralFromIdentifier:(NSString*)identifier {
    NSArray* plist = [discoveredPeripherals getPeripheralList];
    for (BLE_Discovered_Peripheral* bp in plist) {
        if ([[bp.cbperipheral.identifier UUIDString] compare:identifier] == NSOrderedSame) {
            return bp;
        }
    }
    return nil;
    
}

-(BLE_Discovered_Peripheral*)getConnectedBLEPeripheralFromIdentifier:(NSString*)identifier {
    NSArray* plist = [connectedPeripheral getPeripheralList];
    for (BLE_Discovered_Peripheral* bp in plist) {
        if ([[bp.cbperipheral.identifier UUIDString] compare:identifier] == NSOrderedSame) {
            return bp;
        }
    }
    return nil;
    
}


-(CBPeripheral*)getDiscoveredCBPeripheralFromIdentifier:(NSString*)identifier {
    NSArray* plist = [discoveredPeripherals getPeripheralList];
    for (BLE_Discovered_Peripheral* bp in plist) {
        if ([[bp.cbperipheral.identifier UUIDString] compare:identifier] == NSOrderedSame) {
            return bp.cbperipheral;
        }
    }
    return nil;

}


-(CBPeripheral*)getConnectedCBPeripheralFromIdentifier:(NSString*)identifier {
    NSArray* plist = [connectedPeripheral getPeripheralList];
    for (BLE_Discovered_Peripheral* bp in plist) {
        if ([[bp.cbperipheral.identifier UUIDString] compare:identifier] == NSOrderedSame) {
            return bp.cbperipheral;
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
    if (connectedPeripheral != nil) {
        [connectedPeripheral release];
        connectedPeripheral = nil;
    }
    [super dealloc];
}


- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state)
    {
        case CBCentralManagerStatePoweredOn:
        {
            [centralmanager scanForPeripheralsWithServices:@[ [CBUUID UUIDWithString:MAV_TRANSFER_SERVICE_UUID]]
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
    if (p.advertisementdata == nil) {
        p.advertisementdata = [advertisementData copy];
    }
    
    if (p == nil) {
        //newly discovered, initialize;
        NSLog(@"newly discovered *********%@", peripheral.identifier);
        p = [[BLE_Discovered_Peripheral alloc] init];
        p.cbperipheral = [peripheral copy];
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
        
    
    if (averagedRSSI < -35/*-35*/)
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
                
                qgcApp()->toolbox()->linkManager()->didDiscoverBLELinks((__bridge void*)p_in, (__bridge void*)p_out);
                
                //TODO: do type check to ensure target call back handler conform with protocol;

                [delegatecontroller didDiscoverBTLinksInRange:p_in outOfRange:p_out];
                
                
            });
            
        }
        sync = NO;
    
}

/** If the connection fails for whatever reason, we need to deal with it.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    BTSerialLink_objc* link = [self linkForPeripheral:peripheral];
    assert(link);

    dispatch_async(dispatch_get_main_queue(), ^{
        
        //[(ConnectPopoverViewController*)delegatecontroller didFailToConnectBTLink];
        refQGCLinkManager->failedConnectBLEHardware(QString::fromNSString([peripheral.identifier UUIDString]));

        
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
    
    
    //create BLE_DISCOVERED_PERIPHERAL and add to connected list;
#pragma TD - remove duplicated bp creation;
    BLE_Discovered_Peripheral* bp = [[BLE_Discovered_Peripheral alloc] initWithCurrentRSSI:peripheral.RSSI.integerValue];
    bp.cbperipheral = peripheral;
    // Make sure we get the discovery callbacks
    peripheral.delegate = bp;

    [connectedPeripheral addPeripheral:bp];
    
    NSLog(@"connected peripheral: %@", bp);
    NSLog(@"connected device RSSI: %d", peripheral.RSSI.integerValue);
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //[delegatecontroller didConnectBTLink:peripheral result:YES];
        
        refQGCLinkManager->didConnectBLEHardware(QString::fromNSString([peripheral.identifier UUIDString]));
        //refQGCLinkManager->didConnectBLELink((__bridge BTSerialLink*)[link getCallerLinkPointer]);
        
    });

    
    
    //start update rssi of connected devices;
    if (t_connected==nil) {
        
        //init timer and start updating rssi for peripheral;
        t_connected = [NSTimer scheduledTimerWithTimeInterval:0.1f
                                                       target:self
                                                     selector:@selector(updaterssi:)
                                                     userInfo:nil
                                                      repeats:YES];
        
        
    }
}


/**
 start update rssi;
 
 **/
#pragma TBC - change updaterssi delegate;

-(void)updaterssi : (id)sender {
    //check all connected devices;
    
    NSArray* p_array = [connectedPeripheral getPeripheralList];

    for(BLE_Discovered_Peripheral* p in p_array) {
        [p updaterssi:sender];
    }
    
    if (tt_update) {
        //do update, notify UI;
        QList<QString> *p_uuidlist = new QList<QString>;
        
        for (BLE_Discovered_Peripheral* p in p_array) {
            p_uuidlist->append(QString::fromNSString([p.cbperipheral.identifier UUIDString]));
        }
        
        
        tt_update = NO;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // end of this time of update;
            if (p_uuidlist->count() > 0) {
                refQGCLinkManager->didUpdateConnectedBLELinkRSSI(p_uuidlist);
                
                
                [delegatecontroller didReadConnectedBTLinkRSSI:connectedPeripheral];
            }
            
        });
    }

    
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error {
    int filteredvalue;
    //QList<QString>* p_uuidlist = new QList<QString>();

    BLE_Discovered_Peripheral* p = [connectedPeripheral containsPeripheral:peripheral];
    assert(p==nil);
    
    //BTSerialLink_objc* link = [self linkForPeripheral:peripheral];
    if (error == nil) {
        filteredvalue = [p getFilteredRssi:peripheral.RSSI.intValue];
        //make a UUID Qlist of connected peripherals that has link quality status flipped;
        
    }

    //check next;
    if (cr_polling_idx < [connectedPeripheral count]-1) {
        CBPeripheral* p = [connectedPeripheral peripheralAtIndex:cr_polling_idx+1];
        [p readRSSI];
    }
    else {
        //reached end;
        
        if (tt_update) {
            //do update, notify UI;
            QList<QString> *p_uuidlist = new QList<QString>;
            
            for (BLE_Discovered_Peripheral* p in connectedPeripheral) {
                p_uuidlist->append(QString::fromNSString([peripheral.identifier UUIDString]));
            }
        

            tt_update = NO;

            dispatch_async(dispatch_get_main_queue(), ^{
                // end of this time of update;
                if (p_uuidlist->count() > 0) {
                    refQGCLinkManager->didUpdateConnectedBLELinkRSSI(p_uuidlist);
                

                    [delegatecontroller didReadConnectedBTLinkRSSI:connectedPeripheral];
                }
            
            });
        }
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
    
    //TODO: what if multiple links?
    BTSerialLink_objc* link = [self linkForPeripheral:peripheral];

    // Discover the characteristic we want...
    
    NSArray* sarray = peripheral.services;
    
    link.targetService = [peripheral.services objectAtIndex:0];
    
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    
    NSString* cid = [[link configuration] getCharacteristicId];
    NSLog(@"Characteristic ID: %@", cid);
    
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
    
    NSArray* carray = service.characteristics;
    
    NSLog(@"service contains %d characteristics.", [carray count]);
    
    BTSerialLink_objc* link = [self linkForPeripheral:peripheral];

    link.targetCharacteristic = [service.characteristics objectAtIndex:0];
    
    NSString* cid = [[link configuration] getCharacteristicId];
    
    [peripherallinks addLink:link];
    

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
        
        
        [delegatecontroller didConnectBTLink:peripheral result:YES];
        //call back to LinkManager to update link status;
        qgcApp()->toolbox()->linkManager()->didConnectBLELink((__bridge BTSerialLink*)[link getCallerLinkPointer]);
        
        //call back to mavlink protocol;
        //((__bridge BTSerialLink*)[link getCallerLinkPointer])->didConnect();
        
    });
    
    
    //build routing table of the peripheral;
    NSArray* sarray = peripheral.services;

    
    NSLog(@"connected device RSSI: %d", peripheral.RSSI.integerValue);
    //start update rssi of connected devices;
    if ([[peripherallinks allLinks] count]==1) {
        //first connected to this app;
        //add into list;
        BLE_Discovered_Peripheral* bp = [[BLE_Discovered_Peripheral alloc] initWithCurrentRSSI:peripheral.RSSI.integerValue];
        bp.cbperipheral = peripheral;
        [connectedPeripheral addPeripheral:bp];
        
        //init timer;
        t_connected = [NSTimer scheduledTimerWithTimeInterval:0.1f
                                                       target:self
                                                     selector:@selector(updaterssi:)
                                                     userInfo:nil
                                                      repeats:YES];

        
    }
    


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
        
        
        //[(ConnectPopoverViewController*)delegatecontroller didConnectedBTLink];
        //callback -> BTSerialLink -> LinkManager -> UI (MainToolBarController)
        //qgcApp()->toolbox()->linkManager()->didConnectBLELink();
        
        
    });
    
    
    
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
    
    BTSerialLink_objc* link = [self linkForPeripheral:peripheral];

    //did write and call back;
    //dispatch_async(dispatch_get_main_queue(), ^{
        
        
        //[(ConnectPopoverViewController*)delegatecontroller didReadBytes:characteristic.value];
        NSData* data = characteristic.value;
        ((__bridge BTSerialLink*)([link getCallerLinkPointer]))->didReadBytes((const char*)[data bytes], [data length]);
    //});

    NSString* aStr= [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSLog(@"%@, %d", aStr, [characteristic.value length]);
    /*
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
     */
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
///     @brief BLEHelperWrapper
///
///     @author

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
    
    void setPeripheralLinkQuality(QString& pname, BLE_LINK_QUALITY q);
    int currentFilteredPeripheralRSSI(QString& pname);
    BLE_LINK_QUALITY currentPeripheralLinkQuality(QString& pname);

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

void BLEHelperWrapper::setPeripheralLinkQuality(QString& pname, BLE_LINK_QUALITY q){
    BLE_Discovered_Peripheral* p = [ble_objc connectedPeripheralFromUUIDString:(qt2ioshelper::QString2NSString(&pname))];
    [p setLinkQuality:q];
}

int BLEHelperWrapper::currentFilteredPeripheralRSSI(QString& pname){
    BLE_Discovered_Peripheral* p = [ble_objc connectedPeripheralFromUUIDString:(qt2ioshelper::QString2NSString(&pname))];
    return [p currentFilteredRssi];
}

BLE_LINK_QUALITY BLEHelperWrapper::currentPeripheralLinkQuality(QString& pname){
    BLE_Discovered_Peripheral* p = [ble_objc connectedPeripheralFromUUIDString:(qt2ioshelper::QString2NSString(&pname))];
    return [p linkQuality];
    
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

void BLEHelper::setPeripheralLinkQuality(QString& pname, BLE_LINK_QUALITY q) {
    ble_wrapper->setPeripheralLinkQuality(pname, q);
}

int BLEHelper::currentFilteredPeripheralRSSI(QString& pname){
    return ble_wrapper->currentFilteredPeripheralRSSI(pname);
}

BLE_LINK_QUALITY BLEHelper::currentPeripheralLinkQuality(QString& pname){
    return ble_wrapper->currentPeripheralLinkQuality(pname);
}


/**
 BTSerialConfigurationWrapper
 
 **/

class BTSerialConfigurationWrapper {
    BTSerialConfiguration_objc* btc_objc;
public:
    BTSerialConfigurationWrapper();
    ~BTSerialConfigurationWrapper();
    void configBLESerialLink(QString& linkid, QString& linkname, QString& sid, QString& cid, BLE_LINK_CONNECT_STAGE stage);
    
};

BTSerialConfigurationWrapper::BTSerialConfigurationWrapper() {
    btc_objc = [[BTSerialConfiguration_objc alloc] init];
}

BTSerialConfigurationWrapper::~BTSerialConfigurationWrapper() {
    if (btc_objc!=nil) {
        
    
        [btc_objc release];
    }
}

void BTSerialConfigurationWrapper::configBLESerialLink(QString& linkid, QString& linkname, QString& sid, QString& cid, BLE_LINK_CONNECT_STAGE stage) {
    NSString* identifier = qt2ioshelper::QString2NSString(&linkid);
    NSString* name = qt2ioshelper::QString2NSString(&linkname);
    NSString* serviceid = qt2ioshelper::QString2NSString(&sid);
    NSString* characteristicid = qt2ioshelper::QString2NSString(&cid);
    
    [btc_objc configLinkId:identifier linkname:name serviceid:serviceid characteristicid:characteristicid stage:stage];
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
    bool _hardwareDisconnect();
    void setCallerLinkPointer (void*);
    
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
    QString qserviceid = config->getBLELinkServiceID();
    QString qcharacteristicid = config->getBLELinkCharacteristicID();

    NSString* identifier = qt2ioshelper::QString2NSString(&qidentifier);
    NSString* name = qt2ioshelper::QString2NSString(&qname);
    NSString* serviceid = qt2ioshelper::QString2NSString(&qserviceid);
    NSString* characteristicid = qt2ioshelper::QString2NSString(&qcharacteristicid);

    BTSerialConfiguration_objc* config_obj = [[BTSerialConfiguration_objc alloc] init];
    BLE_LINK_CONNECT_STAGE linkstage = config->getBLELinkConnectStage();

    [config_obj configLinkId:identifier linkname:name serviceid:serviceid characteristicid:characteristicid stage:linkstage];

    //configBLESerialLink(identifier, name, serviceid, characteristicid);
    return config_obj;
}


bool BTSerialLinkWrapper::_connect() {
    //btl_objc = [[BTSerialLink_objc alloc] init];
    //NSString* nsidentifier = qt2ioshelper::QString2NSString(identifier);
    [btl_objc connect];
    return true;
}

bool BTSerialLinkWrapper::_hardwareConnect() {
    [btl_objc hardwareConnect];
    return true;
}

bool BTSerialLinkWrapper::_disconnect() {
    [btl_objc disconnect];
}

#pragma TBC complete disconnect;
bool BTSerialLinkWrapper::_hardwareDisconnect() {
    [btl_objc hardwareDisconnect];

}


void BTSerialLinkWrapper::setCallerLinkPointer (void* delegate) {
    [btl_objc setCallerLinkPointer:(__bridge id)delegate];
}


/******************************************
 BTSerialLink class;
 
 */

BTSerialLink::BTSerialLink(BTSerialConfiguration *config)
//, _socket(NULL)
//, _socketIsConnected(false)
: _mavlinkChannelSet(false)
, _linkstatus(BLE_LINK_NOT_CONNECTED)
, _linkquality(BLE_LINK_QUALITY_INRANGE)
{
    _config = config;
    Q_ASSERT(_config != NULL);

    btlwrapper = new BTSerialLinkWrapper(config);
    btlwrapper -> setCallerLinkPointer(this);
    
    qDebug() << "Bluetooth serial comm Created " << _config->name();
    
    

}

BTSerialLink::BTSerialLink(BTSerialConfiguration* config, MAVLinkProtocol* handler)
:mavhandler(handler)
,_mavlinkChannelSet(false)
, _linkstatus(BLE_LINK_NOT_CONNECTED)
, _linkquality(BLE_LINK_QUALITY_INRANGE)

{
    _config = config;
    Q_ASSERT(_config != NULL);
    Q_ASSERT(mavhandler != NULL);
    
    btlwrapper = new BTSerialLinkWrapper(config);
    btlwrapper -> setCallerLinkPointer(this);
    
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


void BTSerialLink::setLinkConnectedStatus(BLE_LINK_STATUS status) {
    _linkstatus = status;
}

BLE_LINK_STATUS BTSerialLink::linkConnectedStatus() {
    return _linkstatus;
}

BLE_LINK_QUALITY BTSerialLink::linkQuality() {
    return _linkquality;
}


void BTSerialLink::setMAVLinkProtocolHandler(MAVLinkProtocol* protocolhandler) {
    mavhandler = protocolhandler;
}


void BTSerialLink::didReadBytes(const char* data, qint64 size) {
    mavhandler->receiveBytes(this, QByteArray::QByteArray(data, size));
}

void BTSerialLink::didConnect() {
    mavhandler->linkConnected(this);
}

void BTSerialLink::didDisconnect() {
    mavhandler->linkDisconnected(this);
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

void BTSerialLink::writeBytesNeedsAck(QString characteristic, const char* data, qint64 size) {
    
}

void BTSerialLink::writeBytesNeedsAck(const char* data, qint64 size) {
    
}


/*
void writeBytes(QString characteristic, const char* data, qint64 size);
void writeBytesNeedsAck(QString characteristic, const char* data, qint64 size);

void writeBytes(const char* data, qint64 size);
void writeBytesNeedsAck(const char* data, qint64 size);
*/

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
    btlwrapper->_disconnect();
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
    
    return true;
    
}

bool BTSerialLink::_hardwareConnect()
{
    //try establish physical link to peripheral;
    //QString* identifier = _config->getBLEPeripheralIdentifier();
    
    return btlwrapper->_hardwareConnect();
    
}


bool BTSerialLink::_hardwareDisconnect() {
    
    return btlwrapper->_hardwareDisconnect();
    
}


void BTSerialLink::setCallbackDelegate(void* delegate) {
    //btlwrapper->setCallbackDelegate(delegate);
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

BTSerialConfiguration::BTSerialConfiguration(const QString& name) : LinkConfiguration(name), connstage(BLE_LINK_CONNECT_CHARACTERISTIC)
{
    //_port    = QGC_TCP_PORT;
    //_address = QHostAddress::Any;
    btcwrapper =  new BTSerialConfigurationWrapper();
}

BTSerialConfiguration::BTSerialConfiguration(BTSerialConfiguration* source) : LinkConfiguration(source), connstage(BLE_LINK_CONNECT_CHARACTERISTIC)
{
    //_port    = source->port();
    //_address = source->address();

}

BTSerialConfiguration:: ~BTSerialConfiguration() {
    if (btcwrapper!=NULL) {
        delete btcwrapper;
    }
}

bool BTSerialConfiguration::operator== (BTSerialConfiguration* cfg) {
    if (identifier == cfg->getBLEPeripheralIdentifier() &&
        pname == cfg->getBLEPeripheralName() &&
        serviceID == cfg->getBLELinkServiceID() &&
        characteristicID == cfg->getBLELinkCharacteristicID() ) {
        return true;
    }
    return false;
}


void BTSerialConfiguration::configBLESerialLink(QString& linkid, QString& linkname, QString& sid, QString& cid, BLE_LINK_CONNECT_STAGE stage) {

    identifier = linkid;
    pname = linkname;
    serviceID = sid;
    characteristicID = cid;
    connstage = stage;
    
    btcwrapper -> configBLESerialLink (identifier, pname, serviceID, characteristicID, stage);
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


QString BTSerialConfiguration::settingsURL() {
    //for the moments;
    return "";
}

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

QString BTSerialConfiguration::getBLEPeripheralIdentifier() {
    return identifier;
}

QString BTSerialConfiguration::getBLEPeripheralName() {
    return pname;
}

QString BTSerialConfiguration::getBLELinkServiceID() {
    return serviceID;
}

QString BTSerialConfiguration::getBLELinkCharacteristicID() {
    return characteristicID;
}

BLE_LINK_CONNECT_STAGE BTSerialConfiguration::getBLELinkConnectStage() {
    return connstage;
}


/***************************
 Objective C implementation
 
 ***************/

@interface BTSerialLink_objc ()<CBCentralManagerDelegate,CBPeripheralDelegate>
{
    CBCharacteristic *writeCharacteristic;
    
}
//@property (nonatomic, strong) CBCentralManager *manager;
//@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSObject* centraldelegate;
@property (nonatomic, strong) NSObject* peripheraldelegate;


@end


@implementation BTSerialLink_objc
@synthesize centraldelegate, peripheraldelegate, targetCharacteristic, targetService, isInRange;

-(BTSerialLink_objc*)init {
    [super init];
    if (self)
    {
        self.centraldelegate = self;
        self.peripheraldelegate = self;
        
        connectTimer = nil;
        cbmgr = [[BLEHelper_objc sharedInstance] getBLECentralManager];
    }
    return self;
}


-(BTSerialLink_objc*)initWith:(BTSerialConfiguration_objc*)config {
    [super init];
    if (self)
    {
        centraldelegate = self;
        peripheraldelegate = self;
        
        connectTimer = nil;
        config_objc = config;
        cbmgr = [[BLEHelper_objc sharedInstance] getBLECentralManager];
    }
    return self;
}


-(BTSerialConfiguration_objc*)configuration {
    return config_objc;
}


/*
 Link status
 */

-(BLE_LINK_STATUS)linkStatus {
    assert(caller_link_ptr!=nil);
    return ((BTSerialLink*)caller_link_ptr)->linkConnectedStatus();
}

-(void)setLinkStatus:(BLE_LINK_STATUS)linkStatus {
    assert(caller_link_ptr!=nil);
    ((BTSerialLink*)caller_link_ptr)->setLinkConnectedStatus(linkStatus);
    
#pragma TBC
    
}


-(void)readBytes {
    [cbp readValueForCharacteristic:targetCharacteristic];
}


/*
//link rssi;
-(void)startUpdateLinkRSSI:(int)currentRssi {
    lp_filter = [[BLE_LowPassFilter_objc alloc] initWith:currentRssi];
    
    

}

-(int)getFilteredRssi:(int)rssi

{
    [lp_filter updateWindowWith:rssi];
    return [lp_filter filteredRssi];
}
*/


-(void)writeBytes:(const char*)data size:(int)size {
    
    //NSString* cid = [config_objc getCharacteristicId];
    assert(targetCharacteristic!=nil);
    
    NSData *ndata = [NSData dataWithBytes: data length:size];
    [cbp writeValue:ndata forCharacteristic:targetCharacteristic type:CBCharacteristicWriteWithoutResponse];
}


-(void)writeBytesNeedsAck:(const char*)data size:(int)size {
    //NSString* cid = [config_objc getCharacteristicId];
    
    assert(targetCharacteristic!=nil);
    
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
        
        
        //[(ConnectPopoverViewController*)delegatecontroller didConnectedBTLink];
        //callback -> BTSerialLink -> LinkManager -> UI (MainToolBarController)
        //qgcApp()->toolbox()->linkManager()->didConnectBLELink();

        
    });
    

    
}

-(void)writeBytes:(const char*)data characteristic:(CBCharacteristic*)cid size:(int)size {
    
}

-(void)writeBytesNeedsAck:(const char *)data characteristic:(CBCharacteristic*)cid size:(int)size {
    
}


-(void)setCallerLinkPointer:(id)delegate {
    //delegatecontroller = delegate;
    caller_link_ptr = delegate;
}

-(id)getCallerLinkPointer {
    return caller_link_ptr;
}

-(BOOL)connect {
    
    NSString* identifier = [config_objc getLinkId];
    //connectstage = BLE_LINK_CONNECT_CHARACTERISTIC;

    bdp  =  [[BLEHelper_objc sharedInstance] getConnectedBLEPeripheralFromIdentifier:(NSString*)identifier];
    
    //set peripheral delegate to this link; not needed?
    // ble_cbp setDelegate = ble_cbp;
    cbp = bdp.cbperipheral;
    
    //discover service/characteristic and subscribe to it;
    NSString* sid = [config_objc getServiceId];
    
    //assert(connectTimer==nil);
    if (connectTimer!=nil) {
        //hardware connected, mute previous hardware connect timer;
        [connectTimer invalidate];
        connectTimer = nil;

    }
    connectTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f
                                                    target:self
                                                  selector:@selector(connectTimeOut)
                                                  userInfo:nil
                                                   repeats:YES];
    
    NSLog(@"Trying building link to connected BLE peripheral %@", bdp);

    assert(bdp != nil);
    
    [bdp buildConnectionForLink:self];
    //[cbp discoverServices:@[[CBUUID UUIDWithString:sid]]];
     
    //add to connecting peripheral list;
    //[[BLEHelper_objc sharedInstance] addLink:self];
    
    //[cbmgr connectPeripheral:cbp options:nil];
}

-(BOOL)hardwareConnect {
    NSString* identifier = [config_objc getLinkId];
    //connectstage = BLE_LINK_CONNECT_PERIPHERAL;
    
    cbp =  [[BLEHelper_objc sharedInstance] getDiscoveredCBPeripheralFromIdentifier:(NSString*)identifier];
    
    connectTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f
                                                   target:self
                                                 selector:@selector(hardwareConnectTimeOut)
                                                 userInfo:nil
                                                  repeats:YES];

    
    [cbmgr connectPeripheral:cbp options:nil];

}

-(BOOL)hardwareDisconnect {
    [cbmgr connectPeripheral:cbp options:nil];
    return YES;
    
}


-(void)hardwareConnectTimeOut {
    //mute timer;
    [connectTimer invalidate];
    connectTimer = nil;
    
    //call failed connecting;
    [bdp failedBuildLinkConnection:self];

}


-(void)connectTimeOut {
    //mute timer;
    [connectTimer invalidate];
    connectTimer = nil;
    
    //clean up trial lists;
    [bdp failedBuildLinkConnection:self];
    
    //call failed connecting;
    
}


-(void)didConnectHardware {
    
}

-(void)didConnect {
    //mute timer;
    [connectTimer invalidate];
    connectTimer = nil;

    id uidelegate = [[BLEHelper_objc sharedInstance] getUICallbackDelegate];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (uidelegate != nil) {
                [uidelegate didConnectBTLink:bdp.cbperipheral result:YES];
        }
        
        //call back to LinkManager to update link status;
        qgcApp()->toolbox()->linkManager()->didConnectBLELink((__bridge BTSerialLink*)[self getCallerLinkPointer]);
        NSLog(@"BLE link connected.");
        
        //call back to mavlink protocol;
        //((__bridge BTSerialLink*)[link getCallerLinkPointer])->didConnect();
        
    });

}

-(void)failedConnectHardware {
    
}

-(void)failedConnect{
    
    id uidelegate = [[BLEHelper_objc sharedInstance] getUICallbackDelegate];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (uidelegate != nil) {
            [uidelegate failedConnectBTLink:bdp.cbperipheral result:YES];
        }

        //call back to LinkManager to update link status;
        qgcApp()->toolbox()->linkManager()->failedConnectBLELink((__bridge BTSerialLink*)[self getCallerLinkPointer]);
        
        //call back to mavlink protocol;
        //((__bridge BTSerialLink*)[link getCallerLinkPointer])->didConnect();
        
    });

}


-(BOOL)disconnect {
    NSString* identifier = [config_objc getLinkId];
    //connectstage = BLE_LINK_CONNECT_CHARACTERISTIC;
    
    cbp  =  [[BLEHelper_objc sharedInstance] getConnectedCBPeripheralFromIdentifier:(NSString*)identifier];
    //unsubscribe from service;
    [cbp setNotifyValue:NO forCharacteristic:targetCharacteristic];

    
    //remove objc config object;
    
    //remove connecting peripheral list;
    [[BLEHelper_objc sharedInstance] deleteLink:self];
    
    //leave the hardware disconnect to LinkManager;
    //[cbmgr cancelPeripheralConnection:cbp];
    [bdp removeLink:self];
    
    //LinkManager call back;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //call back to LinkManager to update link status;
        qgcApp()->toolbox()->linkManager()->disconnectLink((__bridge BTSerialLink*)[self getCallerLinkPointer]);
        
        //call back to mavlink protocol;
        //((__bridge BTSerialLink*)[link getCallerLinkPointer])->didConnect();
        
    });
    
    

}

-(CBPeripheral*)peripheralForLink {
    return cbp;
}

-(BLE_LINK_CONNECT_STAGE)connectStage {
    return [config_objc connectStage];
}



/*
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state)
    {
        case CBCentralManagerStatePoweredOn:
        {
            [central scanForPeripheralsWithServices:@[ [CBUUID UUIDWithString:kServiceUUID]]
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
*/

@end


@implementation BTSerialConfiguration_objc

-(void)configLinkId:(NSString*)linkid linkname:(NSString*)name serviceid:(NSString*)sid characteristicid:(NSString*)cid stage:(BLE_LINK_CONNECT_STAGE)stage
{
    
    link_identifier=[linkid copy];
    link_name=[name copy];
    link_service_id=[sid copy];
    link_characteristic_id=[cid copy];
    connectstage = stage;

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

-(BLE_LINK_CONNECT_STAGE)connectStage {
    return connectstage;
}


@end

@implementation BLE_Peripheral_Links

-(BLE_Peripheral_Links*)init {
    [super init];
    if (self) {
        p_links = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

-(void)addLink:(BTSerialLink_objc*) link {
    [p_links addObject:link];
}

-(void)deleteLink:(BTSerialLink_objc*)link {
    if ([p_links indexOfObject:link] != NSNotFound) {
        [p_links removeObject:link];
    }
}

-(NSArray*)connectedLinks {
    
}

-(NSArray*)allLinks {
    return p_links;
}

-(BTSerialLink_objc*)linkForPeripheral:(CBPeripheral*)p {
    for (BTSerialLink_objc* link in p_links) {
        if ([[link peripheralForLink] isEqual: p]) {
            return link;
        }
    }
    return nil;
}

-(CBPeripheral*)peripheralForLink:(BTSerialLink_objc*)link {
    return [link peripheralForLink];
}

-(void)emptyList{
    
}


-(void)dealloc {
    if (self) {
        [self emptyList];
    }
    [p_links release];
}

@end
