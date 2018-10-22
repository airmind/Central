//
//  MindSkinRootView_impl_objc.m
//  qgroundcontrol
//
//  Created by ning roland on 6/16/16.
//
//

#import <Foundation/Foundation.h>

#import "tagNodesViewController.h"
#import "sideMenuViewController.h"
#include "MindSkinRootView.h"
#include "MindSkinRootView_impl_objc.h"
#include "qt2ioshelper.h"
#include "QGCApplication.h"
#include "ParameterLoadHelper.h"
#import "tagBLEScanningPanel.h"

#import "mindskinMessageViewController.h"

/// ///////////////////////////////////////////////
///     @brief MindSkinRootView_wrapper
///
///     @author

class MindSkinRootView_wrapper {
    
private:
    MindSkinRootView_impl_objc* skinroot_objc;
    
public:
    MindSkinRootView_wrapper();
    ~MindSkinRootView_wrapper();
    
    void presentMindSkinRootUI();
    void showBLEConnectionsView();
    void dismissBLEConnectionsView();

    void showMessage(const QString& msg);

    
};

MindSkinRootView_wrapper::MindSkinRootView_wrapper () {
    skinroot_objc = [MindSkinRootView_impl_objc sharedInstance];
}

MindSkinRootView_wrapper::~MindSkinRootView_wrapper () {
    
}

void MindSkinRootView_wrapper::presentMindSkinRootUI() {
    [skinroot_objc presentMindSkinRootUI];
}

void MindSkinRootView_wrapper::showBLEConnectionsView() {
    [skinroot_objc showBLEConnectionsView];
}

void MindSkinRootView_wrapper::dismissBLEConnectionsView() {
    [skinroot_objc dismissBLEConnectionsView];
}

void MindSkinRootView_wrapper::showMessage(const QString& msg) {
    [skinroot_objc showMessage:(qt2ioshelper::QString2NSString(&msg))];
}



/// ///////////////////////////////////////////////
///     @brief MindSkinRootView
///
///     @author Roland


MindSkinRootView::MindSkinRootView() {
    skinroot_wrapper = new MindSkinRootView_wrapper();
}


MindSkinRootView* MindSkinRootView::sharedInstance() {
    
    static MindSkinRootView* instance;
    
    if (!instance)
        instance = new MindSkinRootView;
    return instance;
}

void MindSkinRootView::launchMindskinUI(){
    skinroot_wrapper->presentMindSkinRootUI();
}

void MindSkinRootView::showBLEConnectionsView() {
    skinroot_wrapper->showBLEConnectionsView();
}

void MindSkinRootView::dismissBLEConnectionsView() {
    skinroot_wrapper->dismissBLEConnectionsView();
}

void MindSkinRootView::shutdown(){
    
}

void MindSkinRootView::showMessage(const QString& msg) {
    skinroot_wrapper->showMessage(msg);
}



/// ///////////////////////////////////////////////
///     @brief MindSkinRootView_impl_objc
///
///     @author


@implementation MindSkinRootView_impl_objc


+(MindSkinRootView_impl_objc*)sharedInstance{
    static MindSkinRootView_impl_objc* sharedInstance;
    
    @synchronized(self)
    {
        if (!sharedInstance) {
            sharedInstance = [[MindSkinRootView_impl_objc alloc] init];
        }
        
        return sharedInstance;
    }
    
}

-(UIView*)view {
    return skinrootcontroller.view;
}

-(void)presentMindSkinRootUI {
    UIViewController* rootcontroller = (UIViewController*)[self getUIViewRootController];
    
    //present Mindskin UI entry;
    
#ifdef __DRONETAG_BLE__
    //prepare BLE scanning view controller;
    //do nothing for the moment;

    /*
    UIViewController* tagnodesctlr = [[tagNodesViewController alloc] initWithNibName:@"TagNodesViewController" bundle:nil];
    skinrootcontroller = tagnodesctlr;
     

    [rootcontroller presentViewController:tagnodesctlr animated:YES completion:^{
        qgcApp()->_initSetting();
    }];*/
    skinrootcontroller = rootcontroller;

    qgcApp()->_initSetting();
     
#else
    
    tagNodesViewController* tgvc = [[tagNodesViewController alloc] initWithNibName:@"new" bundle:nil];
    CGRect rect = [racermainctlr.view frame];
    
    sideMenuViewController* sidemenunctlr = [[sideMenuViewController alloc] init];
    [sidemenunctlr.view setFrame:CGRectMake(rect.origin.x, rect.origin.y, 200, rect.size.height)];
    
    //UIViewController* racermainctlr = [[tagNodesViewController alloc] initWithNibName:@"RacerMainMenuViewController" bundle:nil];
    
    skinrootcontroller = racermainctlr;

    //add a splitview as container;
    UISplitViewController *splitViewController = [[UISplitViewController alloc] init];
    UINavigationController *masterNav = [[UINavigationController alloc] initWithRootViewController:sidemenunctlr];
    UINavigationController *detailNav = [[UINavigationController alloc] initWithRootViewController:racermainctlr];
    splitViewController.viewControllers = [NSArray arrayWithObjects:masterNav, detailNav, nil];
    splitViewController.delegate = racermainctlr;
    
    //enable swipe gesture to show/hide master in landscape mode;
    splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModePrimaryHidden;
    splitViewController.presentsWithGesture = YES;

    [rootcontroller presentViewController:splitViewController animated:YES completion:^{
        qgcApp()->_initSetting();
    }];
    
#endif
    
}


-(void)showBLEConnectionsView {
    tagBLEScanningPanel* scanpanel = [tagBLEScanningPanel sharedInstance];
    if (![scanpanel presented]) {
        NSLog(@"presenting scan panel...");
        UIViewController* rootcontroller = (UIViewController*)[self getUIViewRootController];
        UIView* rootview = rootcontroller.view;
        CGRect rootrect = [rootview frame];
        CGRect initrect = CGRectMake(rootrect.origin.x+rootrect.size.width, 60, rootrect.size.width/4, rootrect.size.height-60);
        CGRect destrect = CGRectMake(rootrect.origin.x+3*rootrect.size.width/4, 60, rootrect.size.width/4, rootrect.size.height-60);
        [scanpanel initScanningPanel:initrect];
        [rootview addSubview:scanpanel.view];
        [scanpanel.view setFrame:initrect];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [scanpanel.view setFrame:destrect];
            
            //animate view in;
            /*
             [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
             context.duration = 0.5;
             [awin setFrame:destrect display:YES animate:NO];
             }
             completionHandler:^{
             }];
             
             */
        });
    }
    
}

-(void)dismissBLEConnectionsView {
    tagBLEScanningPanel* scanpanel = [tagBLEScanningPanel sharedInstance];
    if ([scanpanel presented]) {
        UIViewController* rootcontroller = (UIViewController*)[self getUIViewRootController];

        CGRect rootrect = [rootcontroller.view frame];
        CGRect destrect = CGRectMake(rootrect.origin.x+rootrect.size.width, 60, rootrect.size.width/4, rootrect.size.height-60);
        
        //animate view out;
        dispatch_async(dispatch_get_main_queue(), ^{
            [scanpanel.view setFrame:destrect];
            /*
             [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
             context.duration = 0.5;
             [tagvc.view setFrame:destrect];
             }
             completionHandler:^{
             }];
             */
        });
        
        [scanpanel.view removeFromSuperview];
        [scanpanel release];
        
    }
}

-(UIResponder*)getUIViewRootController {
    UIResponder* responder;
    
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(window in windows) {
            if (window.windowLevel == UIWindowLevelNormal) {
                break;
            }
        }
    }
    
    for (UIView *subView in [window subviews])
    {
        UIResponder *tresponder = [subView nextResponder];
        if([tresponder isKindOfClass:[UIViewController class]]) {
            responder= tresponder;
            break;
        }
    }
    
    return responder;

}


-(void)showMessage:(NSString*)msg {
    [[mindskinMessageViewController sharedInstance] showMessage:msg];
}


@end
