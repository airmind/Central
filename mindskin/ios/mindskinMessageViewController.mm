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


@interface Messenger ()

@end

@implementation Messenger
@synthesize message, type, title, displayType, completionHandler, icon, textview;

- (void)loadView {
    //create and add view;
    //override view with UIVisualEffectView;
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView* blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurView.alpha = 1;
    //blurView.frame = self.view.frame;
    
    self.view = blurView;
    
    self.view.frame = CGRectZero;
    
    //add text view;
    CGRect msgrect = CGRectZero;
    
    if (textview == nil) {
        
        textview = [[UITextView alloc] initWithFrame:msgrect];
        //textview.font = msgfont;
        //textview.textColor = msgcolor;
        textview.backgroundColor = [UIColor clearColor];
        [self.view addSubview:textview];
        
    }
    else {
        //adjust view height to fit text message into.
        textview.frame = msgrect;
        
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
    
    //pangesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    //[self.view addGestureRecognizer:pangesture];
    
    
}

-(void)presentMessage:(id)completionDelegate {
    //calc view size;
    completionHandler = completionDelegate;
    
    UIView* parentview = [[MindSkinRootView_impl_objc sharedInstance] view];
    CGSize screenSize = [[UIScreen mainScreen] bounds].size ;
    
    int textviewwidth = screenSize.width - 40; /*for landscape layout*/
        
    //commit to main thread;
    NSLog(@"Dispatching to main_q\n");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
    
        NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                              msgfont, NSFontAttributeName,
                                              msgcolor, NSForegroundColorAttributeName,
                                              nil];
        
        
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:message attributes:attributesDictionary];
        //messageview.attributedText = attributedString; //this is the key!
        
        
        CGSize constraint = CGSizeMake(textviewwidth, CGFLOAT_MAX);
        
        //calced view rect for message.
        CGRect msgrect = [attributedString boundingRectWithSize:constraint options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
        
        //do padding;
        
        msgrect.size.height = msgrect.size.height + 20;
        
        //place in invisible area first;
        CGRect viewframe = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y-(msgrect.size.height + 40),
                                      screenSize.width, msgrect.size.height + 40);
        
        
        
        self.view.frame = viewframe;
        
        //set text view rect;
        textview.frame = CGRectMake(20, 20,
                                       screenSize.width-40, msgrect.size.height);
        textview.text = message;

    
        [attributedString release];
        
    
        [parentview addSubview:self.view];
    
        //animate view in;
        CGRect normalrect = viewframe;
        normalrect.origin.y = normalrect.origin.y + (msgrect.size.height + 40);
    

        [UIView animateWithDuration:0.5
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self.view setFrame:normalrect];
                             
                         }
                         completion:^(BOOL finished){
                             if (finished) {
                                 //[messageview scrollRangeToVisible:NSMakeRange([msg length], 0)];
                                 
                                 NSLog(@"%@; present ended\n", textview.text);
                                 if (t1 == nil) {
                                     
                                     
                                     t1 = [NSTimer scheduledTimerWithTimeInterval:5.0f
                                                                           target:self
                                                                         selector:@selector(dismissMessageView)
                                                                         userInfo:nil
                                                                          repeats:NO];
                                 }

                                 
                             }
                             
                         }];
    });

}

-(void)dismissMessageView{
    //animate out;
    @synchronized(self) {
        
        CGRect hiddenrect = self.view.frame;
        hiddenrect.origin.y = hiddenrect.origin.y - (textview.frame.size.height + 40);
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.5
                                  delay:0
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 [self.view setFrame:hiddenrect];
                                 
                             }
                             completion:^(BOOL finished){
                                 if (finished) {
                                     [self.view removeFromSuperview];
                                     [textview release];
                                     [self.view release];
                                     
                                     [(mindskinMessageViewController*)completionHandler nextMessenger];
                                     
                                     
                                 }
                                 
                             }];
        });
        
        
        
    }
}


-(void) handleSwipeGestureUp:(UIGestureRecognizer*)recognizer {
    [self dismissMessageView];
}


@end


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
    
    msgfont = [UIFont fontWithName:@"HelveticaNeue" size:14.0];
    msgcolor = [UIColor blackColor];
    
    messengers = [[NSMutableArray alloc] initWithCapacity:0];

    
    t1 = nil;
    messengers_q = dispatch_queue_create("messengersQ",  DISPATCH_QUEUE_SERIAL);
    //dispatch_get_main_queue();
    messageSemaphore = dispatch_semaphore_create(1);

    return self;
}

- (void)loadView {
    //create and add view;
    //override view with UIVisualEffectView;
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView* blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurView.alpha = 1;
    //blurView.frame = self.view.frame;
    
    self.view = blurView;
    
    self.view.frame = CGRectZero;

    //add text view;
    CGRect msgrect = CGRectZero;

    if (messageview == nil) {
        
        messageview = [[UITextView alloc] initWithFrame:msgrect];
        messageview.font = msgfont;
        messageview.textColor = msgcolor;
        messageview.backgroundColor = [UIColor clearColor];
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
        //create a messenger object and return;
    NSLog(@"Dispatching to message_q\n");
   
        //dispatch to message_q to calc view size;
        dispatch_async(messengers_q, ^{
            Messenger* amsger = [[Messenger alloc] init];
            amsger.message = [[NSString stringWithString:msg] copy];
            amsger.msgfont = msgfont;
            amsger.msgcolor = msgcolor;
            
            [messengers addObject:amsger];
            
            dispatch_semaphore_wait(messageSemaphore, DISPATCH_TIME_FOREVER);
            
            [amsger presentMessage:self];
 
        
            
            
        
        });
        
        
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
    
 
}

-(void)nextMessenger{
    
    dispatch_semaphore_signal(messageSemaphore);
                                 
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
