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
    UISwipeGestureRecognizer* swipegesture;
    UIPanGestureRecognizer* pangesture;
    BOOL ispresented;
    
    NSString* history;
    
    NSTimer* t1;
}

+(mindskinMessageViewController*) sharedInstance;

-(void)clear;
//auto dismiss;
-(void)showMessage:(NSString*)msg;
-(void)showHistoryMessages:(int)max;
-(void)dismissMessageView;


@end
