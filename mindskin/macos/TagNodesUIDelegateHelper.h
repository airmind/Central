//
//  TagNodesUIDelegateHelper.h
//  MindSkin
//
//  Created by ning roland on 12/22/17.
//

#import <Foundation/Foundation.h>

@interface TagNodesUIDelegateHelper : NSObject {
    //uiviewcontroller;
    id nodeUIDelegate;
    
    //container view controller;
    id nodeUIContainer;
    
    //waiting list of ui delegates;
    NSMutableArray* uidelegatewaitinglist;
}

+(TagNodesUIDelegateHelper*) sharedInstance;
-(void) setTagNodeUIDelegate:(id)delegate;
-(void) setTagNodeUIContainer:(id)container;
-(void) waitforTagNodeReady:(NSDictionary*)uiDelegateItem;

@end
