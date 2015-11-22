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


@interface BLEHelper_objc: NSObject {
    
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
