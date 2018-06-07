//
//  mindskinMessageViewController.h
//  QGroundControl
//
//  Created by ning roland on 7/21/16.
//
//

#import <AppKit/AppKit.h>

@interface Messenger : NSViewController <NSGestureRecognizerDelegate> {
    
    NSTimer* t1;
    
    NSFont *msgfont;
    NSColor *msgcolor;


}

@property (nonatomic, assign) NSString* message;
@property (nonatomic, assign) NSString* title;
@property (nonatomic, assign) NSImage* icon;
@property (nonatomic, assign) int type;
@property (nonatomic, assign) int displayType;
@property (nonatomic, assign) id completionHandler;
@property (nonatomic, assign) Messenger* nextmessenger;
@property (nonatomic, assign) NSTextView* textview;
@property (nonatomic, assign) NSFont *msgfont;
@property (nonatomic, assign) NSColor *msgcolor;

-(void)presentMessage:(id)completionDelegate;


@end

@interface mindskinMessageViewController : NSViewController <NSGestureRecognizerDelegate> {
    NSTextView* messageview;

    BOOL ispresented;
    
    
    NSTimer* t1;
    
    NSFont *msgfont;
    NSColor *msgcolor;
    
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
