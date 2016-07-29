//
//  mindskinMessageViewController.h
//  QGroundControl
//
//  Created by ning roland on 7/21/16.
//
//

#import <UIKit/UIKit.h>

@interface Messenger : UIViewController <UIGestureRecognizerDelegate> {
    UITapGestureRecognizer* tapgesture;
    UISwipeGestureRecognizer* swipeupgesture;
    UISwipeGestureRecognizer* swipedowngesture;
    
    NSTimer* t1;
    
    UIFont *msgfont;
    UIColor *msgcolor;


}

@property (nonatomic, assign) NSString* message;
@property (nonatomic, assign) NSString* title;
@property (nonatomic, assign) UIImage* icon;
@property (nonatomic, assign) int type;
@property (nonatomic, assign) int displayType;
@property (nonatomic, assign) id completionHandler;
@property (nonatomic, assign) Messenger* nextmessenger;
@property (nonatomic, assign) UITextView* textview;
@property (nonatomic, assign) UIFont *msgfont;
@property (nonatomic, assign) UIColor *msgcolor;

-(void)presentMessage:(id)completionDelegate;


@end

@interface mindskinMessageViewController : UIViewController <UIGestureRecognizerDelegate> {
    UITextView* messageview;
    UITapGestureRecognizer* tapgesture;
    UISwipeGestureRecognizer* swipeupgesture;
    UISwipeGestureRecognizer* swipedowngesture;

    UIPanGestureRecognizer* pangesture;
    BOOL ispresented;
    
    
    NSTimer* t1;
    
    UIFont *msgfont;
    UIColor *msgcolor;
    
    dispatch_queue_t messengers_q;
    dispatch_semaphore_t messageSemaphore;
    
    NSMutableArray* messengers;
    
    
}

+(mindskinMessageViewController*) sharedInstance;

-(void)clear;
//auto dismiss;
-(void)showMessage:(NSString*)msg;
-(void)showHistoryMessages:(int)max;
-(void)nextMessenger;


@end
