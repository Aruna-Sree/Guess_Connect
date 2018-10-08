//
//  DayButton.m
//  Timex
//
//  Created by Aruna Kumari Yarra on 02/06/16.
//

#import "DayButton.h"
#import "TDDefines.h"

@implementation DayButton
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


- (void)setSelected:(BOOL)selected {
    
    [super setSelected:selected];
    
    if (selected) {
        self.layer.borderColor = UIColorFromRGB(AppColorRed).CGColor;
    } else {
        self.layer.borderColor = UIColorFromRGB(MEDIUM_GRAY_COLOR).CGColor;
    }
}


@end
