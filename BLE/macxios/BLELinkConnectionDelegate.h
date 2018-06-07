//
//  BLELinkConnectionDelegate.h
//  QGroundControl
//
//  Created by ning roland on 10/16/16.
//
//


/**
 Any objC UI interface that handling BLE links need to conform to this protocol;
 
 **/

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class BLE_Discovered_Peripheral_List;



@protocol BLELinkConnectionDelegate <NSObject>

@required
-(void)didDiscoverBTLinksInRange:(NSArray*)p_in outOfRange:(NSArray*)p_out ;
-(void)didConnectBLEHardware:(CBPeripheral*)cbp;
-(void)failedConnectBLEHardware:(CBPeripheral*)cbp;
-(void)didConnectBTLink:(CBPeripheral*)cbp result:(BOOL)yor ;
-(void)failedConnectBTLink:(CBPeripheral*)cbp result:(BOOL)yor ;

@optional
-(void)didReadConnectedBTLinkRSSI:(BLE_Discovered_Peripheral_List*)cbplist;



@end
