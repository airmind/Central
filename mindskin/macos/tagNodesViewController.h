//
//  tagNodesViewController.h
//  qgroundcontrol
//
//  Created by ning roland on 7/17/16.
//
//

#import <AppKit/AppKit.h>
#import "BLELinkConnectionDelegate.h"

typedef enum {
    CONN_ALLLINKS,
    BT_SCANNING,
    BT_DISCOVERED,
    
} CONN_STAGE;

//Have to conform to BLELinkConnectionDelegate protocol;
@interface tagNodesViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate, BLELinkConnectionDelegate> {
    
    NSArray* conarray;
    NSMutableArray* btlinksarray;
    NSTextView* textview;
    IBOutlet NSTableView* tagnodeslistview;
    
    BOOL presented;
    CONN_STAGE conn_stage;
    
    void* delegate;


}

@property (strong, nonatomic) id detailItem;

+(tagNodesViewController*) sharedInstance;
-(BOOL)isPresented;

@end
