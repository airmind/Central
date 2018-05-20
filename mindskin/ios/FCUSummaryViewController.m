//
//  FCUSummaryViewController.m
//  MindSkin
//
//  Created by ning roland on 11/13/17.
//
//

#import "FCUSummaryViewController.h"
//#include "MAVLinkProtocol.h"

@interface FCUSummaryViewController ()

@end

@implementation FCUSummaryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    paraProgressView.progress = 0.0f;
}

-(void)setParameterHelper:(ParameterLoadHelper_objc*)paramHelper {
    m_paramhelper = paramHelper;
}

-(void)parameterProgressUpdate:(float)progress {
    [paraProgressView setProgress:progress animated:YES];
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
