//
//  RacerMainMenuViewController.h
//  QGroundControl
//
//  Created by ning roland on 8/11/16.
//
//

#import <UIKit/UIKit.h>

@interface MenuController : NSObject {
    NSString* controllername;
    int controllerid;
    
    NSArray* commandbuffer;
    
}

-(NSString*)menuControlCommmandReceived:(NSString*)cmd;
-(void)clearBuffer;

@end


@interface RacerMainMenuViewController : UIViewController {
#ifdef __remotehead__
    
    MenuController* mctlr;
#endif
    
    NSArray* menuitems;
    
    //gestures;
    
    
    
}

-(IBAction)FlightTapped:(id)sender;
-(IBAction)PowerTapped:(id)sender;
-(IBAction)RadioTapped:(id)sender;
-(IBAction)ExpertTapped:(id)sender;
-(IBAction)linkstatusPressed:(id)sender;

@end
