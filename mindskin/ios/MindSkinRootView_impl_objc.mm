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
    
};

MindSkinRootView_wrapper::MindSkinRootView_wrapper () {
    skinroot_objc = [MindSkinRootView_impl_objc sharedInstance];
}

MindSkinRootView_wrapper::~MindSkinRootView_wrapper () {
    
}

void MindSkinRootView_wrapper::presentMindSkinRootUI() {
    [skinroot_objc presentMindSkinRootUI];
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

-(void)presentMindSkinRootUI {
    UIViewController* rootcontroller = (UIViewController*)[self getUIViewRootController];
    
    //present Mindskin UI entry;
    UIViewController* tagnodesctlr = [[tagNodesViewController alloc] initWithNibName:@"TagNodesViewController" bundle:nil];
    //[tagnodesctlr.view setFrame:CGRectMake(00, 60, 200, 200)];
    //[rootcontroller.view setFrame:CGRectMake(00, 60, 200, 200)];
    //[rootcontroller.view addSubview:tagnodesctlr.view];

    [rootcontroller presentViewController:tagnodesctlr animated:YES completion:nil];
    
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


@end
