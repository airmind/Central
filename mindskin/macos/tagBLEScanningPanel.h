//
//  tagBLEScanningPanel.h
//  MindSkin
//
//  Created by ning roland on 6/7/18.
//

#import <Cocoa/Cocoa.h>
#import "tagNodesViewController.h"

@interface tagBLEScanningPanel : NSPanel {
    BOOL presented;
    tagNodesViewController* tagvc;

}


+ (tagBLEScanningPanel*) sharedInstance;
-(BOOL)presented;
-(void)initScanningPanel:(NSRect)rect;
-(void)releaseScanningPanel;

@end
