//
//  BLELinkConnectionDelegate.h
//  QGroundControl
//
//  Created by ning roland on 10/16/16.
//
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol BLELinkConnectionDelegate <NSObject>

@required
-(void)didDiscoverBTLinksInRange:(NSArray*)p_in outOfRange:(NSArray*)p_out ;
-(void)didConnectBLEHardware:(CBPeripheral*)cbp;
-(void)failedConnectBLEHardware:(CBPeripheral*)cbp;
-(void)didConnectBTLink:(CBPeripheral*)cbp result:(BOOL)yor ;
-(void)failedConnectBTLink:(CBPeripheral*)cbp result:(BOOL)yor ;

@optional
-(void)didReadConnectedBTLinkRSSI:(CBPeripheral*)cbp RSSI:(int)rssi inrange:(BOOL)inrange ;



@end
