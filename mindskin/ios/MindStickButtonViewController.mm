//
//  MindStickButtonViewController.m
//  qgroundcontrol
//
//  Created by ning roland on 12/22/15.
//
//

#import "MindStickButtonViewController.h"

#include "MindStickButton.h"



/**
 MindStickButtonWrapper impl
 **/
class MindStickButtonWrapper {

private:
    MindStickButtonViewController* buttonController;
    
public:
    
    MindStickButtonWrapper();
    ~MindStickButtonWrapper();
    
    void showStatusButton();
    void removeStatusButton();
    void enable();
    void disable();
    void linkRSSIUpdated(void* list);

};


MindStickButtonWrapper::MindStickButtonWrapper() {
    buttonController = [[MindStickButtonViewController alloc] init];
}

MindStickButtonWrapper::~MindStickButtonWrapper () {
    if (buttonController!=nil) {
        [buttonController release];
    }
}

void MindStickButtonWrapper::showStatusButton() {
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
    
    
    CGRect viewFrame = ((UIViewController*)responder).view.frame;
    
    //76@2x;
    [buttonController.view setFrame:CGRectMake(viewFrame.origin.x+viewFrame.size.height, viewFrame.origin.y+viewFrame.size.width-152, 152, 152)];
    //[popoverctrol.view setFrame:CGRectMake(0, 0, 100, 100)];
    
    //[responder presentViewController:popoverctrol animated:YES completion:^{
    
    
    // }];
    
    [((UIViewController*)responder).view addSubview:buttonController.view];
    
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [buttonController.view setFrame:CGRectMake(viewFrame.origin.x+viewFrame.size.height-162, viewFrame.origin.y+viewFrame.size.width-152, 152, 152)];
                         
                     }
                     completion:^(BOOL finished){
                         if (finished) {
                             
                         }
                         
                     }];
    

}

void MindStickButtonWrapper::removeStatusButton() {
    [buttonController.view removeFromSuperview];
    //[buttonController release];
    
}

void MindStickButtonWrapper::enable() {
    [buttonController enable];
}

void MindStickButtonWrapper::disable() {
    [buttonController disable];
}

void MindStickButtonWrapper::linkRSSIUpdated(void* list) {
    [buttonController updateLinkRSSI:(__bridge BLE_Peripheral_Links*)list];
}


/**
 MindStickButton impl;
 **/
MindStickButton::MindStickButton() {
    mswrapper = new MindStickButtonWrapper();
}

MindStickButton::~MindStickButton() {
    if (mswrapper != NULL) {
        delete mswrapper;
    }
}

void MindStickButton::showButton() {
    mswrapper -> showStatusButton();
}

void MindStickButton::removeButton() {
    mswrapper -> removeStatusButton();
}

void MindStickButton::enable() {
    mswrapper -> enable();
}

void MindStickButton::disable() {
    mswrapper -> disable();
}

void MindStickButton::updateStatus() {
    
}

void MindStickButton::linkRSSIUpdated(void* list) {
    mswrapper->linkRSSIUpdated(list);
}

/**
 MindStickButtonViewController - Objective - C implementation;
 **/

@interface MindStickButtonViewController ()

@end

@implementation MindStickButtonViewController


-(MindStickButtonViewController*)init {
    [super init];
    if (self) {
        statusButton = nil;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (statusButton != nil) {
        return;
    }
    
    CGRect btnrect = CGRectMake(0, 0, 152, 152);
    statusButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [statusButton setFrame:btnrect];
    statusButton.tag=1200;
    UIImage *buttonImageNormal= [UIImage imageNamed:@"AppIcon76x76@2x~ipad.png"];
    [statusButton setBackgroundImage:buttonImageNormal	forState:UIControlStateNormal];
    UIImage *buttonImageHighlight = [UIImage imageNamed:@"AppIcon76x76@2x~ipad.png"];
    [statusButton setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
    //[mindstickiconbutton addTarget:self action:@selector(resetButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:statusButton];

}

/*
-(void)showStatusButton {
    
}

-(void)removeStatusButton {
    
}
*/

-(void)enable {
    statusButton.enabled = YES;
}

-(void)disable {
    statusButton.enabled = NO;
}


-(void)updateLinkRSSI:(BLE_Peripheral_Links*) list {
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc {
    if (statusButton!=nil) {
        [statusButton release];
        statusButton = nil;
    }
    
    [super dealloc];
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
