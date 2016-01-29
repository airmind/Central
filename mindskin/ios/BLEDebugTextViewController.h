//
//  BLEDebugTextViewController.h
//  qgroundcontrol
//
//  Created by ning roland on 1/29/16.
//
//

#import <UIKit/UIKit.h>

@interface BLEDebugTextViewController : UIViewController {
    UITextView* textview;
}

-(void)addLine:(NSString*)msg;
-(void)clearview;

@end
