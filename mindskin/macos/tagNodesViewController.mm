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
#include "QGCApplication.h"
#include "mavlink.h"


//sound play;
#import <AudioToolbox/AudioToolbox.h>


@implementation tagNodesViewController

+ (tagNodesViewController*) sharedInstance {
    static tagNodesViewController* sharedInstance;
    
    @synchronized(self)
    {
        if (!sharedInstance) {
            sharedInstance = [[tagNodesViewController alloc] init];
        }
        
        return sharedInstance;
    }
    
}

- (tagNodesViewController*)init {
    self = [super init];
    presented = NO;
    
    return self;
}
#if 0
- (void)loadView {
 /*
    if (textview == nil) {
        
        textview = [[NSTextView alloc] initWithFrame:msgrect];
        //textview.font = msgfont;
        //textview.textColor = msgcolor;
        textview.backgroundColor = [NSColor clearColor];
        [((NSVisualEffectView*)(self.view)) addSubview:textview];
        
    }
    else {
        //adjust view height to fit text message into.
        textview.frame = msgrect;
        
    }
    */
    //set data source;
    tagnodeslistview.dataSource = self;
    tagnodeslistview.delegate = self;
}
#endif

- (void)configureView
{
    // Update the user interface for the detail item.
    

}


- (void)viewDidLoad {
    [super viewDidLoad];
     
    // Do any additional setup after loading the view.
    //[self presentTagNodesDiscoveryUI];
    
    presented = YES;
    
    conn_stage = BT_SCANNING;
    
    btlinksarray = [[NSMutableArray alloc] initWithCapacity:0];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)isPresented {
    return presented;
}

- (void)presentTagNodesDiscoveryUI {

    //hide table view;
    //tagnodeslistview.frame = tableframe;
    
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


#pragma mark - Tagnode list table View

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
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

-(CGFloat)tableView:(NSTableView*)tableView heightForFooterInSection:(NSInteger)section {
    return 10;
}

- (NSView *)tableView:(NSTableView *)tableView viewForFooterInSection:(NSInteger)section {
    
    NSView* tableFooterView = [[NSView alloc] initWithFrame:CGRectZero];
    return tableFooterView;
    //return nil;
    
    
}


- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    
    if (conn_stage == CONN_ALLLINKS) {
        //return full height of screen, seems needed for xcode 8 and above;
        return 40;//tableView.frame.size.height;
     }
    else if (conn_stage == BT_SCANNING){
        //return full height of screen;
        return 40;//tableView.frame.size.height;
    }
    else {
        if (row==0) {
            return 40;
        }
        else if (row==[btlinksarray count]-1) {
            return 100;
        }
        else {
            return 40;
        }
    }
}


- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    //NSTableCellView *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    static NSString *cellIdentifier = @"sideMenuCell";
    
    NSTableRowView* cell = nil;
    
    if (!cell) {
        cell = [[NSTableRowView alloc] init];
    }
    [cell setBackgroundColor:[NSColor clearColor]];
    if (conn_stage == BT_SCANNING) {
        [self configureBluetoothCell:cell atIndexPath:row];
    }
    else if (conn_stage == BT_DISCOVERED){
        [self configureDiscoveredBTLinksCell:cell atIndexPath:row];
    }
    else {
        [self configureCell:cell atIndexPath:row];
        
    }
    return cell;
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (void)configureDiscoveredBTLinksCell:(NSTableRowView *)cell atIndexPath:(NSInteger)indexPath {
    //NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    //cell.textLabel.text = [[object valueForKey:@"timeStamp"] description];
    //int cellwidth = cell.frame.size.width;
    
    //main label;
    CGRect btnrect = CGRectMake(30, 5, 120, 40);
    
    NSTextField* label= (NSTextField*)[cell viewWithTag:(200+indexPath)];
    if ( label== nil) {
        
        label = [[NSTextField alloc] initWithFrame:btnrect];
        [label setBezeled:NO];
        [label setDrawsBackground:NO];
        [label setEditable:NO];
        [label setSelectable:NO];
        label.tag = 200 + indexPath;
        label.font = [NSFont fontWithName:@"HelveticaNeue-Light" size:16];
        label.textColor=[NSColor colorWithRed:0.5f green:0.5f blue:0.5 alpha:1.0f];
        
        [cell addSubview:label];
        
    }
    
    //rssi label;
    CGRect rssirect = CGRectMake(200, 5, 60, 40);
    NSTextField* rssilabel =(NSTextField*)[cell viewWithTag:(199)];
    if ( rssilabel== nil) {
        
        rssilabel = [[NSTextField alloc] initWithFrame:rssirect];
        [rssilabel setBezeled:NO];
        [rssilabel setDrawsBackground:NO];
        [rssilabel setEditable:NO];
        [rssilabel setSelectable:NO];

        rssilabel.tag = 199;
        rssilabel.font = [NSFont fontWithName:@"HelveticaNeue-bold" size:14];
        rssilabel.textColor=[NSColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1.0f];
        [cell addSubview:rssilabel];
        
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
    
    BLE_Discovered_Peripheral* cbp = [btlinksarray objectAtIndex:indexPath];
    
    //get the best display name of this device;
    NSString* ident = [cbp.cbperipheral.identifier UUIDString];
    //QString name;
    
    NSString* blename;
    if (cbp.advertisementdata==nil) {
        
        if (cbp.cbperipheral.name == nil || [cbp.cbperipheral.name compare:@""]==NSOrderedSame) {
            blename = ident;
        }
        else {
            blename = cbp.cbperipheral.name;
        }
        
    }
    else {
        blename = [(NSDictionary*)(cbp.advertisementdata) valueForKey:CBAdvertisementDataLocalNameKey];
        if (blename == nil || [blename compare:@""]==NSOrderedSame) {
            if (cbp.cbperipheral.name == nil || [cbp.cbperipheral.name compare:@""]==NSOrderedSame) {
                blename = ident;
            }
            else {
                blename = cbp.cbperipheral.name;
            }
            
        }
    }
    [label setStringValue:blename];
    [rssilabel setStringValue:[NSNumber numberWithInt:[cbp currentFilteredRssi]].stringValue];
    //NSLog(@"Peripheral name: %@, rssi: %d", blename, [cbp currentFilteredRssi]);
    //}
    
    //NSString* btnTitle;
    
}

- (void)configureCell:(NSTableRowView *)cell atIndexPath:(NSInteger)indexPath {
    //NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    //cell.textLabel.text = [[object valueForKey:@"timeStamp"] description];
    
    int cellwidth = cell.frame.size.width;
    CGRect btnrect = CGRectMake(30, 5, 160, 40);
    
    NSTextField* label= (NSTextField*)[cell viewWithTag:(200+indexPath)];
    if ( label== nil) {
        
        label = [[NSTextField alloc] initWithFrame:btnrect];
        label.tag = 200 + indexPath;
        
        [cell addSubview:label];
        
    }
    //[btn setFrame:btnrect];
    
    
    NSString* atitle;
    //[cell.contentView addSubview:btn];
    
    if (indexPath < [conarray count]) {
        atitle = [conarray objectAtIndex:indexPath];
        label.font = [NSFont fontWithName:@"HelveticaNeue-Light" size:16];
        label.textColor=[NSColor colorWithRed:1.0f green:1.0f blue:1.0 alpha:1.0f];
        
        [label setStringValue:atitle]; //NSLocalizedStringFromTable(@"Device number", @"InfoPlist",@"comment");
        
        //[btn setTitle:btnTitle forState:UIControlStateNormal];
        
    }
    else {
        if (indexPath == [conarray count]) {
            //bluetooth entry;
            //reset table list content;
            //[btn setTitle:@"MindStick Bluetooth" forState:UIControlStateNormal];
            label.font = [NSFont fontWithName:@"HelveticaNeue-Light" size:16];
            label.textColor=[NSColor colorWithRed:0.012f green:0.66f blue:0.95f alpha:1.0f];
            
            [label setStringValue:@"MindStick Bluetooth"];
        }
        else {
            //add connection entry;
            //[btn setTitle:@"Add Connection" forState:UIControlStateNormal];
            label.font = [NSFont fontWithName:@"HelveticaNeue-Light" size:16];
            label.textColor=[NSColor colorWithRed:0.0f green:1.0f blue:0.0f alpha:1.0f];
            
            [label setStringValue:@"Add Connection"];
            
        }
    }
}

- (void)configureBluetoothCell:(NSTableRowView *)cell atIndexPath:(NSInteger)indexPath {
    //searching bluetooth device;
    //int idx = [indexPath indexAtPosition:1];
    int cellwidth = cell.frame.size.width;
    
    //main label;
    CGRect btnrect = CGRectMake(30, 5, 160, 40);
    NSTextField* label =(NSTextField*)[cell viewWithTag:(200+indexPath)];
    if ( label== nil) {
        
        label = [[NSTextField alloc] initWithFrame:btnrect];
        label.tag = 200 + indexPath;
        label.font = [NSFont fontWithName:@"HelveticaNeue-Light" size:16];
        label.textColor=[NSColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1.0f];
        [cell addSubview:label];
        
    }
    
    //rssi label;
    CGRect rssirect = CGRectMake(200, 5, 60, 40);
    NSTextField* rssilabel =(NSTextField*)[cell viewWithTag:(199)];
    if ( rssilabel== nil) {
        
        rssilabel = [[NSTextField alloc] initWithFrame:rssirect];
        rssilabel.tag = 199;
        rssilabel.font = [NSFont fontWithName:@"HelveticaNeue-Light" size:16];
        rssilabel.textColor=[NSColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1.0f];
        [cell addSubview:rssilabel];
        
    }
    
    switch (indexPath) {
        case 0:
            [label setStringValue:@"Searching..."];
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
        NSMutableIndexSet *paths=[[NSMutableIndexSet alloc] init];
        for (NSInteger i = 0; i < [tagnodeslistview numberOfRows]; ++i)
        {
            
            [paths addIndex:i];
        }
        
        [tagnodeslistview removeRowsAtIndexes:paths
                                withAnimation:NSTableViewAnimationEffectFade];
        
        [tagnodeslistview endUpdates];
    }
    
    //update discovered list;
    //check in list first;
    BLE_Discovered_Peripheral* p;
    for (p in p_in) {
        BOOL found=NO;
        int idx=0;
        for (BLE_Discovered_Peripheral* pt in btlinksarray) {
            
            if (pt.cbperipheral.identifier == p.cbperipheral.identifier) {
                found = YES;
                break;
            }
            idx ++;
        }
        if (found==NO) {
            //add this in range device;
            [btlinksarray addObject:p];
            [tagnodeslistview beginUpdates];
            NSIndexSet* paths = [NSIndexSet indexSetWithIndex:[btlinksarray count]-1];
            
            [tagnodeslistview insertRowsAtIndexes:paths
                                    withAnimation:NSTableViewAnimationEffectFade];
            
            [tagnodeslistview endUpdates];
            
        }
    }
    
    //check outrange list;
    for (p in p_out) {
        //BOOL found = NO;
        int idx = 0;
        for (BLE_Discovered_Peripheral* pt in btlinksarray) {
            if (pt.cbperipheral.identifier == p.cbperipheral.identifier) {
                [btlinksarray removeObjectAtIndex:idx];
                [tagnodeslistview beginUpdates];
                
                NSIndexSet *paths = [NSIndexSet indexSetWithIndex:idx];
                
                [tagnodeslistview removeRowsAtIndexes:paths
                                        withAnimation:NSTableViewAnimationEffectFade];
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
    
        //already connected?
        BLE_Discovered_Peripheral* cbp = (BLE_Discovered_Peripheral*)[btlinksarray objectAtIndex:0];
        
        if ([cbp isConnected]) {
#ifdef __mindskin_DEBUG__
            NSLog(@"already connected\n");
#endif
            return;
        }
        
        //no;
        if ([cbp hardwareConnectStatus]!= BLE_Peripheral_HARDWARE_NOTCONNECTED) {
            //connecting or connected;
#ifdef __mindskin_DEBUG__
            NSLog(@"already Connecting...\n");
#endif
            return;
        }
        else {
#ifdef __mindskin_DEBUG__
            NSLog(@"Try connect to peripheral hardware...\n");
#endif
            [cbp setHardwareConnectStatus:BLE_Peripheral_HARDWARE_CONNECTING];
            [self performSelector:@selector(connectSingleBLEPeripheral:) withObject:nil afterDelay:0.5];
        }
    }
}

-(void)connectSingleBLEPeripheral:(id)peripheral {
    BLE_Discovered_Peripheral* cbp = (BLE_Discovered_Peripheral*)[btlinksarray objectAtIndex:0];
    
    [[BLEHelper_objc sharedInstance] createBTSerialLinkFromPeripheral:cbp];
    /*
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
        
        btconfig->configBLESerialLink(ident, name, sid, cid, BLE_LINK_CONNECT_CHARACTERISTIC);
        
        //create a physical link and connect;
        BTSerialLink* blelink = qgcApp()->toolbox()->linkManager()->createConnectedBLELink(btconfig);
        //[blelink _connect];
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

-(void)didConnectBTLink:(CBPeripheral*)cbp result:(BOOL)yor {
    if (yor) {
        //connected, make the beep sound;
        NSLog(@"Beep One...\n");
        int idx = [btlinksarray indexOfObject:cbp];
        
        NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"BEEP1C" ofType:@"WAV"];
        SystemSoundID soundID;
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:soundPath], &soundID);
        AudioServicesPlaySystemSound(soundID);
        
        //get tag node system ID;
        //Load Flight controller UI;
        //tagNodeInfoViewController* tagInfovc = [[tagNodeInfoViewController alloc] initWithNibName:@"tagNodeInfoViewController" bundle:nil];
        //[self presentViewController:tagInfovc animated:YES completion:nil];
        
    }
    else {
        //display alert;
        NSString* errorTitle = NSLocalizedStringFromTable(@"Connect Error", @"InfoPlist",@"comment");
        NSString* errorMsg = NSLocalizedStringFromTable(@"Can not connect to device, please retry.", @"InfoPlist",@"comment");
        NSString* cancel=NSLocalizedStringFromTable(@"Cancel", @"InfoPlist",@"comment");
        //NSAlert * errorwindow = [[NSAlert alloc] initWithTitle:errorTitle message:errorMsg delegate:self cancelButtonTitle:cancel otherButtonTitles:@"OK",nil];
        //errorwindow.tag=3;
        //[errorwindow show];
    }
    
    
}

-(void)didReadConnectedBTLinkRSSI:(BLE_Discovered_Peripheral_List*)bdplist {
    NSArray* plist = [bdplist getPeripheralList];
    for (BLE_Discovered_Peripheral* p in plist) {
        //check display list and update UI one by one;
        int i=0;
        for (BLE_Discovered_Peripheral* pt in btlinksarray) {
            
            if ([pt.cbperipheral.identifier isEqual: p.cbperipheral.identifier]) {
                //update rssi of the entry;
                //[[tagnodeslistview cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]] setNeedsDisplay];
                //[tagnodeslistview reloadData];
                [btlinksarray replaceObjectAtIndex:i withObject:p];
                NSTableRowView* bdpcell = [tagnodeslistview rowViewAtRow:i makeIfNecessary:NO];
                [self configureDiscoveredBTLinksCell:bdpcell
                                         atIndexPath:i];
                
                //NSLog(@"reload tag node table %d\n", [pt currentFilteredRssi]);
            }
            i++;
        }
        
    }
    
}

- (void)didConnectBLEHardware:(CBPeripheral *)cbp {
    
}


- (void)failedConnectBLEHardware:(CBPeripheral *)cbp {
    
}


- (void)failedConnectBTLink:(CBPeripheral *)cbp result:(BOOL)yor {
    
}


/*
 -(void)didReadConnectedBTLinkRSSI:(CBPeripheral*)cbp RSSI:(int)rssi inrange:(BOOL)inrange {
 //find link from peripheral;
 
 BTSerialConfiguration* btconfig = new BTSerialConfiguration(QString::fromNSString([cbp name]));
 QString ident = QString::fromNSString([[cbp identifier] UNSDString]);
 QString name = QString::fromNSString([cbp name]);
 
 QString sid = QString::fromNSString(MAV_TRANSFER_SERVICE_UNSD);
 QString cid = QString::fromNSString(MAV_TRANSFER_CHARACTERISTIC_UNSD);
 
 btconfig->configBLESerialLink(ident, name, sid, cid, BLE_LINK_CONNECT_CHARACTERISTIC);
 
 BTSerialLink* blelink = qgcApp()->toolbox()->linkManager()->getBLELinkByConfiguration(btconfig);
 
 
 if (!blelink) {
 //not found;
 return;
 
 }
 
 else {
 if (!inrange) {
 //not in range, disconnect;
 qgcApp()->toolbox()->linkManager()->disconnectLink(blelink);
 
 //update NS by disable connection icon;
 [self disableMindStickStatusIcon];
 
 
 //reconnect to wait back in range;
 qgcApp()->toolbox()->linkManager()->connectLink(blelink);
 
 }
 else {
 //read rssi and update NS;
 }
 }
 }
 */

- (void)tableView:(NSTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
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
                                 withRowAnimation:NSTableViewAnimationEffectFade];
                
            }
            else {
                //add needed cells;
                NSMutableArray *paths = [[NSMutableArray alloc] initWithCapacity:0];
                for(int i=0; i<3-[conarray count]; i++) {
                    [paths addObject:[NSIndexPath indexPathForRow:[conarray count]+i inSection:0]];
                }
                
                //NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:idx inSection:1]];
                
                [tableView insertRowsAtIndexPaths:paths
                                 withRowAnimation:NSTableViewAnimationEffectFade];
                
                
            }
            
            //update menu text;
            for (NSInteger i = 0; i < [tableView numberOfRows]; ++i)
            {
                NSTableRowView* cell = [tableView rowViewAtRow:i makeIfNecessary:NO];
                [self configureBluetoothCell:cell atIndexPath:i];
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
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                context.duration = 0.2;
                [self.view setFrame:CGRectMake(viewFrame.origin.x+200, 60, 200, viewFrame.size.width)];
            }
                                completionHandler:^{
                                    [ self.view removeFromSuperview];
                                    presented=NO;
                                    
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
        QString ident = QString::fromNSString([cbp.cbperipheral.identifier UUIDString]);
        QString name;
        
        NSString* blename;
        if (cbp.advertisementdata==nil) {
            
            if (cbp.cbperipheral.name == nil || [cbp.cbperipheral.name compare:@""]==NSOrderedSame) {
                name = ident;
            }
            else {
                name = QString::fromNSString(cbp.cbperipheral.name);
            }
            
        }
        else {
            blename = [(NSDictionary*)(cbp.advertisementdata) valueForKey:CBAdvertisementDataLocalNameKey];
            if (blename != nil && [blename compare:@""]!=NSOrderedSame) {
                name = QString::fromNSString(blename);
            }
            else {
                if (cbp.cbperipheral.name == nil || [cbp.cbperipheral.name compare:@""]==NSOrderedSame) {
                    name = ident;
                }
                else {
                    name = QString::fromNSString(cbp.cbperipheral.name);
                }
                
            }
        }
        
        BTSerialConfiguration* btconfig = new BTSerialConfiguration(name);
        QString sid = QString::fromNSString(MAV_TRANSFER_SERVICE_UUID);
        QString cid = QString::fromNSString(MAV_TRANSFER_CHARACTERISTIC_UUID);
        
        btconfig->configBLESerialLink(ident, name, sid, cid, BLE_LINK_CONNECT_CHARACTERISTIC);
        
        //create a physical link and connect;
        BTSerialLink* blelink = qgcApp()->toolbox()->linkManager()->createConnectedBLELink(btconfig);
        
        
    }
    
}

-(void)setConnectActionDelegate:(void*)adelegate{
    delegate = adelegate;
}


- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    
}

@end
