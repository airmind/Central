//
//  MindStickButton.h
//  qgroundcontrol
//
//  Created by ning roland on 12/22/15.
//
//

#ifndef __qgroundcontrol__MindStickButton__
#define __qgroundcontrol__MindStickButton__

#include <stdio.h>

class MindStickButtonWrapper;

class MindStickButton {
private:
    MindStickButtonWrapper* mswrapper;
    
public:
    MindStickButton();
    ~MindStickButton();
    
    void showButton();
    void removeButton();
    void enable();
    void disable();
    void updateStatus();
    void linkRSSIUpdated(void* list);
    
};

#endif /* defined(__qgroundcontrol__MindStickButton__) */
