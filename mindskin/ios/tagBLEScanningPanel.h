//
//  tagBLEScanningPanel.h
//  MindSkin
//
//  Created by ning roland on 6/7/18.
//

#import <UIKit/UIKit.h>
#import "tagNodesViewController.h"

@interface tagBLEScanningPanel : UIViewController {
    BOOL presented;
    tagNodesViewController* tagvc;

}

+ (tagBLEScanningPanel*) sharedInstance;
-(BOOL)presented;
-(void)initScanningPanel:(CGRect)rect;
-(void)releaseScanningPanel;

@end
