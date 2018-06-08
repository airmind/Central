//
//  MindSkinRootView_impl_objc.m
//  qgroundcontrol
//
//  Created by ning roland on 6/16/16.
//
//

#import <Foundation/Foundation.h>

#include "MindSkinRootView.h"
#include "MindSkinRootView_impl_objc.h"
#include "qt2ioshelper.h"
#include "QGCApplication.h"
#include "ParameterLoadHelper.h"
#import "BTSerialLink_objc.h"
#include "mindskinMessageViewController.h"
#import "tagBLEScanningPanel.h"

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

-(MindSkinRootView_impl_objc*)init {
    self = [super init];
    return self;
}

-(NSView*)view {
    return skinrootcontroller.view;
}

-(void)presentMindSkinRootUI {
#ifdef __ios__
    UIViewController* rootcontroller = (UIViewController*)[self getUIViewRootController];
    
    //present Mindskin UI entry;
    
#ifdef __DRONETAG_BLE__
    UIViewController* tagnodesctlr = [[tagNodesViewController alloc] initWithNibName:@"TagNodesViewController" bundle:nil];
    skinrootcontroller = tagnodesctlr;

    [rootcontroller presentViewController:tagnodesctlr animated:YES completion:^{
        qgcApp()->_initSetting();
    }];
#else
    //todo: try to get a link to see if its racer or mindpx
    //launch racer by default;
    tagNodesViewController* racermainctlr = [[tagNodesViewController alloc] initWithNibName:@"TagNodesViewController" bundle:nil];
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
#endif //0
    
}

-(void)showBLEConnectionsView {
    tagBLEScanningPanel* scanpanel = [tagBLEScanningPanel sharedInstance];
    if (![scanpanel presented]) {
        NSWindow* rootwin = (NSWindow*)[self getNSViewRootController];
        
        NSView* rootview = rootwin.contentView;
        NSRect rootrect = [rootview frame];
        NSRect initrect = NSMakeRect(rootrect.origin.x+rootrect.size.width, 60, rootrect.size.width/4, rootrect.size.height-60);
        NSRect destrect = NSMakeRect(rootrect.origin.x+3*rootrect.size.width/4, 60, rootrect.size.width/4, rootrect.size.height-60);

        [scanpanel initScanningPanel:initrect];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [rootwin addChildWindow:scanpanel ordered:NSWindowAbove];
            [scanpanel setFrame:destrect display:NO animate:YES];

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
        NSWindow* rootwin = (NSWindow*)[self getNSViewRootController];

        NSRect rootrect = [rootwin.contentView frame];
        NSRect destrect = NSMakeRect(rootrect.origin.x+rootrect.size.width, 60, rootrect.size.width/4, rootrect.size.height-60);

        //animate view out;
        dispatch_async(dispatch_get_main_queue(), ^{
            [scanpanel setFrame:destrect display:NO animate:YES];
/*
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                context.duration = 0.5;
                [tagvc.view setFrame:destrect];
            }
                            completionHandler:^{
                             }];
  */
        });

        [rootwin removeChildWindow:scanpanel];
        //[scanpanel releaseScanningPanel];

    }
}


-(NSResponder*)getNSViewRootController {
    
    NSWindow *window = (NSWindow *)[[NSApplication sharedApplication] mainWindow];
    if (window.level != NSNormalWindowLevel) {
        NSArray *windows = [[NSApplication sharedApplication] windows];
        for(window in windows) {
            if (window.level == NSNormalWindowLevel) {
                break;
            }
        }
    }
/*
    NSResponder* responder = window.windowController;
    for (NSView *subView in [window.contentView subviews])
    {
        NSResponder *tresponder = [subView nextResponder];
        if([tresponder isKindOfClass:[NSViewController class]]) {
            responder= tresponder;
            break;
        }
    }
 */
    
    return window;

}


-(void)showMessage:(NSString*)msg {
    [[mindskinMessageViewController sharedInstance] showMessage:msg];
}


@end
