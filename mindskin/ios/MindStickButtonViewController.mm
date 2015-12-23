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
    
    [buttonController.view setFrame:CGRectMake(viewFrame.origin.x+viewFrame.size.height, 60, 60, viewFrame.size.width)];
    //[popoverctrol.view setFrame:CGRectMake(0, 0, 100, 100)];
    
    //[responder presentViewController:popoverctrol animated:YES completion:^{
    
    
    // }];
    
    [((UIViewController*)responder).view addSubview:buttonController.view];
    
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [buttonController.view setFrame:CGRectMake(viewFrame.origin.x+viewFrame.size.height-200, 60, 200, viewFrame.size.width)];
                         
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
    
    CGRect btnrect = CGRectMake(400, 300, 48, 48);
    statusButton = [[UIButton alloc] initWithFrame:btnrect];
    statusButton.tag=1200;
    UIImage *buttonImageNormal= [UIImage imageNamed:@"refresh@2x.png"];
    [statusButton setBackgroundImage:buttonImageNormal	forState:UIControlStateNormal];
    UIImage *buttonImageHighlight = [UIImage imageNamed:@"refreshgrey@2x.png"];
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
