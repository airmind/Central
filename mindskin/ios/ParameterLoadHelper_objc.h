//
//  ParameterLoadHelper.h
//  MindSkin
//
//  Created by ning roland on 11/10/17.
//
//

#ifndef ParameterLoadHelper_h
#define ParameterLoadHelper_h

#include "ParameterLoadHelper.h"

@class ParameterLoadHelper_objc;

@protocol UIParameterLoadProgressDelegate <NSObject>

@required
-(void)parameterLoadHelper:(ParameterLoadHelper_objc*)paramhelper progressUpdate:(float)progress;
-(void)parameterLoadHelper:(ParameterLoadHelper_objc*)paramhelper parameterReadyChanged:(BOOL)yon;

@optional
@end;


@interface ParameterLoadHelper_objc : NSObject {
    id <UIParameterLoadProgressDelegate> param_delegate;
}

+(ParameterLoadHelper_objc*)sharedInstance;

//register callback delegate for update;
-(void)setParameterLoadDelegate:(id)delegate;

//get parameter list;
-(void) refreshAllParameters:(LinkConfiguration)cfg;
-(void) refreshAllParameters:(BTLinkConfiguration)cfg;
/// Request a refresh on the specific parameter
-(void) refreshParameter:(int) componentId paramName: (NSString*)name;

-(void)notifyParameterProgress:(float)progress;

-(BOOL)paramSetupComplete;

public static void refreshAllFlightParameters(String linkConfigName){
    if(controller != null){
        refreshAllParameters(linkConfigName);
    }else{
        //throw new NullPointerException("ParametersController is NULL in ParameterManager. " +
        //        "Must implement 'IParametersController' interface and call setController() before refreshing parameters.");
    }
}



@end


#endif /* ParameterLoadHelper_h */
