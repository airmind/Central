//
//  mindskinMessageViewController.m
//  QGroundControl
//
//  Created by ning roland on 7/21/16.
//
//

#import "mindskinMessageViewController.h"
#import "MindSkinRootView_impl_objc.h"
#import <CoreText/CoreText.h>

@interface mindskinMessageViewController ()

@end

@implementation mindskinMessageViewController


+ (mindskinMessageViewController*) sharedInstance {
    static mindskinMessageViewController* sharedInstance;
    
    @synchronized(self)
    {
        if (!sharedInstance) {
            sharedInstance = [[mindskinMessageViewController alloc] init];
        }
        
        return sharedInstance;
    }

}

- (mindskinMessageViewController*)init {
    self = [super init];
    ispresented = NO;
    
    msgfont = [UIFont fontWithName:@"HelveticaNeue" size:11.0];
    msgcolor = [UIColor blackColor];

    if (history==nil) {
        history = @"";
    }
    
    t1 = nil;
    messageview_q = dispatch_get_main_queue();
    messageSemaphore = dispatch_semaphore_create(1);

    return self;
}

- (void)loadView {
    
    //add text view;
    CGRect msgrect = CGRectMake(self.view.frame.origin.x+10, self.view.frame.origin.y+10,
                                self.view.frame.size.width-20, self.view.frame.size.height-20);

    if (messageview == nil) {
        
        messageview = [[UITextView alloc] initWithFrame:msgrect];
        
        [self.view addSubview:messageview];
        
    }
    else {
        //adjust view height to fit text message into.
        messageview.frame = msgrect;
        
    }
    
    
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //add gesture recognizers;
    tapgesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self.view addGestureRecognizer:tapgesture];

    swipeupgesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGestureUp:)];
    [self.view addGestureRecognizer:swipeupgesture];
    swipeupgesture.direction = UISwipeGestureRecognizerDirectionUp;

    swipedowngesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGestureDown:)];
    [self.view addGestureRecognizer:swipedowngesture];
    swipedowngesture.direction = UISwipeGestureRecognizerDirectionDown;

    pangesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self.view addGestureRecognizer:pangesture];

    
}


-(void)clear {
    
}

//auto dismiss;
-(void)showMessage:(NSString*)msg {
    @synchronized(self) {
        //mulitple access;
        
        if (!ispresented) {
            UIView* parentview = [[MindSkinRootView_impl_objc sharedInstance] view];
            
            dispatch_async(messageview_q, ^{
                dispatch_semaphore_wait(messageSemaphore, DISPATCH_TIME_FOREVER);
           
                //present view first;
                ispresented = YES;
            
                //calc correct message view size;

                int textviewwidth = self.view.frame.size.width - 40;
                
                
            
                NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                      msgfont, NSFontAttributeName,
                                                      msgcolor, NSForegroundColorAttributeName,
                                                      nil];
                
                
                NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:msg attributes:attributesDictionary];
                messageview.attributedText = attributedString; //this is the key!

                 
                CGSize constraint = CGSizeMake(textviewwidth, CGFLOAT_MAX);
                
                //calced view rect for message.
                CGRect msgrect = [attributedString boundingRectWithSize:constraint options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
                
                
                //messageview = [[UITextView alloc] initWithFrame:msgrect];
                //in invisible area first;
                CGRect viewframe = CGRectMake(parentview.frame.origin.x, parentview.frame.origin.y-(msgrect.size.height + 40),
                                              parentview.frame.size.width, msgrect.size.height + 40);
                
                
                //create and add view;
                //override view with UIVisualEffectView;
                UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
                UIVisualEffectView* blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
                blurView.alpha = 1;
                blurView.frame = self.view.frame;
            
                self.view = blurView;

                self.view.frame = viewframe;
                
            
            
                [parentview addSubView:self.view];
            
                if (t1 == nil) {
                
            
                    t1 = [NSTimer scheduledTimerWithTimeInterval:3.0f
                                target:self
                                selector:@selector(dismissMessageView)
                                userInfo:nil
                                repeats:NO];
                }
                
                
                //animate view in;
                CGRect normalrect = viewframe;
                normalrect.origin.y = normalrect.origin.y + (msgrect.size.height + 40);
                
                [UIView animateWithDuration:0.2
                                      delay:0
                                    options:UIViewAnimationOptionBeginFromCurrentState
                                 animations:^{
                                     [self.view setFrame:normalrect];
                                     
                                 }
                                 completion:^(BOOL finished){
                                     if (finished) {
                                         
                                     }
                                     
                                 }];

                
            });
            
            
        }
        else {
                //restart the timer;
            if ([t1 isValid]) {
                    [t1 invalidate];
                    t1 = [NSTimer scheduledTimerWithTimeInterval:3.0f
                                                      target:self
                                                    selector:@selector(dismissMessageView)
                                                    userInfo:nil
                                                     repeats:NO];
                
            }
            //append message and scroll to latest;
            NSString* str = messageview.text;
            str = [str stringByAppendingString:msg];
            messageview.text = str;
            [messageview scrollRangeToVisible:NSMakeRange([msg length], 0)];
            messageview.text = msg;

            
        }
        
        history = [history stringByAppendingString:msg];
        
    }
                           

}

                 
                 
-(void)showHistoryMessages:(int)max {
    
    //stop timer;
    [t1 invalidate];
    
    //take over full screen;
    UIView* parentview = [[MindSkinRootView_impl_objc sharedInstance] view];
    
    CGRect fullrect = parentview.frame;
    
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.view setFrame:fullrect];
                         
                     }
                     completion:^(BOOL finished){
                         if (finished) {
                             
                         }
                         
                     }];
    
    messageview.text = history;
    [messageview scrollRangeToVisible:NSMakeRange([history length], 0)];

}

-(void)dismissMessageView{
    //animate out;
    @synchronized(self) {
        //mulitple access;
        if (!ispresented) {
            return;
        }
        
        ispresented = NO;
        CGRect hiddenrect = self.view.frame;
        hiddenrect.origin.y = hiddenrect.origin.y - (messageview.frame.size.height + 40);
        
        [UIView animateWithDuration:0.2
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self.view setFrame:hiddenrect];
                             
                         }
                         completion:^(BOOL finished){
                             if (finished) {
                                 
                             }
                             
                         }];

        [self.view removeFromSuperview];
        [messageview release];
        [self.view release];

        dispatch_semaphore_signal(messageSemaphore);

        
    }
}



- (CGSize)frameSizeForAttributedString:(NSAttributedString *)attributedString
{
                    CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString((CFAttributedStringRef)attributedString);
                    CGFloat width = 100;//YOUR_FIXED_WIDTH;
                    
                    CFIndex offset = 0, length;
                    CGFloat y = 0;
                    do {
                        length = CTTypesetterSuggestLineBreak(typesetter, offset, width);
                        CTLineRef line = CTTypesetterCreateLine(typesetter, CFRangeMake(offset, length));
                        
                        CGFloat ascent, descent, leading;
                        CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
                        
                        CFRelease(line);
                        
                        offset += length;
                        y += ascent + descent + leading;
                    } while (offset < [attributedString length]);
                    
                    CFRelease(typesetter);
                    
                    return CGSizeMake(width, ceil(y));
}



-(void) handleSwipeGestureUp:(UIGestureRecognizer*)recognizer {
    [self dismissMessageView];
}


-(void) handleSwipeGestureDown:(UIGestureRecognizer*)recognizer {
    [self showHistoryMessages:-1];
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
