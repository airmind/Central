//
//  ConnectPopoverWrapper.h
//  qgroundcontrol
//
//  Created by ning roland on 11/11/15.
//
//

#ifndef qgroundcontrol_ConnectPopoverWrapper_h
#define qgroundcontrol_ConnectPopoverWrapper_h

class ConnectPopoverWrapper;

class ConnectPopover{
private:
    ConnectPopoverWrapper* popoverwrapper;
    
public:
    ConnectPopover();
    ~ConnectPopover();
    void presentPopover(QStringList connectionlist);
    void dismissPopover();
    //NSString* QString2NSString (const QString* qstr);
};


#endif
