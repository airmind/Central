//
//  tagNodeInfoViewController.m
//  MindSkin
//
//  Created by ning roland on 11/13/17.
//
//

#import "tagNodeInfoViewController.h"
#import "TagNodesUIDelegateHelper.h"
#import "FCUSummaryViewController.h"

@interface tagNodeInfoViewController ()

@end

@implementation tagNodeInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    // get parameter loader instance;
    
    //view controller, target component id, component type;
    NSString * key1 =@"delegate_controller";
    NSString * key2 =@"component_id";
    NSString * key3 =@"component_type";
    
    NSNumber* cid = [NSNumber numberWithInt:-1];
    NSNumber* ctype = [NSNumber numberWithInt:-1];

    NSDictionary* item = [[NSDictionary alloc]
                                initWithObjectsAndKeys:self,key1,cid,key2,ctype,key3,nil] ;
    
    [[TagNodesUIDelegateHelper sharedInstance] waitforTagNodeReady:item];
    
    // get all child controllers and pass paramhelper instance.
    NSArray* ctrlarray = [self viewControllers];
    for (UIViewController* vc in ctrlarray) {
        [vc setParameterHelper:param_helper];
    }
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
-(void)parameterLoadHelper:(ParameterLoadHelper_objc*)paramhelper progressUpdate:(float)progress {
    //update progress bar;
    FCUSummaryViewController* fcucontroller = (FCUSummaryViewController*)[[self viewControllers] objectAtIndex:0];
    [fcucontroller parameterProgressUpdate:progress];
    
}

-(void)parameterLoadHelper:(ParameterLoadHelper_objc*)paramhelper parameterReadyChanged:(BOOL)yon {
    //update displayed params;
    if (yon == YES) {
        //parse params, get airframe type;
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
-(void)setParameterHelper:(ParameterLoadHelper_objc*)paramHelper {
    param_helper = paramHelper;
}


-(void) setNodeLinkConfigration:(BTSerialConfiguration_objc*)btc_objc {
    tagNodeLinkConfig = btc_objc;
}


-(BTSerialConfiguration_objc*) getNodeLinkConfiguration {
    return tagNodeLinkConfig;
}



@end
