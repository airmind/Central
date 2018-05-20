//
//  tagNodesViewController.h
//  qgroundcontrol
//
//  Created by ning roland on 7/17/16.
//
//

#import <UIKit/UIKit.h>
#import "BLELinkConnectionDelegate.h"

typedef enum {
    CONN_ALLLINKS,
    BT_SCANNING,
    BT_DISCOVERED,
    
} CONN_STAGE;

//Have to conform to BLELinkConnectionDelegate protocol;
@interface tagNodesViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, BLELinkConnectionDelegate,
                                                                                    UIPopoverControllerDelegate, UISplitViewControllerDelegate> {
    
    //ConnectPopoverViewController* tagnodelistviewcontroller;
    
    IBOutlet UITableView* tagnodeslistview;
    IBOutlet UIImageView* tagImage;
    IBOutlet UIButton* wifiButton;
    IBOutlet UIButton* longpacketButton;
    
    NSArray* conarray;
    NSMutableArray* btlinksarray;
    
    BOOL presented;
    CONN_STAGE conn_stage;
    
    void* delegate;


}

@property (strong, nonatomic) id detailItem;


-(IBAction)onWifiButtonTapped:(id)sender;
-(IBAction)onLongPacketButtonTapped:(id)sender;

@end
