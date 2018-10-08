//
//  SetupWatchViewController.h
//  Timex
//
//  Created by avemulakonda on 5/4/16.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface SetupWatchViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, MBProgressHUDDelegate> {
    IBOutlet UILabel *infoLabel;
    IBOutlet UILabel *progressLbl;
    
    IBOutlet NSLayoutConstraint *infoLblTopConstraint;
    IBOutlet NSLayoutConstraint *infoLblleftConstraint;
    IBOutlet NSLayoutConstraint *infoLblBottomContraint;
    IBOutlet NSLayoutConstraint *infoLblRightConstraint;
    
    IBOutlet NSLayoutConstraint *progressLblWidthContraint;
    
    IBOutlet UIImageView *watchSetup;
    IBOutlet UITableView *watchListTableView;
    IBOutlet UIActivityIndicatorView *activityIndicator;
    IBOutlet NSLayoutConstraint *indicatorTopConstraint;
}

@property (nonatomic ) BOOL openedByMenu;

@end
