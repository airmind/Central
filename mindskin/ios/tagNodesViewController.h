//
//  tagNodesViewController.h
//  qgroundcontrol
//
//  Created by ning roland on 7/17/16.
//
//

#import <UIKit/UIKit.h>

@interface tagNodesViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>{
    IBOutlet UITableView* tagnodeslist;
    IBOutlet UIImageView* tagImage;
    IBOutlet UIButton* wifiButton;
}

-(IBAction)onWifiButtonTapped:(id)sender;

@end
