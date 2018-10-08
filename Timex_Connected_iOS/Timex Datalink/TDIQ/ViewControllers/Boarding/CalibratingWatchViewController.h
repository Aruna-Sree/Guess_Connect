//
//  CalibratingWatchViewController.h
//  Timex
//
//  Created by kpasupuleti on 5/4/16.
//

#import <UIKit/UIKit.h>
#import "TDRootViewController.h"

@interface CalibratingWatchViewController : UIViewController<UITabBarDelegate, UITableViewDataSource, UIAlertViewDelegate> {
    IBOutlet UILabel *infoLabel;
    IBOutlet UILabel *progressLbl;
    
    IBOutlet NSLayoutConstraint *infoLblTopConstraint;
    IBOutlet NSLayoutConstraint *infoLblleftConstraint;
    IBOutlet NSLayoutConstraint *infoLblRightConstraint;
    IBOutlet NSLayoutConstraint *infoLblBottomContraint;
    
    IBOutlet NSLayoutConstraint *progressLblWidthContraint;
    
    IBOutlet UILabel *syncCover;
    IBOutlet UILabel *syncLbl;
    IBOutlet UIView *syncView;
    IBOutlet UIImageView *watchSetup;
    IBOutlet UITableView *calibrateTableView;
    IBOutlet UIActivityIndicatorView *activityIndicator;
    IBOutlet UIActivityIndicatorView *syncViewActivityIndicator;
    IBOutlet NSLayoutConstraint *indicatorTopConstraint;

}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil doSettingsMenuCalibration:(BOOL)isFromSettings ;
-(void)showSlideMenuIcon;
@property (nonatomic) BOOL openCalibration;
@end
