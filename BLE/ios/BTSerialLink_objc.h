//
//  BTSerialLink_objc.h
//  qgroundcontrol
//
//  Created by ning roland on 10/15/15.
//
//

#ifndef qgroundcontrol_BTSerialLink_objc_h
#define qgroundcontrol_BTSerialLink_objc_h

#import <CoreBluetooth/CoreBluetooth.h>

//class BTSerialConfigurationWrapper;
//class BTSerialLinkWrapper;

#define LP_RSSI_WINDOW_LENGTH 10

typedef enum {
    BLE_LINK_CONNECTED_PERIPHERAL,
    BLE_LINK_CONNECTED_SERVICE,
    BLE_LINK_CONNECTED_CHARACTERISTIC
    
}BLE_LINK_CONNECT_STAGE ;

@interface BLE_LowPassFilter_objc : NSObject {
    int lp_win[LP_RSSI_WINDOW_LENGTH]; //ring buffer
    int rp;

}
-(BLE_LowPassFilter_objc*)init;
-(BLE_LowPassFilter_objc*)initWith:(int)rssi;

-(int)filteredRssi;
-(void)updateWindowWith:(int)rssi;
@end


//Discovered peripheral until disconnected/scan stopped;
@interface BLE_Discovered_Peripheral : NSObject {
    //CBPeripheral* p;
    BLE_LowPassFilter_objc* lp_filter;
    //BOOL inrange;
    //BOOL connected;
}

@property (assign, nonatomic) CBPeripheral*  peripheral;
@property (assign, nonatomic) BOOL inrange;
@property (assign, nonatomic) BOOL connected;

//-(CBPeripheral*)peripheral;
-(BLE_Discovered_Peripheral*)init;
-(BLE_Discovered_Peripheral*)initWithCurrentRSSI:(int)rssi;

-(BLE_Discovered_Peripheral*)BLEPeripheralFromCBPeripheral:(CBPeripheral*)p;

-(void)isInRange;
-(void)outOfRange;
-(void)isConnected;
-(void)isDisconnected;
-(int)getFilteredRssi:(int)rssi;


@end

@interface BLE_Discovered_Peripheral_List : NSObject {
    //TODO: need a time out for power down device in range?
    NSMutableArray* p_list; //BLE_peripheral list;
}
-(BLE_Discovered_Peripheral_List*)init;
-(BLE_Discovered_Peripheral*)containsPeripheral:(CBPeripheral*)p;
-(NSUInteger)indexOfPeripheral:(CBPeripheral*)p;
-(CBPeripheral*)peripheralAtIndex:(NSUInteger)idx;
-(BOOL)addPeripheral:(BLE_Discovered_Peripheral*)p;
-(BOOL)removePeripheral:(BLE_Discovered_Peripheral*)p;
-(NSArray*)getInRangePeripheralList;
-(NSArray*)getOutOfRangePeripheralList;
-(void)emptyList;
-(NSArray*)getDiscoveredPeripheralList;
-(NSUInteger)counts;

@end



@interface BLEHelper_objc: NSObject {
    int rp;
    NSTimer* t1; //scan rssi timer, every 1s;
    NSTimer* t_connected; //connected rssi timer, every 100ms;
    BOOL sync;
}

@end

@interface BTSerialConfiguration_objc : NSObject {
    NSString* link_identifier; //peripheral id;
    NSString* link_name; //display name;
    NSString* link_service_id; //service id;
    NSString* link_characteristic_id; //characteristic id;
}

-(void)configLinkId:(NSString*)linkid linkname:(NSString*)name serviceid:(NSString*)sid characteristicid:(NSString*)cid;
-(NSString*)getLinkId;
-(NSString*)getServiceId;
-(NSString*)getCharacteristicId;
-(NSString*)getName;

@end


@interface BTSerialLink_objc : NSObject {
    CBCentralManager* cbmgr;
    CBPeripheralManager* cbpmgr;
    
    CBPeripheral* cbp;
    //CBService* targetService;
    //CBCharacteristic* targetCharacteristic;
    
    //id delegatecontroller;
    id caller_link_ptr;
    
    BTSerialConfiguration_objc* config_objc;
    
    BLE_LINK_CONNECT_STAGE connectstage;
    
    BLE_LowPassFilter_objc* lp_filter;


}
@property (assign, nonatomic) CBService*  targetService;
@property (assign, nonatomic) CBCharacteristic*  targetCharacteristic;


-(BTSerialLink_objc*)initWith:(BTSerialConfiguration_objc*)config;

-(void)setCallerLinkPointer:(id)delegate;
-(BOOL)connect:(NSString*) identifier;

//read/write;

-(void)readBytes;
-(void)readBytes:(CBCharacteristic*)characteristic;

-(void)writeBytes:(const char*)data size:(long long)size ;
-(void)writeBytesNeedsAck:(const char*)data size:(long long)size ;

-(void)writeBytes:(const char*)data characteristic:(CBCharacteristic*)cid size:(long long)size ;
-(void)writeBytesNeedsAck:(const char *)data characteristic:(CBCharacteristic*)cid size:(long long)size ;
-(CBPeripheral*)peripheralForLink;
-(BLE_LINK_CONNECT_STAGE)connectStage;
-(BTSerialConfiguration_objc*)configuration;

//link rssi;
-(void)startUpdateLinkRSSI:(int)currentRssi;
-(int)getFilteredRssi:(int)rssi;

-(id)getCallerLinkPointer;

@end


@interface BLE_Peripheral_Links : NSObject {
    NSMutableArray* p_links;
}

-(BLE_Peripheral_Links*)init;

-(void)addLink:(BTSerialLink_objc*) link;
-(void)deleteLink:(BTSerialLink_objc*)link;

-(NSArray*)connectedLinks;
-(NSArray*)allLinks;
-(BTSerialLink_objc*)linkForPeripheral:(CBPeripheral*)p;
-(CBPeripheral*)peripheralForLink:(BTSerialLink_objc*)link;
-(void)emptyList;

@end

#endif
