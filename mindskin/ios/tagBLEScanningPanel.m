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
    
    //self.floatingPanel = YES;
    //[self setStyleMask:UIWindowStyleMaskBorderless|UIWindowStyleMaskResizable];
    return self;
    
}

-(BOOL)presented {
    return presented;
}

-(void)initScanningPanel:(CGRect)rect {
    presented = YES;
    
    UIVisualEffectView* blurView = [[UIVisualEffectView alloc] initWithFrame:rect];
    self.view = blurView;
    [self.view setAutoresizesSubviews:YES];
    //[self.view setWantsLayer:YES];
    //[self.view setState:UIVisualEffectStateActive];
    //[self.view setBlendingMode:UIVisualEffectBlendingModeBehindWindow];
    //[self.view setMaterial:UIVisualEffectMaterialDark];
    
    tagvc = [[tagNodesViewController alloc] initWithNibName:@"tagBLEScanningView" bundle:[NSBundle mainBundle]];
    [[BLEHelper_objc sharedInstance] setCallbackDelegate:tagvc];
    [((UIVisualEffectView*)(self.view)).contentView addSubview:tagvc.view];
    [tagvc.view setFrame:self.view.bounds];

}

-(void)dealloc {
    //clear BLE helper delegate pointer;
    [[BLEHelper_objc sharedInstance] setCallbackDelegate:nil];
    [tagvc.view removeFromSuperview];
    [tagvc release];
    presented = NO;
    
    [super dealloc];
}
@end
