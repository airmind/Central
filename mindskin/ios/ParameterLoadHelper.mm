//
//  ParameterLoadHelper.m
//  MindSkin
//
//  Created by ning roland on 11/10/17.
//
//

#import <Foundation/Foundation.h>
#import "ParameterLoadHelper_objc.h"

#include "ParameterLoadHelper.h"
#include "ParameterLoadHelper_objc.h"


#pragma - implementation ParameterLoadHelper_objc

@implementation ParameterLoadHelper_objc

+(ParameterLoadHelper_objc*)sharedInstance{
    static ParameterLoadHelper_objc* sharedInstance;
    
    @synchronized(self)
    {
        if (!sharedInstance) {
            sharedInstance = [[ParameterLoadHelper_objc alloc] init];
        }
        
        return sharedInstance;
    }
    
}


//register callback delegate for update;
-(void)setParameterLoadDelegate:(id)delegate {
    qgcApp()->toolbox()->multiVehicleManager()->getVehicleByLinkConfigName()->parameterManager;
}

//get parameter list;
-(void) refreshAllParameters:(LinkConfiguration)cfg {
    parameterManager->refreshAllParameters();
}

-(void) refreshAllParameters:(BTLinkConfiguration)cfg {
    parameterManager->refreshAllParameters();

}

/// Request a refresh on the specific parameter
-(void) refreshParameter:(int) componentId paramName: (NSString*)name {
    parameterManager->refreshParameter(componentId, name);

}

-(void)notifyParameterProgress : (float)progress {
    [param_delegate parameterLoadHelper:self progressUpdate:progress];
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

    void ParameterManager::parameterUpdate(int vehicleId, int componentId, int mavType, QString parameterName, int parameterCount, int parameterIndex,  QVariant value, QString shortDesc, QString longDesc, QString unit, QVariant defaultValue) ;
    void ParameterManager::_parameterUpdate(int vehicleId, int componentId, QString parameterName, int parameterCount, int parameterId, int mavType, QVariant value);
    

};

ParameterLoadHelperWrapper::ParameterLoadHelperWrapper(){
    paraHelper_objc = [ParameterLoadHelper_objc sharedInstance];
    
}

ParameterLoadHelperWrapper::~ParameterLoadHelperWrapper() {
}


void ParameterLoadHelperWrapper::setCallbackDelegate(void* delegate) {
    [paraHelper_objc setCallbackDelegate:(__bridge id)delegate];
}

void ParameterLoadHelperWrapper::notifyParameterProgress(float progress) {
    [paraHelper_objc notifyParameterProgress:progress];
}

void ParameterLoadHelperWrapper::parameterReadyChanged(bool yon) {
    [paraHelper_objc parameterReadyChanged:yon];
    
}


#pragma - implementation ParameterLoadHelper

ParameterLoadHelper::ParameterLoadHelper(){
    parahelper_wrapper = new ParameterLoadHelperWrapper();
    
}

ParameterLoadHelper::~ParameterLoadHelper() {
    if (ble_wrapper != NULL) {
        delete parahelper_wrapper;
    }
}


void ParameterLoadHelper::setCallbackDelegate(void* delegate) {
    parahelper_wrapper->setCallbackDelegate(delegate);
}

void ParameterLoadHelper::notifyParameterProgress(float progress) {
    parahelper_wrapper->notifyParameterProgress(progress);
}

void ParameterLoadHelper::parameterReadyChanged(bool yon) {
    parahelper_wrapper->parameterReadyChanged(yon);

}



