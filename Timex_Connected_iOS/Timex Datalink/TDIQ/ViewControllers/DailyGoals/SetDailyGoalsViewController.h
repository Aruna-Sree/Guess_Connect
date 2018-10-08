//
//  SetDailyGoalsViewController.h
//  Timex
//
//  Created by kpasupuleti on 5/4/16.
//

#import <UIKit/UIKit.h>
#import "GoalsCell.h"
#import "TDRootViewController.h"
@interface SetDailyGoalsViewController : TDRootViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate> {
    IBOutlet UITableView *tblView;
    IBOutlet UIButton *activeBtn;
    IBOutlet UIButton *prettyActiveBtn;
    IBOutlet UIButton *veryActiveBtn;
    IBOutlet UIView *goalsTypeView;
    IBOutlet UILabel *headerLbl;
    IBOutlet NSLayoutConstraint *goalsTypeViewWidthConstraint;
}
@end
