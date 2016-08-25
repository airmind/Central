//
//  RacerMainMenuView.m
//  QGroundControl
//
//  Created by ning roland on 8/22/16.
//
//

#import "RacerMainMenuView.h"

@implementation RacerMainMenuView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


-(void)layoutSubviews {
    // spread the menu at equal width and space;
    
    /// get frame size;
    CGRect viewframe = self.frame;
    
    /// calc space and width;
    int margin = 20;
    int space = 20;
    
    int width = (viewframe.size.width - margin*2 - space*3) / 4;
    
    CGRect m1frame, m2frame, m3frame, m4frame;
    
    m1frame.origin.x = margin;
    m1frame.size.width = width;
    
    m2frame.origin.y = m1frame.origin.x + width + space;
    m2frame.size.width = width;
    
    m3frame.origin.x = m2frame.origin.x + (width + space);
    m3frame.size.width = width;
    
    m4frame.origin.x = m3frame.origin.x + (width + space);
    m4frame.size.width = width;
    
    m1.frame = m1frame;
    m2.frame = m2frame;
    m3.frame = m3frame;
    m4.frame = m4frame;
    
    //set other icons;
    

}



@end
