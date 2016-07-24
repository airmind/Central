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

    swipegesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
    [self.view addGestureRecognizer:swipegesture];

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
            
            //calc message text to determine view size;
            NSString* str = messageview.text;
            if (str==nil) {
                str = @"";
            }
            str = [str stringByAppendingString:msg];

            //messageview.text = str;
            
            
            //present view first;
            ispresented = YES;
            
            //calc correct message view size;
                int textviewwidth = self.view.frame.size.width - 40;
                
                
                
                UIFont *font = [UIFont fontWithName:@"HelveticaNeue" size:11.0];
                UIColor *color = [UIColor blackColor];
                
                NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                      font, NSFontAttributeName,
                                                      color, NSForegroundColorAttributeName,
                                                      nil];
                
                
                NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:str attributes:attributesDictionary];
                messageview.attributedText = attributedString; //this is the key!

                 
                CGSize constraint = CGSizeMake(textviewwidth, CGFLOAT_MAX);
                
                //calced view rect for message.
                CGRect msgrect = [attributedString boundingRectWithSize:constraint options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
                
                
                //messageview = [[UITextView alloc] initWithFrame:msgrect];
                CGRect viewframe = CGRectMake(parentview.frame.origin.x, parentview.frame.origin.y,
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
            
            //animate view in;
            
        }
        else {
            //append message and scroll to latest;
            NSString* str = self.textView.text;
            str = [str stringByAppendingString:@"\n MsgId: "];
            str = [str stringByAppendingString: [[NSNumber numberWithInt:message.msgid] stringValue]];
            
            str = [str stringByAppendingString:@" SeqId: "];
            str = [str stringByAppendingString: [[NSNumber numberWithInt:message.seq] stringValue]];
            
            for (unsigned int i = 0; i < minfo.num_fields; ++i)
            {
                //emitFieldValue(&message, i, time);
                //NSString* str = self.textView.text;
                str = [str stringByAppendingString:@"\n"];
                mavlink_field_info_t finfo = minfo.fields[i];
                if (finfo.name==NULL) {
                    str = [str stringByAppendingString:@""];
                    
                }
                else {
                    str = [str stringByAppendingString:[NSString stringWithCString:finfo.name encoding:NSASCIIStringEncoding]];
                }
                str = [str stringByAppendingString:@"\n"];
                
                if (finfo.print_format==NULL) {
                    str = [str stringByAppendingString:@""];
                    
                }
                else {
                    str = [str stringByAppendingString:[NSString stringWithCString:finfo.print_format encoding:NSASCIIStringEncoding]];
                }
                
                str = [str stringByAppendingString:@"\n"];
                NSString* arraylen = [[NSNumber numberWithInt:finfo.array_length] stringValue];
                str = [str stringByAppendingString:arraylen];
                
                
                
            }
            self.textView.text = str;
            [self.textView scrollRangeToVisible:NSMakeRange([str length], 0)];

            
        }
    }

}

                 
                 
-(void)showHistoryMessages:(int)max {
    
}

-(void)dismissMessageView{
    
}

                 
                 
- (CGSize)frameSizeForAttributedString:(NSAttributedString *)attributedString
{
                    CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString((CFAttributedStringRef)attributedString);
                    CGFloat width = YOUR_FIXED_WIDTH;
                    
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
