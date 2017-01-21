//
//  BTSerialLink_objc.h
//  qgroundcontrol
//
//  Created by ning roland on 10/15/15.
//
//

#ifndef qgroundcontrol_BTSerialLink_objc_h
#define qgroundcontrol_BTSerialLink_objc_h

#include "BTSerialLink.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLELinkConnectionDelegate.h"

//class BTSerialConfigurationWrapper;
//class BTSerialLinkWrapper;

#define LP_RSSI_WINDOW_LENGTH 10

typedef enum {
    BLE_Peripheral_HARDWARE_NOTCONNECTED,
    BLE_Peripheral_HARDWARE_CONNECTING,
    BLE_Peripheral_HARDWARE_CONNECTED
    
}BLE_Peripheral_HARDWARECONNECT_STATUS;

@interface BLE_LowPassFilter_objc : NSObject {
    int lp_win[LP_RSSI_WINDOW_LENGTH]; //ring buffer
    int rp;

}
-(BLE_LowPassFilter_objc*)init;
-(BLE_LowPassFilter_objc*)initWith:(int)rssi;

-(int)filteredRssi;
-(void)updateWindowWith:(int)rssi;
@end


/*
 BLEHelper_objc use this hashtable to route central delegate call to matching link delegate of peripheral objects.
 
 p_links table use peripheral as key to index dispatch table; dispatch table use sid + cid to index matching link object;
 
 */

@class BTSerialLink_objc;

@interface BLE_LinkRouting_Hashtable : NSObject {
    /*
     Do NOT subclass NSMutableDictionary, extend it.
     */
    NSMutableDictionary* hashtable;
    
   
}

-(instancetype)initWithCapacity:(NSUInteger)numItems;
-(void)addMetaCharacteristic:(CBCharacteristic*)character forService:(CBService*)service;
-(void)routingCharacteristic:(CBCharacteristic*)chara inService: (CBService*)service toLink:(BTSerialLink_objc*)link;
-(BTSerialLink_objc*)linkForCharacteristic:(CBCharacteristic*)character inService:(CBService*)service;
-(void)removeRoutingEntryofLink:(BTSerialLink_objc*)link;

@end


//Discovered peripheral until disconnected/scan stopped;
@interface BLE_Discovered_Peripheral : NSObject <CBPeripheralDelegate>{
    //CBPeripheral* p;
    BLE_LowPassFilter_objc* lp_filter;
    //BOOL inrange;
    //BOOL connected;
    BLE_Peripheral_HARDWARECONNECT_STATUS connectStatus;
    BLE_LINK_QUALITY linkquality;
    NSMutableArray* servicetryconnectionlist;  //link vs. CBService;
    NSMutableArray* characteristictryconnectionlist;  //link vs. CBService;
    
    NSTimer* t_connected; //connected rssi timer, every 100ms;

    //link routing table;
    BLE_LinkRouting_Hashtable* rtable;
    
}

@property (assign, nonatomic) CBPeripheral*  cbperipheral;

//for the moment; define platform independent advertisement data object for discovering stage in BTSerialLink class;
@property (assign, nonatomic) NSDictionary*  advertisementdata;

@property (assign, nonatomic) BOOL inrange;
@property (assign, nonatomic) BOOL connected;

//-(CBPeripheral*)peripheral;
-(BLE_Discovered_Peripheral*)init;
-(BLE_Discovered_Peripheral*)initWithCurrentRSSI:(int)rssi;

-(BLE_Discovered_Peripheral*)BLEPeripheralFromCBPeripheral:(CBPeripheral*)p;

-(void)isInRange;
-(void)outOfRange;
-(BOOL)isConnected;
-(void)isDisconnected;
-(int)getFilteredRssi:(int)rssi;
-(int)currentFilteredRssi;
-(BLE_Peripheral_HARDWARECONNECT_STATUS)hardwareConnectStatus;
-(void)setHardwareConnectStatus:(BLE_Peripheral_HARDWARECONNECT_STATUS)status;
-(BLE_LINK_QUALITY)linkQuality;
-(void)setLinkQuality : (BLE_LINK_QUALITY) quality;
-(BOOL)buildMetaRoutingTable; //on connected;
-(BOOL)buildConnectionForLink:(BTSerialLink_objc*)link;
-(void)failedBuildLinkConnection:(BTSerialLink_objc*)link;
-(void)removeLink:(BTSerialLink_objc*)link;
-(BTSerialLink_objc*)linkForCharacteristic:(CBCharacteristic*)characteristic inService: (CBService*)service ;
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
-(NSArray*)getPeripheralList;
-(NSUInteger)counts;

@end



@interface BLEHelper_objc: NSObject {
    int rp;
    NSTimer* t1; //scan rssi timer, every 1s;
    NSTimer* t_connected; //connected rssi timer, every 100ms;
    
    BOOL sync; // flag for not connected peripherals;
    BOOL tt_update; // flag for connected peripherals;
    
    id <BLELinkConnectionDelegate> delegatecontroller;

}

@end

@interface BTSerialConfiguration_objc : NSObject {
    NSString* link_identifier; //peripheral id;
    NSString* link_name; //display name;
    NSString* link_service_id; //service id;
    NSString* link_characteristic_id; //characteristic id;
    BLE_LINK_CONNECT_STAGE connectstage;
}

-(void)configLinkId:(NSString*)linkid linkname:(NSString*)name serviceid:(NSString*)sid characteristicid:(NSString*)cid stage:(BLE_LINK_CONNECT_STAGE)stage;
-(NSString*)getLinkId;
-(NSString*)getServiceId;
-(NSString*)getCharacteristicId;
-(NSString*)getName;
-(BLE_LINK_CONNECT_STAGE)connectStage;

@end


@interface BTSerialLink_objc : NSObject {
    CBCentralManager* cbmgr;
    CBPeripheralManager* cbpmgr;
    
    CBPeripheral* cbp;
    BLE_Discovered_Peripheral* bdp;
    
    //CBService* targetService;
    //CBCharacteristic* targetCharacteristic;
    
    //id delegatecontroller;
    id caller_link_ptr;
    
    BTSerialConfiguration_objc* config_objc;
    
    //BLE_LINK_CONNECT_STAGE connectstage;
    
    BLE_LowPassFilter_objc* lp_filter;
    
    //link connection timer for time out monitoring;
    NSTimer* connectTimer;


}
@property (assign, nonatomic) CBService*  targetService;
@property (assign, nonatomic) CBCharacteristic*  targetCharacteristic;
@property (assign, nonatomic) BOOL isInRange;


-(BTSerialLink_objc*)initWith:(BTSerialConfiguration_objc*)config;

-(void)setCallerLinkPointer:(id)delegate;
-(BOOL)connect;
-(BOOL)hardwareConnect;
-(BOOL)hardwareDisconnect;

-(void)didConnect;
-(void)failedConnect;

//link status;
-(BLE_LINK_STATUS)linkStatus;
-(void)setLinkStatus:(BLE_LINK_STATUS)linkStatus;

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
-(void)endUpdateLinkRSSI;

-(int)getFilteredRssi:(int)rssi;

-(id)getCallerLinkPointer;

@end





@interface BLE_Peripheral_Links : NSObject {
    NSMutableArray* p_links;
    //NSMutableDictionary* p_links;
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
