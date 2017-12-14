//
//  FCUSummaryViewController.m
//  MindSkin
//
//  Created by ning roland on 11/13/17.
//
//

#import "FCUSummaryViewController.h"
#include "MAVLinkProtocol.h"

@interface FCUSummaryViewController ()

@end

@implementation FCUSummaryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // get parameter loader instance;
    paramhelper = [ParameterLoadHelper_objc sharedInstance];
    
    //set delegation;
    [paramhelper setParameterLoadDelegate: self];
    
    //issue fetch all parameter command;
    paraProgressView.progress = 0.0f;
    [paramhelper refreshAllParameters:MAV_COMP_ID_ALL];
}


-(void)parameterLoadHelper:(ParameterLoadHelper_objc*)paramhelper progressUpdate:(float)progress {
    //update progress bar;
    [paraProgressView setProgress:progress animated:YES];


}

-(void)parameterLoadHelper:(ParameterLoadHelper_objc*)paramhelper parameterReadyChanged:(BOOL)yon {
    //update displayed params;
    if (yon == YES) {
        //parse params, get airframe type;
    }
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
