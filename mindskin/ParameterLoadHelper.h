//
//  ParameterLoadHelper.h
//  MindSkin
//
//  Created by ning roland on 11/22/17.
//
//

#ifndef ParameterLoadHelper_h
#define ParameterLoadHelper_h

class ParameterLoadHelperWrapper;

class ParameterLoadHelper {
private:

    ParameterLoadHelperWrapper* parahelper_wrapper;
    
public:
    
    ParameterLoadHelper();
    ~ParameterLoadHelper();
    
    //register callback delegate for update;
    void setParameterLoadDelegate(void* delegate);
    
    //send progress notification;
    void notifyParameterProgress(float progress);
    
    //init load parameter finished and ready;
    void parameterReadyChanged(bool yon);
    
    //get parameter list;
    void refreshAllParameters(int componentid);
    //-(void) refreshAllParameters:(BTLinkConfiguration)cfg;

    
};


#endif /* ParameterLoadHelper_h */
