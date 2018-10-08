//
//  SettingsViewController.h
//  Timex
//
//  Created by kpasupuleti on 5/4/16.
//

#import <UIKit/UIKit.h>
#import "TDRootViewController.h"
#import "SettingsSubViewController.h"
#import "BLEManager.h"

@interface SettingsViewController : TDRootViewController<UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, UITextFieldDelegate> {
    NSArray *settingsItems;
    IBOutlet NSLayoutConstraint *tableViewBottomConstraint;
    BLEManager*   bleManager;

}

@property (weak ,nonatomic) IBOutlet UITableView *settingsTableView;

@end
