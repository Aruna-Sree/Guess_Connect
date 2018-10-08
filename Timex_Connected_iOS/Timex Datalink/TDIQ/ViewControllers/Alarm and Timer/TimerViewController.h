//
//  TimerViewController.h
//  Timex
//
//  Created by Raghu on 08/07/16.
//  Copyright © 2016 innominds. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDRootViewController.h"

@interface TimerViewController : TDRootViewController
{
    NSMutableArray *hoursArray;
    NSMutableArray *minsArray;
    NSMutableArray *secsArray;
    IBOutlet NSLayoutConstraint *startBtnBottomConstraint;
    IBOutlet NSLayoutConstraint *stopBtnBottomConstraint;
    IBOutlet UILabel *headerLbl;
    IBOutlet NSLayoutConstraint *startbtnWidthConstraint;
    IBOutlet NSLayoutConstraint *stopbtnWidthConstraint;
    IBOutlet UIPickerView *supportTextPickerView;
}
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (strong, nonatomic) IBOutlet UILabel *countdownLbl;
@property (strong, nonatomic) IBOutlet UIButton *syncAndStartBtn;
@property (strong, nonatomic) IBOutlet UIButton *syncAndStopBtn;

- (void)countdownTimerStart;
- (void)invalidateTimer;
- (void)timerStarted:(BOOL)start;
@end
