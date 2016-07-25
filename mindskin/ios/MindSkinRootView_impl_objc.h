//
//  MindSkinRootView_impl_objc.h
//  qgroundcontrol
//
//  Created by ning roland on 6/16/16.
//
//

#ifndef qgroundcontrol_MindSkinRootView_impl_objc_h
#define qgroundcontrol_MindSkinRootView_impl_objc_h

#import <UIKit/UIKit.h>
#include "MindSkinRootView.h"

@interface MindSkinRootView_impl_objc : NSObject{
    BOOL presented;
    
    UIViewController* skinrootcontroller;

};

+(MindSkinRootView_impl_objc*) sharedInstance;
-(void)presentMindSkinRootUI;
-(void)shutdown;

-(void)showMessage:(NSString*)msg;

-(UIResponder*)getUIViewRootController;

-(UIView*)view;

@end

#endif
