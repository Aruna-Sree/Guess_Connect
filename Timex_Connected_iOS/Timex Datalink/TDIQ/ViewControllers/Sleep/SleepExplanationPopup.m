//
//  SleepExplanationPopup.m
//  timex
//
//  Created by Aruna Kumari Yarra on 07/12/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import "SleepExplanationPopup.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"
#import "UIImage+Tint.h"

@implementation SleepExplanationPopup
- (id)initWithFrame:(CGRect)frame {
    
    self = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] objectAtIndex:0];
    self.frame = frame;
    
    popupView.layer.cornerRadius = 5.0f;
    popupView.layer.masksToBounds = YES;
    
    descriptionLbl.font = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:16];
    [titleBtn.titleLabel setFont:[UIFont fontWithName:[iDevicesUtil getAppWideBoldFontName] size:19]];
    if (!tap)
    {
        tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(cancel)];
    }
    [self addGestureRecognizer:tap];
    return self;
}
- (void)cancel {
    [self removeFromSuperview];
}
- (void)setImageNDescriptionBasedOnSleepType:(int)sleepType {
    if (sleepType == 0) { // DeepSleep
        [titleBtn setImage:[[UIImage imageNamed: @"Welcome_Sleep"] imageWithTint:M328_HOME_SLEEP_DARK_COLOR] forState:UIControlStateNormal];
        [titleBtn setTitle:NSLocalizedString(@"Deep Sleep", nil) forState:UIControlStateNormal];
        descriptionLbl.text = NSLocalizedString(@"This measures the amount of time you spend sleeping soundly. During deep sleep, your body moves very little. Seeing more of these cycles means you're getting a good night's sleep.", nil);
    } else if (sleepType == 1) { // LightSleep
        [titleBtn setImage:[[UIImage imageNamed: @"Welcome_Sleep"] imageWithTint:M328_HOME_SLEEP_LIGHT_COLOR] forState:UIControlStateNormal];
        [titleBtn setTitle:NSLocalizedString(@"Light Sleep", nil) forState:UIControlStateNormal];
        descriptionLbl.text = NSLocalizedString(@"This measures the amount of time you spend tossing and turning in bed. During light sleep, your body moves more than you realize. Keeping track of these cycles can help you improve your sleep habits.", nil);
    } else {
        [titleBtn setImage:[[UIImage imageNamed: @"Welcome_Sleep"] imageWithTint:M328_HOME_SLEEP_AWAKE_COLOR] forState:UIControlStateNormal];
        [titleBtn setTitle:NSLocalizedString(@"Awake", nil) forState:UIControlStateNormal];
        descriptionLbl.text = NSLocalizedString(@"This measures the amount of time your sleep was interrupted. You'll see them in events whenever you get up from bed or move around too much.", nil);
    }
}
@end
