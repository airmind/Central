//
//  ConnectPopoverViewController.m
//  qgroundcontrol
//
//  Created by ning roland on 11/3/15.
//
//

#import "ConnectPopoverViewController.h"
#include "MainToolBarController.h"
#include "LinkManager.h"
#include "qt2ioshelper.h"
#include "ConnectPopover.h"
#include "QGCApplication.h"

NSString* qt2ioshelper::QString2NSString (const QString* qstr) {
    
    std::string str = qstr->toStdString();
    const char *s= str.c_str();
    NSString* nstring = [NSString stringWithUTF8String:s];
    return nstring;
}


//ConnectPopoverWrapper;
//----
class ConnectPopoverWrapper{

private:
    ConnectPopoverViewController* popoverctrol;
    
public:
    ConnectPopoverWrapper();
    ~ConnectPopoverWrapper();
    void presentPopover(QStringList connectionlist);
    void dismissPopover();
    
};


ConnectPopoverWrapper::ConnectPopoverWrapper() {
    
}

ConnectPopoverWrapper::~ConnectPopoverWrapper() {
    
}


void ConnectPopoverWrapper::presentPopover(QStringList connectionList) {
    UIResponder* responder;
    
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(window in windows) {
            if (window.windowLevel == UIWindowLevelNormal) {
                break;
            }
        }
    }
    
    for (UIView *subView in [window subviews])
    {
        UIResponder *tresponder = [subView nextResponder];
        if([tresponder isKindOfClass:[UIViewController class]]) {
            responder= tresponder;
            break;
        }
    }
    
    
    //UIView *view = static_cast<UIView *>(MainWindow::instance());
    //(QGuiApplication::platformNativeInterface()->nativeResourceForWindow("uiview", window()));
    //UIViewController *qtController = [[view window] rootViewController];
    
    NSMutableArray* connectionarray = [[NSMutableArray alloc] init];
    
    int len = connectionList.length();
    for (int i=0; i<len; i++) {
        [connectionarray addObject:(qt2ioshelper::QString2NSString(&connectionList.at(i)))];
        
    }
    
    popoverctrol = [[ConnectPopoverViewController alloc] init:connectionarray];
    CGRect viewFrame = ((UIViewController*)responder).view.frame;
    
    [popoverctrol.view setFrame:CGRectMake(viewFrame.origin.x+viewFrame.size.height, 60, 200, viewFrame.size.width)];
    //[popoverctrol.view setFrame:CGRectMake(0, 0, 100, 100)];
    
    //[responder presentViewController:popoverctrol animated:YES completion:^{
        
        
    // }];

    [((UIViewController*)responder).view addSubview:popoverctrol.view];
    
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [popoverctrol.view setFrame:CGRectMake(viewFrame.origin.x+viewFrame.size.height-200, 60, 200, viewFrame.size.width)];
                         
                     }
                     completion:^(BOOL finished){
                         if (finished) {
                             
                         }
                         
                     }];

    
    //return nil;

}

void ConnectPopoverWrapper::dismissPopover() {
    
    CGRect viewFrame = [popoverctrol.view frame];
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [popoverctrol.view setFrame:CGRectMake(viewFrame.origin.x+200, 60, 200, viewFrame.size.width)];
                         
                     }
                     completion:^(BOOL finished){
                         if (finished) {
                             [ popoverctrol.view removeFromSuperview];
                         }
                         
                     }];
 
   
}

ConnectPopover::ConnectPopover() {
    this->popoverwrapper = new ConnectPopoverWrapper();
}

ConnectPopover::~ConnectPopover() {
    delete this->popoverwrapper;
}


void ConnectPopover::presentPopover(QStringList connectionlist){
    this->popoverwrapper->presentPopover(connectionlist);

}

void ConnectPopover::dismissPopover(){
    
    this->popoverwrapper->dismissPopover();
}



@interface ConnectPopoverViewController ()

@end

@implementation ConnectPopoverViewController

- (ConnectPopoverViewController*)init:(NSArray*)array {
    self = [super init];
    conarray = array;
    conn_stage = CONN_ALLLINKS;
    presented = NO;
    btlinksarray = [[NSMutableArray alloc] initWithCapacity:0];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    ((UITableView*)(self.view)).tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    ((UITableView*)(self.view)).separatorStyle=UITableViewCellSeparatorStyleNone;
    
    [self.view setBackgroundColor:[UIColor colorWithRed:0.7 green:0.8 blue:0.7 alpha:1.0f]];
    
    //self.navigationItem.leftBarButtonItem = self.editButtonItem;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    //return [sectionInfo numberOfObjects];
    if (conn_stage==BT_SCANNING) {
        return 3;
    }
    else if (conn_stage == BT_DISCOVERED) {
        return [btlinksarray count];
    }
    else {
        return [conarray count]+2;
    }
}

-(CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section {
    return 10;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    
    UIView* tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    return tableFooterView;
    //return nil;
    
    
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    //int numRows = [gridData count]/4;
    int idx = [indexPath indexAtPosition:1];
    
    if (conn_stage == CONN_ALLLINKS) {
        
    
        switch (idx) {
            case 0:
                return 40;
            case 1:
                return 40;
            case 2:
                return 40;
            
            default:
                return 40.0;
            
            
        }
    }
    else if (conn_stage == BT_SCANNING){
        switch (idx) {
            case 0:
                return 40;
                
            case 1:
                return 80;
            case 2:
                return 40;
            default:
                break;
        }
    }
    else {
        if (idx==0) {
            return 40;
        }
        else if (idx==[btlinksarray count]-1) {
            return 40;
        }
        else {
            return 40;
        }
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    static NSString *cellIdentifier = @"sideMenuCell";
    
    UITableViewCell* cell = nil;
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    [cell setBackgroundColor:[UIColor clearColor]];
    if (conn_stage == BT_SCANNING) {
        [self configureBluetoothCell:cell atIndexPath:indexPath];
    }
    else if (conn_stage == BT_DISCOVERED){
        [self configureDiscoveredBTLinksCell:cell atIndexPath:indexPath];
    }
    else {
        [self configureCell:cell atIndexPath:indexPath];
        
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (void)configureDiscoveredBTLinksCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    //NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    //cell.textLabel.text = [[object valueForKey:@"timeStamp"] description];
    int idx = [indexPath indexAtPosition:1];
    
    int cellwidth = cell.frame.size.width;
    CGRect btnrect = CGRectMake(30, 5, 120, 40);
    
    UILabel* label= (UILabel*)[cell.contentView viewWithTag:(200+idx)];
    if ( label== nil) {
        
        label = [[UILabel alloc] initWithFrame:btnrect];
        label.tag = 200 + idx;
        label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        label.textColor=[UIColor colorWithRed:1.0f green:1.0f blue:1.0 alpha:1.0f];

        [cell.contentView addSubview:label];

    }
    
    
    if (idx==0) {
        label.text = @"Searching ble ...";
    }
    else if (idx == [btlinksarray count]) {
        label.text = @"back";
    }
    else {
        CBPeripheral* p = [btlinksarray objectAtIndex:idx];
        if (p.name==nil) {
            label.text = [p.identifier UUIDString];
        }
        else {
            label.text = p.name;
        }
    }
    
    //NSString* btnTitle;

}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    //NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    //cell.textLabel.text = [[object valueForKey:@"timeStamp"] description];
    int idx = [indexPath indexAtPosition:1];
    
    int cellwidth = cell.frame.size.width;
    CGRect btnrect = CGRectMake(30, 5, 160, 40);
    
    UILabel* label= (UILabel*)[cell.contentView viewWithTag:(200+idx)];
    if ( label== nil) {
        
        label = [[UILabel alloc] initWithFrame:btnrect];
        label.tag = 200 + idx;
        
        [cell.contentView addSubview:label];

    }
    //[btn setFrame:btnrect];
    
    
    NSString* atitle;
     //[cell.contentView addSubview:btn];
    
    if (idx < [conarray count]) {
        atitle = [conarray objectAtIndex:idx];
        label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        label.textColor=[UIColor colorWithRed:1.0f green:1.0f blue:1.0 alpha:1.0f];
        
        label.text = atitle;//NSLocalizedStringFromTable(@"Device number", @"InfoPlist",@"comment");

        //[btn setTitle:btnTitle forState:UIControlStateNormal];
        
    }
    else {
        if (idx == [conarray count]) {
            //bluetooth entry;
            //reset table list content;
            //[btn setTitle:@"MindStick Bluetooth" forState:UIControlStateNormal];
            label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
            label.textColor=[UIColor colorWithRed:0.012f green:0.66f blue:0.95f alpha:1.0f];

            label.text=@"MindStick Bluetooth";
        }
        else {
            //add connection entry;
            //[btn setTitle:@"Add Connection" forState:UIControlStateNormal];
            label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
            label.textColor=[UIColor colorWithRed:0.0f green:1.0f blue:0.0f alpha:1.0f];
            
            label.text=@"Add Connection";

        }
    }
}

- (void)configureBluetoothCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    //searching bluetooth device;
    int idx = [indexPath indexAtPosition:1];
    int cellwidth = cell.frame.size.width;
    CGRect btnrect = CGRectMake(30, 5, 160, 40);

    UILabel* label =(UILabel*)[cell.contentView viewWithTag:(200+idx)];
    if ( label== nil) {
        
        label = [[UILabel alloc] initWithFrame:btnrect];
        label.tag = 200 + idx;
        label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        label.textColor=[UIColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1.0f];
        [cell.contentView addSubview:label];

    }

    switch (idx) {
        case 0:
            label.text = @"Searching...";
            break;
        case 1:
            //call link manager as self delegate;
            //LinkManager::instance()->discoverBTLinks((__bridge void *)self);
            break;
        case 2:
            //add back button;
            break;
        default:
            break;
    }
    

}


-(void)didDiscoverBTLinksInRange:(NSArray*)p_in outOfRange:(NSArray*)p_out {
    //clear cells;
    if (conn_stage != BT_DISCOVERED) {
        conn_stage = BT_DISCOVERED;

        [self.tableView beginUpdates];
        NSMutableArray *paths=[[NSMutableArray alloc] initWithCapacity:0];
        for (NSInteger i = 0; i < [self.view numberOfRowsInSection:0]; ++i)
        {

            [paths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
    
        [self.tableView deleteRowsAtIndexPaths:paths
                          withRowAnimation:UITableViewRowAnimationFade];
    
        [self.tableView endUpdates];
    }
    
    //update discovered list;
    //check in list first;
    CBPeripheral* p;
    for (p in p_in) {
        BOOL found=NO;
        int idx=0;
        for (CBPeripheral* pt in btlinksarray) {
            
            if (pt == p) {
                found = YES;
                break;
            }
            idx ++;
        }
        if (found==NO) {
            //add this in range device;
            [btlinksarray addObject:p];
            [self.tableView beginUpdates];
            NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:[btlinksarray count]-1 inSection:0]];
            
            [self.tableView insertRowsAtIndexPaths:paths
                                  withRowAnimation:UITableViewRowAnimationFade];

            [self.tableView endUpdates];
            
        }
    }
    
    //check outrange list;
    for (p in p_out) {
        //BOOL found = NO;
        int idx = 0;
        for (CBPeripheral* pt in btlinksarray) {
            if (pt == p) {
                [btlinksarray removeObjectAtIndex:idx];
                [self.tableView beginUpdates];
                
                NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:idx inSection:0]];
                
                [self.tableView deleteRowsAtIndexPaths:paths
                                      withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
                break;

            }
            idx ++;
        }
    }
    
    /*
    
    if (act==0) {
        //remove linkname;
        NSUInteger idx = [btlinksarray indexOfObject:peripheral];
        if (idx != NSNotFound) {
            [btlinksarray removeObjectAtIndex:idx];
        
            [self.tableView beginUpdates];
        //considering table headers;
            NSLog(@"removing row --->\n %d", idx);
            NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:idx inSection:0]];
        
            [self.tableView deleteRowsAtIndexPaths:paths
                              withRowAnimation:UITableViewRowAnimationFade];

            [self.tableView endUpdates];
        }
        
    }
    else {
        //add linkname;
        [btlinksarray addObject:peripheral];
        NSLog(@"adding row --->\n %d", 1);
        
        [self.tableView beginUpdates];
        NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:[btlinksarray count]-1 inSection:0]];
        
        [self.tableView insertRowsAtIndexPaths:paths
                              withRowAnimation:UITableViewRowAnimationFade];
        
        [self.tableView endUpdates];
        /*
        UITableViewCell* cell = [self.view cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[btlinksarray count]-1 inSection:0]];
        [self configureDiscoveredBTLinksCell:cell atIndexPath:[NSIndexPath indexPathForRow:[btlinksarray count]-1 inSection:0]];
        */

    
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    int idx = [indexPath indexAtPosition:1];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    
    
    if (conn_stage == CONN_ALLLINKS) {
        if (idx == [conarray count]) {
            //bluetooth connect pressed;
            conn_stage = BT_SCANNING;

            [tableView beginUpdates];
            if ([conarray count]+2>3) {
                //remove extra cells;
                NSMutableArray *paths = [[NSMutableArray alloc] initWithCapacity:0];
                for(int i=0; i<[conarray count]+2-3; i++) {
                    [paths addObject:[NSIndexPath indexPathForRow:[conarray count]+1-i inSection:0]];
                }

                //NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:idx inSection:1]];
                
                [self.tableView deleteRowsAtIndexPaths:paths
                                      withRowAnimation:UITableViewRowAnimationFade];

            }
            else {
                //add needed cells;
                NSMutableArray *paths = [[NSMutableArray alloc] initWithCapacity:0];
                for(int i=0; i<3-[conarray count]; i++) {
                    [paths addObject:[NSIndexPath indexPathForRow:[conarray count]+i inSection:0]];
                }
                
                //NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:idx inSection:1]];
                
                [self.tableView insertRowsAtIndexPaths:paths
                                      withRowAnimation:UITableViewRowAnimationFade];
               
                
            }
            
            //update menu text;
            for (NSInteger i = 0; i < [tableView numberOfRowsInSection:0]; ++i)
            {
                UITableViewCell* cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                [self configureBluetoothCell:cell atIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            }

            
            [tableView endUpdates];
        
            
            
            //start scan;
            qgcApp()->toolbox()->linkManager()->setCallbackDelegate((__bridge void *)self);
            qgcApp()->toolbox()->linkManager()->discoverBTLinks(nil);

        
        }
        else if (idx == [conarray count] + 1) {
            //add connection pressed;
        }
        else {
            //menutoolbar call back;
            ((MainToolBarController*)delegate)->onConnect(QString::fromNSString([conarray objectAtIndex:idx]));
        }
        
    }
    else if (conn_stage == BT_SCANNING) {
        
    }
    else {
        if (idx == [btlinksarray count]) {
            //cancel pressed;
            //stop scanning and back;
            qgcApp()->toolbox()->linkManager()->stopScanning();
            
            //dismiss this popover;
            CGRect viewFrame = [self.view frame];
            [UIView animateWithDuration:0.2
                                  delay:0
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 [self.view setFrame:CGRectMake(viewFrame.origin.x+200, 60, 200, viewFrame.size.width)];
                                 
                             }
                             completion:^(BOOL finished){
                                 if (finished) {
                                     [ self.view removeFromSuperview];
                                 }
                                 
                             }];

            
        }
        else {
            //connect selected devices;
        }
        
    }
    
}

-(void)setConnectActionDelegate:(void*)adelegate{
    delegate = adelegate;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
