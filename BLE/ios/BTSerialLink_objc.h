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


@interface BLE_LowPassFilter_objc : NSObject {
    int lp_win[LP_RSSI_WINDOW_LENGTH]; //ring buffer
    int rp;

}
-(BLE_LowPassFilter_objc*)init;
-(int)filteredRssi;
-(void)updateWindowWith:(int)rssi;
@end


//Discovered peripheral until disconnected/scan stopped;
@interface BLE_Discovered_Peripheral : NSObject {
    //CBPeripheral* p;
    BLE_LowPassFilter_objc* lp_filter;
    BOOL inrange;
    BOOL connected;
}

@property (assign, nonatomic) CBPeripheral*  peripheral;
@property (assign, nonatomic) BOOL inrange;
@property (assign, nonatomic) BOOL connected;

//-(CBPeripheral*)peripheral;
-(BLE_Discovered_Peripheral*)init;
-(void)isInRange;
-(void)outOfRange;
-(void)isConnected;
-(void)isDisconnected;
-(int)getFilteredRssi:(int)rssi;

@end

@interface BLE_Discovered_Peripheral_List : NSMutableArray {
    
}

-(BLE_Discovered_Peripheral*)containsPeripheral:(CBPeripheral*)p;
-(NSUInteger)indexOfPeripheral:(CBPeripheral*)p;
-(BOOL)addPeripheral:(BLE_Discovered_Peripheral*)p;
-(BOOL)removePeripheral:(BLE_Discovered_Peripheral*)p;
-(NSArray*)getInRangePeripheralList;
-(NSArray*)getOutOfRangePeripheralList;

@end

@interface BLEHelper_objc: NSObject {
    //int lp_window_lenth;
    int rp;
    NSTimer* t1;
    BOOL sync;
}

@end

@interface BTSerialConfiguration_objc : NSObject {
    
}

@end


@interface BTSerialLink_objc : NSObject {
    CBCentralManager* cbmgr;
    CBPeripheralManager* cbpmgr;
}



@end



#endif
