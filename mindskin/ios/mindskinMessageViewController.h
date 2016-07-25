//
//  mindskinMessageViewController.h
//  QGroundControl
//
//  Created by ning roland on 7/21/16.
//
//

#import <UIKit/UIKit.h>

@interface mindskinMessageViewController : UIViewController <UIGestureRecognizerDelegate> {
    UITextView* messageview;
    UITapGestureRecognizer* tapgesture;
    UISwipeGestureRecognizer* swipeupgesture;
    UISwipeGestureRecognizer* swipedowngesture;

    UIPanGestureRecognizer* pangesture;
    BOOL ispresented;
    
    NSString* history;
    
    NSTimer* t1;
    
    UIFont *msgfont;
    UIColor *msgcolor;
    
    dispatch_queue_t messageview_q;
    dispatch_semaphore_t messageSemaphore;

    
    
}

+(mindskinMessageViewController*) sharedInstance;

-(void)clear;
//auto dismiss;
-(void)showMessage:(NSString*)msg;
-(void)showHistoryMessages:(int)max;
-(void)dismissMessageView;


@end
