//
//  MindSkinRootView_impl_objc.h
//  qgroundcontrol
//
//  Created by ning roland on 6/16/16.
//
//

#ifndef qgroundcontrol_MindSkinRootView_impl_objc_h
#define qgroundcontrol_MindSkinRootView_impl_objc_h

#import <AppKit/AppKit.h>
#include "MindSkinRootView.h"
#import "tagNodesViewController.h"

@interface MindSkinRootView_impl_objc : NSObject{
    BOOL presented;
    
    NSViewController* skinrootcontroller;
    tagNodesViewController* tagvc;

};

+(MindSkinRootView_impl_objc*) sharedInstance;
-(void)presentMindSkinRootUI;
-(void)showBLEConnectionsView;
-(void)hideBLEConnectionsView;

-(void)shutdown;

-(void)showMessage:(NSString*)msg;

-(NSResponder*)getUIViewRootController;

-(NSView*)view;

@end

#endif
