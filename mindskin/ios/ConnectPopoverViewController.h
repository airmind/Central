//
//  ConnectPopoverViewController.h
//  qgroundcontrol
//
//  Created by ning roland on 11/3/15.
//
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef enum {
    CONN_ALLLINKS,
    BT_SCANNING,
    BT_DISCOVERED,

} CONN_STAGE;

@interface ConnectPopoverViewController : UITableViewController <NSFetchedResultsControllerDelegate> {
    NSArray* conarray;
    NSMutableArray* btlinksarray;
    
    BOOL presented;
    CONN_STAGE conn_stage;
    
    void* delegate;
    

}

-(void)didDiscoverBTLinksInRange:(NSArray*)p_in outOfRange:(NSArray*)p_out;
-(void)didConnectedBTLink;
-(void)setConnectActionDelegate:(void*)delegate;

@end
