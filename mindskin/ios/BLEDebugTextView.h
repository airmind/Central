//
//  BLEDebugTextView.h
//  qgroundcontrol
//
//  Created by ning roland on 1/29/16.
//
//

#ifndef qgroundcontrol_BLEDebugTextView_h
#define qgroundcontrol_BLEDebugTextView_h

class BLEDebugTextViewWrapper;

class BLEDebugTextView {
    //Q_OBJECT
    
private:
    BLEDebugTextViewWrapper* debugwrapper;
    bool presented;
    
public:
    BLEDebugTextView();
    ~BLEDebugTextView();
    void presentDebugView();
    void dismissDebugView();
    
    void addline(QString & msg);
    void clearview();
    
    bool isPresented();
    
    //NSString* QString2NSString (const QString* qstr);
    
    
    void peripheralsDiscovered(void* inrangelist, void* outrangelist);
};

#endif
