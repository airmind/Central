//
//  tagNodesViewController.m
//  qgroundcontrol
//
//  Created by ning roland on 7/17/16.
//
//

#import "tagNodesViewController.h"

@interface tagNodesViewController ()

@end

@implementation tagNodesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self presentTagNodesDiscoveryUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)presentTagNodesDiscoveryUI {
    
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


/*
 #pragma mark - table view delegates
 
 

 */


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 7;
}

-(CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
    
}

-(CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section {
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    //int numRows = [gridData count]/4;
    int idx = [indexPath indexAtPosition:1];
    switch (idx) {
        case 0:
            return 75;
        case 1:
            return 75;
        case 2:
            return 75;
        case 3:
            return 75;
        case 4:
            return 75.0;
            
        case 5:
            return 60.0;
        case 6:
            return 60;
            
        default:
            return 40.0;
            
            
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"tagNodeCell";
    //UITextField* input;
    UILabel* label;
    //UIButton* genButton;
    
    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    UITableViewCell* cell = nil;
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
    
}


-(void)configureCell:(UITableViewCell*)cell atIndexPath:indexPath {
    int idx = [indexPath indexAtPosition:1];
    
    int cellwidth = bindtable.frame.size.width;
    
    if (idx==0) {
        if (companyname==nil) {
            CGRect companynamerect = CGRectMake(LEFT_INDENT, 5, 150, 30);
            companyname = [[UILabel alloc] initWithFrame:companynamerect];
            companyname.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
            companyname.textColor=[UIColor colorWithRed:0.012f green:0.66f blue:0.95 alpha:1.0f];
            
            companyname.text = NSLocalizedStringFromTable(@"Company Name", @"InfoPlist",@"comment");
        }
        [cell.contentView addSubview:companyname];
        
        if (companynameinput==nil) {
            CGRect companynamerect = CGRectMake(LEFT_INDENT, 35, cellwidth-LEFT_INDENT-RIGHT_INDENT, 40);
            companynameinput = [[UITextField alloc] initWithFrame:companynamerect];
            companynameinput.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
            companynameinput.textColor=[UIColor darkGrayColor];
            companynameinput.borderStyle = UITextBorderStyleRoundedRect;
            companynameinput.delegate=self;
        }
        [cell.contentView addSubview:companynameinput];
        
    }
    else if (idx==1) {
        
        if (username==nil) {
            CGRect usernamerect = CGRectMake(LEFT_INDENT, 5, 100, 30);
            username = [[UILabel alloc] initWithFrame:usernamerect];
            username.text = NSLocalizedStringFromTable(@"User Name", @"InfoPlist",@"comment");
            username.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
            username.textColor=[UIColor colorWithRed:0.012f green:0.66f blue:0.95 alpha:1.0f];
            
        }
        [cell.contentView addSubview:username];
        
        if (usernameinput==nil) {
            CGRect usernamerect = CGRectMake(LEFT_INDENT, 35, cellwidth-LEFT_INDENT-RIGHT_INDENT, 40);
            usernameinput = [[UITextField alloc] initWithFrame:usernamerect];
            usernameinput.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
            usernameinput.textColor=[UIColor darkGrayColor];
            usernameinput.borderStyle = UITextBorderStyleRoundedRect;
            usernameinput.delegate=self;
        }
        [cell.contentView addSubview:usernameinput];
        
    }
    else if (idx==3) { //verification code;
        
        if (verificationlabel==nil) {
            CGRect usernamerect = CGRectMake(LEFT_INDENT, 5, 300, 30);
            verificationlabel = [[UILabel alloc] initWithFrame:usernamerect];
            verificationlabel.text = NSLocalizedStringFromTable(@"Verfication code", @"InfoPlist",@"comment");
            verificationlabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
            verificationlabel.textColor=[UIColor colorWithRed:0.012f green:0.66f blue:0.95 alpha:1.0f];
            
        }
        [cell.contentView addSubview:verificationlabel];
        
        if (verificationinput==nil) {
            CGRect usernamerect = CGRectMake(LEFT_INDENT, 35, cellwidth/2, 40);
            verificationinput = [[UITextField alloc] initWithFrame:usernamerect];
            verificationinput.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
            verificationinput.textColor=[UIColor darkGrayColor];
            verificationinput.borderStyle = UITextBorderStyleRoundedRect;
            verificationinput.delegate=self;
            
        }
        [cell.contentView addSubview:verificationinput];
        
        if (verficationbutton==nil) {
            CGRect submitrect = CGRectMake(cellwidth/2, 35, cellwidth/2-RIGHT_INDENT, 40);
            verficationbutton=[UIButton buttonWithType:UIButtonTypeRoundedRect];
            [verficationbutton setFrame:submitrect];
            NSString* btnTitle = NSLocalizedStringFromTable(@"Get verification code", @"InfoPlist",@"comment");
            [verficationbutton setTitle:btnTitle forState:UIControlStateNormal];
            [verficationbutton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [verficationbutton setBackgroundColor:[UIColor colorWithRed:0.012 green:0.612 blue:0.992 alpha:1.0]];
            
            [verficationbutton addTarget:self action:@selector(getVerificationCodePressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        [cell.contentView addSubview:verficationbutton];
        
    }
    
    
    else if (idx==2) {
        
        if (celltitle==nil) {
            CGRect celltitlerect = CGRectMake(LEFT_INDENT, 5, 150, 30);
            celltitle = [[UILabel alloc] initWithFrame:celltitlerect];
            celltitle.text = NSLocalizedStringFromTable(@"Cell phone number", @"InfoPlist",@"comment");
            celltitle.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
            celltitle.textColor=[UIColor colorWithRed:0.012f green:0.66f blue:0.95 alpha:1.0f];
            
        }
        [cell.contentView addSubview:celltitle];
        
        if (cellnumber==nil) {
            CGRect cellnumberrect = CGRectMake(LEFT_INDENT, 35, cellwidth-LEFT_INDENT-RIGHT_INDENT, 40);
            cellnumber = [[UITextField alloc] initWithFrame:cellnumberrect];
            cellnumber.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
            cellnumber.textColor=[UIColor darkGrayColor];
            cellnumber.borderStyle = UITextBorderStyleRoundedRect;
            cellnumber.delegate=self;
        }
        [cell.contentView addSubview:cellnumber];
        
    }
    
    else if (idx==4) {
        if (passwordtitle==nil) {
            CGRect passwordtitlerect = CGRectMake(LEFT_INDENT, 5, 150, 30);
            passwordtitle = [[UILabel alloc] initWithFrame:passwordtitlerect];
            passwordtitle.text = NSLocalizedStringFromTable(@"Set password", @"InfoPlist",@"comment");
            passwordtitle.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
            passwordtitle.textColor=[UIColor colorWithRed:0.012f green:0.66f blue:0.95 alpha:1.0f];
            
        }
        [cell.contentView addSubview:passwordtitle];
        
        if (passwordone==nil) {
            CGRect pwdonerect = CGRectMake(LEFT_INDENT, 35, cellwidth-LEFT_INDENT-RIGHT_INDENT, 40);
            passwordone = [[UITextField alloc] initWithFrame:pwdonerect];
            passwordone.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
            passwordone.textColor=[UIColor darkGrayColor];
            passwordone.delegate=self;
            passwordone.borderStyle = UITextBorderStyleRoundedRect;
            passwordone.secureTextEntry=YES;
            
        }
        [cell.contentView addSubview:passwordone];
        
    }
    else if (idx==5) {
        if (passwordtwo==nil) {
            CGRect pwdtworect = CGRectMake(LEFT_INDENT, 5, cellwidth-LEFT_INDENT-RIGHT_INDENT, 40);
            passwordtwo = [[UITextField alloc] initWithFrame:pwdtworect];
            passwordtwo.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
            passwordtwo.textColor=[UIColor darkGrayColor];
            passwordtwo.delegate=self;
            passwordtwo.borderStyle = UITextBorderStyleRoundedRect;
            passwordtwo.secureTextEntry=YES;
            
        }
        [cell.contentView addSubview:passwordtwo];
        
    }
    else {
        //the submit button;
        if (submit==nil) {
            CGRect submitrect = CGRectMake(LEFT_INDENT, 5, cellwidth-LEFT_INDENT-RIGHT_INDENT, 40);
            submit=[UIButton buttonWithType:UIButtonTypeRoundedRect];
            [submit setFrame:submitrect];
            NSString* btnTitle = NSLocalizedStringFromTable(@"Submit", @"InfoPlist",@"comment");
            [submit setTitle:btnTitle forState:UIControlStateNormal];
            [submit setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [submit setBackgroundColor:[UIColor colorWithRed:0.012 green:0.612 blue:0.992 alpha:1.0]];
            
            [submit addTarget:self action:@selector(submitPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        [cell.contentView addSubview:submit];
        
    }
    
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
