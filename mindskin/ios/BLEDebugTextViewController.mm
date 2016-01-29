//
//  BLEDebugTextViewController.m
//  qgroundcontrol
//
//  Created by ning roland on 1/29/16.
//
//

#import "BLEDebugTextViewController.h"
#include "BLEDebugTextView.h"
#include "qt2ioshelper.h"

/**
 Wrapper class;
 **/
class BLEDebugTextViewWrapper {
    private:
        BLEDebugTextViewController* debugviewcontroller;
    
    public:
        BLEDebugTextViewWrapper();
        ~BLEDebugTextViewWrapper();
    
        void addline(QString & msg);
        void clearview();

        void presentPopover();
        void dismissPopover();
        //bool isPresented();

};


BLEDebugTextViewWrapper::BLEDebugTextViewWrapper() {
    
}

BLEDebugTextViewWrapper::~BLEDebugTextViewWrapper() {

}

void BLEDebugTextViewWrapper::addline(QString & msg) {
    NSString* message = qt2ioshelper::QString2NSString(&msg);
    [debugviewcontroller addLine:message];
}

void BLEDebugTextViewWrapper::clearview() {
    [debugviewcontroller clearview];
}

void BLEDebugTextViewWrapper::presentPopover() {
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
    
    
    
    debugviewcontroller = [[BLEDebugTextViewController alloc] init];
    CGRect viewFrame = ((UIViewController*)responder).view.frame;
    
    [debugviewcontroller.view setFrame:CGRectMake(viewFrame.origin.x+viewFrame.size.height, 60, 200, viewFrame.size.width)];
    //[popoverctrol.view setFrame:CGRectMake(0, 0, 100, 100)];
    
    //[responder presentViewController:popoverctrol animated:YES completion:^{
    
    
    // }];
    
    [((UIViewController*)responder).view addSubview:debugviewcontroller.view];
    
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [debugviewcontroller.view setFrame:CGRectMake(viewFrame.origin.x+viewFrame.size.height-200, 60, 200, viewFrame.size.width)];
                         
                     }
                     completion:^(BOOL finished){
                         if (finished) {
                             
                         }
                         
                     }];
    
    
    //return nil;

}

void BLEDebugTextViewWrapper::dismissPopover() {
    [debugviewcontroller dismissPopoverView];

}



BLEDebugTextView::BLEDebugTextView() {
    this->debugwrapper = new BLEDebugTextViewWrapper();
    
}

BLEDebugTextView::~BLEDebugTextView() {
    delete this->debugwrapper;
}

void BLEDebugTextView::presentDebugView() {
    if (presented==true) {
        return;
    }
    debugwrapper->presentPopover();
    presented = true;
}

void BLEDebugTextView::dismissDebugView() {
    if (presented==false) {
        return;
    }
    debugwrapper->dismissPopover();
    presented = false;
}

bool BLEDebugTextView::isPresented() {
    return presented;
}


@interface BLEDebugTextViewController ()

@end

@implementation BLEDebugTextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (!textview) {
        textview = [[UITextView alloc] init];
    }
    [textview setFrame:[self.view frame]];
    textview.layoutManager.allowsNonContiguousLayout = NO;
    
    [self.view addSubview:textview];
    
}

-(void)dismissPopoverView {
    //dismiss this popover;
    CGRect viewFrame = [self.view frame];
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.view setFrame:CGRectMake(viewFrame.origin.x+200, 60, 200, viewFrame.size.width)];
                         
                     }
                     completion:^(BOOL finished){
                         if (finished) {
                             [ self.view removeFromSuperview];
                             //presented=NO;
                         }
                         
                     }];
    
}

-(void)addLine:(NSString*)msg {
    NSString* str = textview.text;
    str = [str stringByAppendingString:@"\n"];
    str = [str stringByAppendingString: msg];
    textview.text = str;


}

-(void)clearview {
    textview.text = nil;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
