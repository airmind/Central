//
//  MindSkinRootView.h
//  qgroundcontrol
//
//  Created by ning roland on 6/16/16.
//
//

#ifndef qgroundcontrol_MindSkinRootView_h
#define qgroundcontrol_MindSkinRootView_h


class MindSkinRootView_wrapper;

class MindSkinRootView {
    
private:
    
 
#ifdef __ios__
    MindSkinRootView_wrapper* skinroot_wrapper;
    
    
    
#endif
    
#ifdef __android__
    
#endif
    
    
    //private constructor;
    MindSkinRootView();
    
public:
    static MindSkinRootView* sharedInstance();
    void launchMindskinUI();
    void shutdown();
    
};


#endif
