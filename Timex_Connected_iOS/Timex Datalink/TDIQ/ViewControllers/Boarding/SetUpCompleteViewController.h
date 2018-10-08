//
//  SetUpCompleteViewController.h
//  Timex
//
//  Created by kpasupuleti on 5/4/16.
//

#import <UIKit/UIKit.h>

@interface SetUpCompleteViewController : UIViewController {
    IBOutlet UILabel *infoLabel;
    IBOutlet NSLayoutConstraint *infoLblTopConstraint;
    IBOutlet NSLayoutConstraint *leftConstraint;
    IBOutlet NSLayoutConstraint *infoLblBottomContraint;
    IBOutlet UILabel *progressLbl;
    IBOutlet NSLayoutConstraint *progressLblWidthContraint;
    IBOutlet UIButton *nexButton;
    IBOutlet UILabel *remeberToSyncLabel;
    IBOutlet NSLayoutConstraint *bottomViewTopContraint;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil skippedCalibration:(BOOL)isSkipped;

@end
