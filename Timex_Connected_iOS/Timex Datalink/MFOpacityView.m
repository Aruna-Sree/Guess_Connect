//
//  MFOpacityView.m
//  Timex
//
//  Created by Naresh Kumar Devalapally on 2/15/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import "MFOpacityView.h"

@implementation MFOpacityView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self) return nil;
    return hitView;
}

@end
