//
//  tagBLEScanningPanel.m
//  MindSkin
//
//  Created by ning roland on 6/7/18.
//

#import "tagBLEScanningPanel.h"
#import "BTSerialLink_objc.h"

@implementation tagBLEScanningPanel

+ (tagBLEScanningPanel*) sharedInstance {
    static tagBLEScanningPanel* sharedInstance;
    
    @synchronized(self)
    {
        if (!sharedInstance) {
            sharedInstance = [[tagBLEScanningPanel alloc] init];
        }
        
        return sharedInstance;
    }
    
}

- (tagBLEScanningPanel*) init {
    self = [super init];
    presented = NO;
    
    self.floatingPanel = YES;
    [self setStyleMask:NSWindowStyleMaskBorderless|NSWindowStyleMaskResizable];
    
    return self;
    
}

-(BOOL)presented {
    return presented;
}

-(void)initScanningPanel:(NSRect)rect {
    presented = YES;
    
    NSVisualEffectView* blurView = [[NSVisualEffectView alloc] initWithFrame:rect];
    self.contentView = blurView;
    [self.contentView setWantsLayer:YES];
    [self.contentView setState:NSVisualEffectStateActive];
    [self.contentView setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
    [self.contentView setMaterial:NSVisualEffectMaterialDark];
    
    tagvc = [[tagNodesViewController alloc] initWithNibName:@"newview" bundle:[NSBundle mainBundle]];
    //[tagvc.view setFrame:rect];
    [[BLEHelper_objc sharedInstance] setCallbackDelegate:tagvc];
    [self.contentView addSubview:tagvc.view];
    
}

-(void)releaseScanningPanel {
    [tagvc.view removeFromSuperview:self.contentView];
    [tagvc release];
    presented = NO;
}
@end
