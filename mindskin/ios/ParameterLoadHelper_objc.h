//
//  ParameterLoadHelper.h
//  MindSkin
//
//  Created by ning roland on 11/10/17.
//
//

#ifndef ParameterLoadHelper_objc_h
#define ParameterLoadHelper_objc_h

#import <UIKit/UIKit.h>
//#include "ParameterLoadHelper.h"
//#import "tagNodeInfoViewController.h"
#import "BTSerialLink_objc.h"

@class ParameterLoadHelper_objc;

@protocol UIParameterLoadProgressDelegate <NSObject>

@required
-(void)parameterLoadHelper:(ParameterLoadHelper_objc*)paramhelper progressUpdate:(float)progress;
-(void)parameterLoadHelper:(ParameterLoadHelper_objc*)paramhelper parameterReadyChanged:(BOOL)yon;

@optional
@end;


@interface ParameterLoadHelper_objc : NSObject {
    id <UIParameterLoadProgressDelegate> param_delegate;
    //ParameterManager* refParamManager;
    
}

-(ParameterLoadHelper_objc*)initForTagNode:(UIViewController*)node ;

//register callback delegate for update;
-(void)setParameterLoadDelegate:(id)delegate;

//get parameter list;
//-(void) refreshAllParameters:(LinkConfiguration)cfg;
-(void) refreshAllParameters:(int)componentid;
/// Request a refresh on the specific parameter
-(void) refreshParameter:(int) componentId paramName: (NSString*)name;

-(void)notifyParameterProgress:(float)progress;

-(void)parameterReadyChanged:(BOOL)yon;

-(BOOL)paramSetupComplete;
/*
public static void refreshAllFlightParameters(String linkConfigName){
    if(controller != null){
        refreshAllParameters(linkConfigName);
    }else{
    }
}

*/

@end


#endif /* ParameterLoadHelper_objc_h */
