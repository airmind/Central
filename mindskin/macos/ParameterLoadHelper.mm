//
//  ParameterLoadHelper.m
//  MindSkin
//
//  Created by ning roland on 11/10/17.
//
//

#import <Foundation/Foundation.h>
#import "ParameterLoadHelper_objc.h"
#import "TagNodesUIDelegateHelper.h"

#include <QString>
#include "qt2ioshelper.h"
#include "QGCApplication.h"
#include "BTSerialLink.h"
#include "ParameterLoadHelper.h"
#include "ParameterManager.h"

#pragma - implementation ParameterLoadHelper_objc

@interface ParameterLoadHelper_objc ()  {
    ParameterManager* refParamManager;
    
}

@end

@implementation ParameterLoadHelper_objc

/*
+(ParameterLoadHelper_objc*)sharedInstance{
    static ParameterLoadHelper_objc* sharedInstance;
    
    @synchronized(self)
    {
        if (!sharedInstance) {
            sharedInstance = [[ParameterLoadHelper_objc alloc] init];
        }
        
        return sharedInstance;
    }
    
}*/

//register callback delegate for update;
-(void) setParameterLoadDelegate:(id)delegate {
    param_delegate = delegate;
}

//get parameter list;

-(void) refreshAllParameters:(int)componentid {
    
    if (refParamManager == nil) {
        //BTSerialConfiguration_objc* btc = [node getNodeLinkConfiguration];
        //QGC not support multiple vehicles yet. use activeVehicle for the moment;
        refParamManager = qgcApp()->toolbox()->multiVehicleManager()->activeVehicle()->parameterManager();
    }
    
    param_delegate = [[TagNodesUIDelegateHelper sharedInstance] tagNodeReady:componentid];
    [param_delegate setParameterHelper:self];
    
    //refParamManager->paramLoadHelper()->setParameterLoadDelegate(self);

    refParamManager->refreshAllParameters();
}

/*
-(void) refreshAllParameters:(BTSerialConfiguration_objc*)cfg {
    refParamManager->refreshAllParameters();

}
*/

/// Request a refresh on the specific parameter
-(void) refreshParameter:(int) componentId paramName: (NSString*)name {
    refParamManager->refreshParameter(componentId, QString::fromNSString(name));

}

-(void)notifyParameterProgress : (float)progress {
    [param_delegate parameterLoadHelper:self progressUpdate:progress];
}


-(void)parameterReadyChanged:(BOOL)yon {
    [param_delegate parameterLoadHelper:self parameterReadyChanged:yon];
}


-(BOOL)paramSetupComplete {
    //call QGC setup complete;
    
}


@end

#pragma - definition and implementation ParameterLoadHelperWrapper

class ParameterLoadHelperWrapper {
    ParameterLoadHelper_objc* paraHelper_objc;
public:
    ParameterLoadHelperWrapper();
    ~ParameterLoadHelperWrapper();
    
    void setCallbackDelegate(void*);
    void notifyParameterProgress(float progress);

    void parameterUpdate(int vehicleId, int componentId, int mavType, QString parameterName, int parameterCount, int parameterIndex,  QVariant value, QString shortDesc, QString longDesc, QString unit, QVariant defaultValue) ;
    void _parameterUpdate(int vehicleId, int componentId, QString parameterName, int parameterCount, int parameterId, int mavType, QVariant value);
    
    void parameterReadyChanged(bool yon);
    void refreshAllParameters(int componentid);
    

};

ParameterLoadHelperWrapper::ParameterLoadHelperWrapper(){
    paraHelper_objc = [[ParameterLoadHelper_objc alloc] init];
    
}

ParameterLoadHelperWrapper::~ParameterLoadHelperWrapper() {
}


void ParameterLoadHelperWrapper::setCallbackDelegate(void* delegate) {
    [paraHelper_objc setParameterLoadDelegate:(__bridge id)delegate];
    
}

void ParameterLoadHelperWrapper::notifyParameterProgress(float progress) {
    if (nil != paraHelper_objc) {
        [paraHelper_objc notifyParameterProgress:progress];
    }
}

void ParameterLoadHelperWrapper::parameterReadyChanged(bool yon) {
    if (nil != paraHelper_objc) {
        [paraHelper_objc parameterReadyChanged:yon];
    }
    
}

void ParameterLoadHelperWrapper::refreshAllParameters(int componentid) {
    if (nil != paraHelper_objc) {
        [paraHelper_objc refreshAllParameters:componentid];
    }

}


#pragma - implementation ParameterLoadHelper

ParameterLoadHelper::ParameterLoadHelper(){
    parahelper_wrapper = new ParameterLoadHelperWrapper();
    
}

ParameterLoadHelper::~ParameterLoadHelper() {
    if (parahelper_wrapper != NULL) {
        delete parahelper_wrapper;
    }
}

void ParameterLoadHelper::refreshAllParameters(int componentid) {
    parahelper_wrapper->refreshAllParameters(componentid);
}

void ParameterLoadHelper::setParameterLoadDelegate(void* delegate) {
    parahelper_wrapper->setCallbackDelegate(delegate);
}

void ParameterLoadHelper::notifyParameterProgress(float progress) {
    parahelper_wrapper->notifyParameterProgress(progress);
}

void ParameterLoadHelper::parameterReadyChanged(bool yon) {
    parahelper_wrapper->parameterReadyChanged(yon);

}



