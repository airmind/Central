//
//  MindSkinRootView_impl_objc.m
//  qgroundcontrol
//
//  Created by ning roland on 6/16/16.
//
//

#import <Foundation/Foundation.h>

#import "tagNodesViewController.h"

#include "MindSkinRootView.h"
#include "MindSkinRootView_impl_objc.h"
#include "qt2ioshelper.h"
#include "QGCApplication.h"

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
    
#ifdef __dronetag__
    UIViewController* tagnodesctlr = [[tagNodesViewController alloc] initWithNibName:@"TagNodesViewController" bundle:nil];
    skinrootcontroller = tagnodesctlr;

    [rootcontroller presentViewController:tagnodesctlr animated:YES completion:^{
        qgcApp()->_initSetting();
    }];
#else
    //todo: try to get a link to see if its racer or mindpx
    //launch racer by default;
    
    UIViewController* racermainctlr = [[tagNodesViewController alloc] initWithNibName:@"TagNodesViewController" bundle:nil];

    //UIViewController* racermainctlr = [[tagNodesViewController alloc] initWithNibName:@"RacerMainMenuViewController" bundle:nil];
    skinrootcontroller = racermainctlr;
    
    [rootcontroller presentViewController:racermainctlr animated:YES completion:^{
        qgcApp()->_initSetting();
    }];
#endif
    
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
