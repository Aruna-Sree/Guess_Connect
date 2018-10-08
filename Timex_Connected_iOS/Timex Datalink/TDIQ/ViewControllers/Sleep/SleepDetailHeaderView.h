//
//  SleepDetailHeaderView.h
//  Timex
//
//  Created by Aruna Kumari Yarra on 26/05/16.
//  Copyright © 2016 innominds. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SleepDetailHeaderView : UIView
@property (nonatomic, strong) IBOutlet UILabel *totalTimeLbl;
@property (nonatomic, strong) IBOutlet UILabel *startTimeLbl;
@property (nonatomic, strong) IBOutlet UILabel *endTimeLbl;
@property (nonatomic, strong) IBOutlet UIView *progressView;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *totalLblHeightConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *totalLblWidthConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *leftLblWidthConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *rightLblWidthConstraint;
- (void)setStartTimeWithText:(NSString *)textStr;
- (void)setEndTimeWithText:(NSString *)textStr;
- (void)setTotalTimeWithText:(NSString *)textStr;
@end
