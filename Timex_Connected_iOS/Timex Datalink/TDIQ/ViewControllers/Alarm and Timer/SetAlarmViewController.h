//
//  SetAlarmViewController.h
//  Timex
//
//  Created by Aruna Kumari Yarra on 02/06/16.
//

#import <UIKit/UIKit.h>
#import "DayButton.h"
#import "TDRootViewController.h"

//#import "Alarm.h"

@protocol SetAlarmDelegate
-(void)alarmSaved;
@end
@interface SetAlarmViewController : TDRootViewController </*UIPickerViewDelegate, UIPickerViewDataSource,*/ UIAlertViewDelegate>{
    IBOutlet UIView *daysView;
    IBOutlet UIDatePicker *timePicker;
    IBOutlet UILabel *alarmTitle;
    IBOutlet UIButton *btnSetSync;
    IBOutlet UISwitch *switchOnOff;
    //NSMutableArray * alarmFrequencyArray;
    __weak IBOutlet UIPickerView *alarmFrequencyPicker;
    IBOutlet UILabel *headerLbl;
    
    IBOutlet NSLayoutConstraint *btnWidthConstraint;
    IBOutlet NSLayoutConstraint *btnBottomConstraint;
    
}
@property(nonatomic,weak) id<SetAlarmDelegate>delegate;
- (IBAction)clickedOnDayButton:(DayButton *)sender;
- (IBAction)clickedOnSetSyncButton:(UIButton *)sender;
- (IBAction)clickedOnSwitch:(id)sender;
@end
