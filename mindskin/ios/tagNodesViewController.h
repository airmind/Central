//
//  tagNodesViewController.h
//  qgroundcontrol
//
//  Created by ning roland on 7/17/16.
//
//

#import <UIKit/UIKit.h>

typedef enum {
    CONN_ALLLINKS,
    BT_SCANNING,
    BT_DISCOVERED,
    
} CONN_STAGE;


@interface tagNodesViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate> {
    
    //ConnectPopoverViewController* tagnodelistviewcontroller;
    
    IBOutlet UITableView* tagnodeslistview;
    IBOutlet UIImageView* tagImage;
    IBOutlet UIButton* wifiButton;
    
    NSArray* conarray;
    NSMutableArray* btlinksarray;
    
    BOOL presented;
    CONN_STAGE conn_stage;
    
    void* delegate;


}

-(IBAction)onWifiButtonTapped:(id)sender;

@end
