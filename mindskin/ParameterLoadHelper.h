//
//  ParameterLoadHelper.h
//  MindSkin
//
//  Created by ning roland on 11/22/17.
//
//

#ifndef ParameterLoadHelper_h
#define ParameterLoadHelper_h


#ifdef __ios__
class ParameterLoadHelperWrapper;
#endif


class ParameterLoadHelper {
private:
#ifdef __ios__
    ParameterLoadHelperWrapper* parahelper_wrapper;
#endif
    
public:
    
    ParameterLoadHelper();
    ~ParameterLoadHelper();
    
    //register callback delegate for update;
    -(void)setParameterLoadDelegate:(id)delegate;
    
    //send progress notification;
    -(void)notifyParameterProgress(float progress);
    
    //init load parameter finished and ready;
    void parameterReadyChanged(bool yon);
    
    //get parameter list;
    //-(void) refreshAllParameters:(LinkConfiguration)cfg;
    //-(void) refreshAllParameters:(BTLinkConfiguration)cfg;

    
};


#endif /* ParameterLoadHelper_h */
