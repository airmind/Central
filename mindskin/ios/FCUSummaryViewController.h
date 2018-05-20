//
//  FCUSummaryViewController.h
//  MindSkin
//
//  Created by ning roland on 11/13/17.
//
//

#import <UIKit/UIKit.h>
#import "ParameterLoadHelper_objc.h"

@interface FCUSummaryViewController : UIViewController  {
    IBOutlet UILabel* primAccl;
    IBOutlet UILabel* primAccl_status;
    IBOutlet UILabel* primGyro;
    IBOutlet UILabel* primGyro_status;
    IBOutlet UILabel* primMag;
    IBOutlet UILabel* primMag_status;
    
    IBOutlet UILabel* secAccl;
    IBOutlet UILabel* secAccl_status;
    IBOutlet UILabel* secGyro;
    IBOutlet UILabel* secGyro_status;
    IBOutlet UILabel* secMag;
    IBOutlet UILabel* secMag_status;
    
    IBOutlet UIProgressView* paraProgressView;
    
    ParameterLoadHelper_objc* m_paramhelper;
    
    
}

-(void)setParameterHelper:(ParameterLoadHelper_objc*)paramHelper;
-(void)parameterProgressUpdate:(float)progress;

@end
