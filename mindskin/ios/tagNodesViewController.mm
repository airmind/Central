//
//  tagNodesViewController.m
//  qgroundcontrol
//
//  Created by ning roland on 7/17/16.
//
//

#import "BTSerialLink_objc.h"
#import "tagNodesViewController.h"
#include "LinkManager.h"
#include "qt2ioshelper.h"
#include "ConnectPopover.h"
#include "QGCApplication.h"

//sound play;
#import <AudioToolbox/AudioToolbox.h>

@interface tagNodesViewController ()

@end

@implementation tagNodesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self presentTagNodesDiscoveryUI];
    
    //start scan;
    qgcApp()->toolbox()->linkManager()->setCallbackDelegate((__bridge void *)self);
    qgcApp()->toolbox()->linkManager()->discoverBTLinks(nil); /*add a threshold value?*/
    
    conn_stage = BT_SCANNING;
    
    btlinksarray = [[NSMutableArray alloc] initWithCapacity:0];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)presentTagNodesDiscoveryUI {
    //init tagimage view - full screen;
    tagImage.frame = self.view.frame;
    
    //hide table view;
    CGRect tableframe = CGRectMake(tagImage.frame.size.width, 0, 0, tagImage.frame.size.height);
    tagnodeslistview.frame = tableframe;
    
    //power on NFC/BLE;
    
    
}


- (int)checkNFCStatus {
    
}


- (void)getTagNodesList {
    
}

- (void)loadTagNodesTableView {
    
}

- (void)switchToWifiConnection {
    
}

- (void)switchToTagNodesConnection {
    
}


-(IBAction)onWifiButtonTapped:(id)sender {
    
}


#pragma mark - Tagnode list table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    //return [sectionInfo numberOfObjects];
    if (conn_stage == BT_DISCOVERED) {
        return [btlinksarray count];
    }
    else  {
        return 1;
    }
    
    /*
    else {
        return [conarray count]+2;
    }
     */
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
        //return full height of screen;
        
     }
    else if (conn_stage == BT_SCANNING){
        //return full height of screen;
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
    
    /*
     if (idx==0) {
     label.text = @"Searching ble ...";
     }
     else if (idx == [btlinksarray count]) {
     label.text = @"back";
     }
     else {
     */
    
    BLE_Discovered_Peripheral* cbp = [btlinksarray objectAtIndex:idx];
    
    //get the best display name of this device;
    NSString* ident = [cbp.peripheral.identifier UUIDString];
    //QString name;
    
    NSString* blename;
    if (cbp.advertisementdata==nil) {
        
        if (cbp.peripheral.name == nil || [cbp.peripheral.name compare:@""]==NSOrderedSame) {
            blename = ident;
        }
        else {
            blename = cbp.peripheral.name;
        }
        
    }
    else {
        blename = [(NSDictionary*)(cbp.advertisementdata) valueForKey:CBAdvertisementDataLocalNameKey];
        if (blename == nil || [blename compare:@""]==NSOrderedSame) {
            if (cbp.peripheral.name == nil || [cbp.peripheral.name compare:@""]==NSOrderedSame) {
                blename = ident;
            }
            else {
                blename = cbp.peripheral.name;
            }
            
        }
    }
    label.text = blename;
    
    NSLog(@"Peripheral name: %@", blename);
    //}
    
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
        
        [tagnodeslistview beginUpdates];
        NSMutableArray *paths=[[NSMutableArray alloc] initWithCapacity:0];
        for (NSInteger i = 0; i < [tagnodeslistview numberOfRowsInSection:0]; ++i)
        {
            
            [paths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        [tagnodeslistview deleteRowsAtIndexPaths:paths
                              withRowAnimation:UITableViewRowAnimationFade];
        
        [tagnodeslistview endUpdates];
    }
    
    //update discovered list;
    //check in list first;
    BLE_Discovered_Peripheral* p;
    for (p in p_in) {
        BOOL found=NO;
        int idx=0;
        for (BLE_Discovered_Peripheral* pt in btlinksarray) {
            
            if (pt.peripheral.identifier == p.peripheral.identifier) {
                found = YES;
                break;
            }
            idx ++;
        }
        if (found==NO) {
            //add this in range device;
            [btlinksarray addObject:p];
            [tagnodeslistview beginUpdates];
            NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:[btlinksarray count]-1 inSection:0]];
            
            [tagnodeslistview insertRowsAtIndexPaths:paths
                                  withRowAnimation:UITableViewRowAnimationFade];
            
            [tagnodeslistview endUpdates];
            
        }
    }
    
    //check outrange list;
    for (p in p_out) {
        //BOOL found = NO;
        int idx = 0;
        for (BLE_Discovered_Peripheral* pt in btlinksarray) {
            if (pt.peripheral.identifier == p.peripheral.identifier) {
                [btlinksarray removeObjectAtIndex:idx];
                [tagnodeslistview beginUpdates];
                
                NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:idx inSection:0]];
                
                [tagnodeslistview deleteRowsAtIndexPaths:paths
                                      withRowAnimation:UITableViewRowAnimationFade];
                [tagnodeslistview endUpdates];
                break;
                
            }
            idx ++;
        }
    }
    
    [p_in release];
    [p_out release];
    
    
    //check if the only one found; if did, auto connect it and beep.
    if ([btlinksarray count] == 1) {
        BLE_Discovered_Peripheral* cbp = (BLE_Discovered_Peripheral*)[btlinksarray objectAtIndex:0];
        
        //get the best display name of this device;
        QString ident = QString::fromNSString([cbp.peripheral.identifier UUIDString]);
        QString name;
        
        NSString* blename;
        if (cbp.advertisementdata==nil) {
            
            if (cbp.peripheral.name == nil || [cbp.peripheral.name compare:@""]==NSOrderedSame) {
                name = ident;
            }
            else {
                name = QString::fromNSString(cbp.peripheral.name);
            }
            
        }
        else {
            blename = [(NSDictionary*)(cbp.advertisementdata) valueForKey:CBAdvertisementDataLocalNameKey];
            if (blename != nil && [blename compare:@""]!=NSOrderedSame) {
                name = QString::fromNSString(blename);
            }
            else {
                if (cbp.peripheral.name == nil || [cbp.peripheral.name compare:@""]==NSOrderedSame) {
                    name = ident;
                }
                else {
                    name = QString::fromNSString(cbp.peripheral.name);
                }
                
            }
        }
        
        BTSerialConfiguration* btconfig = new BTSerialConfiguration(name);
        QString sid = QString::fromNSString(MAV_TRANSFER_SERVICE_UUID);
        QString cid = QString::fromNSString(MAV_TRANSFER_CHARACTERISTIC_UUID);
        
        btconfig->configBLESerialLink(ident, name, sid, cid, BLE_LINK_CONNECTED_CHARACTERISTIC);
        
        //create a physical link and connect;
        BTSerialLink* blelink = qgcApp()->toolbox()->linkManager()->createConnectedBLELink(btconfig);
        //[blelink _connect];

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



/* moved to MindStickButton class;
 -(void)showMindStickStatusIcon {
 if (mindstickiconbutton==nil) {
 CGRect btnrect = CGRectMake(400, 300, 48, 48);
 mindstickiconbutton = [[UIButton alloc] initWithFrame:btnrect];
 mindstickiconbutton.tag=1200;
 UIImage *buttonImageNormal= [UIImage imageNamed:@"refresh@2x.png"];
 [mindstickiconbutton setBackgroundImage:buttonImageNormal	forState:UIControlStateNormal];
 UIImage *buttonImageHighlight = [UIImage imageNamed:@"refreshgrey@2x.png"];
 [mindstickiconbutton setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
 //[mindstickiconbutton addTarget:self action:@selector(resetButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
 [rootviewcontroller.view addSubview:mindstickiconbutton];
 
 }
 }
 
 -(void)enableMindStickStatusIcon {
 mindstickiconbutton.enabled = YES;
 }
 
 -(void)disableMindStickStatusIcon {
 mindstickiconbutton.enabled = NO;
 }
 
 -(void)dealloc {
 [mindstickiconbutton release];
 mindstickiconbutton = nil;
 [super dealloc];
 }
 
 */

-(void)didConnectedBTLink:(CBPeripheral*)cbp result:(BOOL)yor {
    if (yor) {
        //connected, make the beep sound;
        int idx = [btlinksarray indexOfObject:cbp];
        
        NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"BEEP1C" ofType:@"WAV"];
        SystemSoundID soundID;
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:soundPath], &soundID);
        AudioServicesPlaySystemSound(soundID);
        
        //get tag node system ID;
        
        //get into main menu UI;
        //[self showMindStickStatusIcon];
        
    }
    else {
        //display alert;
        NSString* errorTitle = NSLocalizedStringFromTable(@"Connect Error", @"InfoPlist",@"comment");
        NSString* errorMsg = NSLocalizedStringFromTable(@"Can not connect to device, please retry.", @"InfoPlist",@"comment");
        NSString* cancel=NSLocalizedStringFromTable(@"Cancel", @"InfoPlist",@"comment");
        UIAlertView * errorwindow = [[UIAlertView alloc] initWithTitle:errorTitle message:errorMsg delegate:self cancelButtonTitle:cancel otherButtonTitles:@"OK",nil];
        errorwindow.tag=3;
        [errorwindow show];
    }
    
    
}

-(void)didReadConnectedBTLinkRSSI:(CBPeripheral*)cbp RSSI:(int)rssi inrange:(BOOL)inrange {
    //find link from peripheral;
    
    BTSerialConfiguration* btconfig = new BTSerialConfiguration(QString::fromNSString([cbp name]));
    QString ident = QString::fromNSString([[cbp identifier] UUIDString]);
    QString name = QString::fromNSString([cbp name]);
    
    QString sid = QString::fromNSString(MAV_TRANSFER_SERVICE_UUID);
    QString cid = QString::fromNSString(MAV_TRANSFER_CHARACTERISTIC_UUID);
    
    btconfig->configBLESerialLink(ident, name, sid, cid, BLE_LINK_CONNECTED_CHARACTERISTIC);
    
    BTSerialLink* blelink = qgcApp()->toolbox()->linkManager()->getBLELinkByConfiguration(btconfig);
    
    
    if (!blelink) {
        //not found;
        return;
        
    }
    
    else {
        if (!inrange) {
            //not in range, disconnect;
            qgcApp()->toolbox()->linkManager()->disconnectBLELink(blelink);
            
            //update UI by disable connection icon;
            [self disableMindStickStatusIcon];
            
            
            //reconnect to wait back in range;
            qgcApp()->toolbox()->linkManager()->connectBLELink(blelink);
            
        }
        else {
            //read rssi and update UI;
        }
    }
}

-(void)dismissPopoverView {
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
                             presented=NO;
                         }
                         
                     }];
    
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
                
                [tableView deleteRowsAtIndexPaths:paths
                                      withRowAnimation:UITableViewRowAnimationFade];
                
            }
            else {
                //add needed cells;
                NSMutableArray *paths = [[NSMutableArray alloc] initWithCapacity:0];
                for(int i=0; i<3-[conarray count]; i++) {
                    [paths addObject:[NSIndexPath indexPathForRow:[conarray count]+i inSection:0]];
                }
                
                //NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:idx inSection:1]];
                
                [tableView insertRowsAtIndexPaths:paths
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
            //((MainToolBarController*)delegate)->onConnect(QString::fromNSString([conarray objectAtIndex:idx]));
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
                                     presented=NO;
                                 }
                                 
                             }];
            
            
        }
        else {
            //connect selected devices;
#ifdef _BLE_DEBUG_
            //pop up debug view;
#endif
            
        }
        
        BLE_Discovered_Peripheral* cbp = (BLE_Discovered_Peripheral*)[btlinksarray objectAtIndex:idx];
        
        //get the best display name of this device;
        QString ident = QString::fromNSString([cbp.peripheral.identifier UUIDString]);
        QString name;
        
        NSString* blename;
        if (cbp.advertisementdata==nil) {
            
            if (cbp.peripheral.name == nil || [cbp.peripheral.name compare:@""]==NSOrderedSame) {
                name = ident;
            }
            else {
                name = QString::fromNSString(cbp.peripheral.name);
            }
            
        }
        else {
            blename = [(NSDictionary*)(cbp.advertisementdata) valueForKey:CBAdvertisementDataLocalNameKey];
            if (blename != nil && [blename compare:@""]!=NSOrderedSame) {
                name = QString::fromNSString(blename);
            }
            else {
                if (cbp.peripheral.name == nil || [cbp.peripheral.name compare:@""]==NSOrderedSame) {
                    name = ident;
                }
                else {
                    name = QString::fromNSString(cbp.peripheral.name);
                }
                
            }
        }
        
        BTSerialConfiguration* btconfig = new BTSerialConfiguration(name);
        QString sid = QString::fromNSString(MAV_TRANSFER_SERVICE_UUID);
        QString cid = QString::fromNSString(MAV_TRANSFER_CHARACTERISTIC_UUID);
        
        btconfig->configBLESerialLink(ident, name, sid, cid, BLE_LINK_CONNECTED_CHARACTERISTIC);
        
        //create a physical link and connect;
        BTSerialLink* blelink = qgcApp()->toolbox()->linkManager()->createConnectedBLELink(btconfig);
        //[blelink _connect];
        
    }
    
}

-(void)setConnectActionDelegate:(void*)adelegate{
    delegate = adelegate;
}
@end
