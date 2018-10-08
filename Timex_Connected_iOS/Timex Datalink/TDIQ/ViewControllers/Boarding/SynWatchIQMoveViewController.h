//
//  TDSynWatchMetropolitanViewController.h
//  Timex
//
//  Created by Diego Santiago on 5/27/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CircleProgressBar.h"

@interface SynWatchIQMoveViewController : UIViewController<UITableViewDataSource>
{
    IBOutlet UILabel *titleLabel;
    IBOutlet UILabel *progressLbl;
    
    IBOutlet CircleProgressBar *mainViewCircleProgress;
    IBOutlet UILabel *percentageLabel;
    IBOutlet UILabel *connectingToWatchLabel;
    
    IBOutlet NSLayoutConstraint *infoLblTopConstraint;
    IBOutlet NSLayoutConstraint *infoLblleftConstraint;
    IBOutlet NSLayoutConstraint *infoLblBottomContraint;
    IBOutlet NSLayoutConstraint *infoLblRightConstraint;
    
    IBOutlet NSLayoutConstraint *progressLblWidthContraint;
    
    IBOutlet UITableView *devicesTableView;

}
@property (nonatomic ) NSObject *watchObject;
@property (nonatomic ) BOOL openedByMenu;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil kickOffSyncAutomatically: (BOOL) autoSyncFlag;

@end
