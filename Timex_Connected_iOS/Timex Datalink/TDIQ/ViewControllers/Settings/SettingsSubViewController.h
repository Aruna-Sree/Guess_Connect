//
//  SettingsSubViewController.h
//  Timex
//
//  Created by Aruna Kumari Yarra on 03/06/16.
//

#import <UIKit/UIKit.h>

@interface SettingsSubViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource> {
    IBOutlet UIPickerView *detailPickerView;
    IBOutlet UIDatePicker *ageDatePickerView;
    IBOutlet UITableView *genderTableView;
    IBOutlet UILabel *infoLbl;
    IBOutlet UIView *autoSyncEnableView;
    IBOutlet UILabel *enableLbl;
    IBOutlet UISwitch *autoSyncSwitch;
    IBOutlet NSLayoutConstraint *autoSyncViewHeightConstraint;
}
@property(nonatomic,retain)NSMutableDictionary * user;
@property(nonatomic)NSInteger syncNumber;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil withScreenType:(int)type;
@end
