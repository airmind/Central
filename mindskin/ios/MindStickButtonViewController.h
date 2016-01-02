//
//  MindStickButtonViewController.h
//  qgroundcontrol
//
//  Created by ning roland on 12/22/15.
//
//

#import <UIKit/UIKit.h>
#import "BTSerialLink_objc.h"

@interface MindStickButtonViewController : UIViewController {
    UIButton* statusButton;
}

-(void)showStatusButton;
-(void)removeStatusButton;
-(void)enable;
-(void)disable;
-(void)updateLinkRSSI:(BLE_Peripheral_Links*) list;

@end
