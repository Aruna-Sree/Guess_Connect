//
//  CustomAlertButton.m
//  timex
//
//  Created by Raghu on 16/01/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import "CustomAlertButton.h"

@implementation CustomAlertButton
{
    void(^actionBlock)(void);
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(id)initWithTitle:(NSString *)title andActionBlock:(void (^ __nullable)(void))block
{
    self = [super init];
    [self setTitle:title forState:UIControlStateNormal];
    [self.titleLabel setFont:[UIFont boldSystemFontOfSize:15]];
    [self setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    actionBlock = block;
    
    return self;
    
}

-(void)performAlertButtonClickAction
{
    actionBlock();
}

@end
