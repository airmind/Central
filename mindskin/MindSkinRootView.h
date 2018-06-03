//
//  MindSkinRootView.h
//  qgroundcontrol
//
//  Created by ning roland on 6/16/16.
//
//

#ifndef qgroundcontrol_MindSkinRootView_h
#define qgroundcontrol_MindSkinRootView_h
#include <QObject>
#include <QString>

class MindSkinRootView_wrapper;

class MindSkinRootView : public QObject {
    
private:

    MindSkinRootView_wrapper* skinroot_wrapper;
#ifdef __android__
    
#endif
    //private constructor;
    MindSkinRootView();
    
public:
    static MindSkinRootView* sharedInstance();
    void launchMindskinUI();
    void shutdown();
    void showMessage(const QString& msg);
    
public slots:
    void showBLEConnectionsView();
    void dismissBLEConnectionsView();

    
};


#endif
