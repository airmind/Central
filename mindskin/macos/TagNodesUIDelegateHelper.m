//
//  TagNodesUIDelegateHelper.m
//  MindSkin
//
//  Created by ning roland on 12/22/17.
//

#import "TagNodesUIDelegateHelper.h"

@implementation TagNodesUIDelegateHelper

+(TagNodesUIDelegateHelper*) sharedInstance{
    static TagNodesUIDelegateHelper* sharedInstance;
    
    @synchronized(self)
    {
        if (!sharedInstance) {
            sharedInstance = [[TagNodesUIDelegateHelper alloc] init];
        }
        
        return sharedInstance;
    }
    
}

-(void) waitforTagNodeReady:(NSDictionary*)uiDelegateItem {
    [uidelegatewaitinglist addObject:uiDelegateItem];
}

-(id) tagNodeReady:(int)componentid {
    //nodeUIDelegate = delegate;
    id delegate;
    //loop through waiting list to find matching ui delegate;
    for (NSDictionary* item in uidelegatewaitinglist) {
        
        int cid = [item objectForKey:@"component_id"];
        if (cid == componentid) {
            delegate = [item objectForKey:@"delegate_controller"];
            return delegate;
        }
        
    }
    return NULL;
}

-(void) setTagNodeUIContainer:(id)container {
    nodeUIContainer = container;
}


@end
