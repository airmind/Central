//
//  RacerMainMenuView.h
//  QGroundControl
//
//  Created by ning roland on 8/22/16.
//
//

#import <UIKit/UIKit.h>

@interface RacerMainMenuView : UIView {
    IBOutlet UIView* m1;
    IBOutlet UIView* m2;
    IBOutlet UIView* m3;
    IBOutlet UIView* m4;
    
    IBOutlet UIButton* dronestatus;
    IBOutlet UIButton* linkstatus;
    IBOutlet UIButton* gpsstatus;

    IBOutlet UILabel* title;
    
}



@end
