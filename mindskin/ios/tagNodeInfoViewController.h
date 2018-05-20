//
//  tagNodeInfoViewController.h
//  MindSkin
//
//  Created by ning roland on 11/13/17.
//
//

#import <UIKit/UIKit.h>
#import "BTSerialLink_objc.h"
#import "ParameterLoadHelper_objc.h"

@interface tagNodeInfoViewController : UITabBarController <UIParameterLoadProgressDelegate> {
    BTSerialConfiguration_objc* tagNodeLinkConfig;
    ParameterLoadHelper_objc* param_helper;
    
    //IBOutlet UIProgressView* paraProgressView;

}

-(void)setParameterHelper:(ParameterLoadHelper_objc*)paramHelper;

-(void) setNodeLinkConfigration:(BTSerialConfiguration_objc*)btc_objc;
-(BTSerialConfiguration_objc*) getNodeLinkConfiguration;

@end
