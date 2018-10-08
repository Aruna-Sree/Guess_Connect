//
//  UpdateFirmwareViewController.h
//  Timex
//
//  Created by avemulakonda on 5/4/16.
//

#import <UIKit/UIKit.h>
#import "MBCircularProgressBarView.h"

@interface UpdateFirmwareViewController : UIViewController {
    IBOutlet UILabel *infoLabel;
    IBOutlet UILabel *progressLbl;
    IBOutlet UILabel *bodyLbl;
    IBOutlet UIButton *laterBtn;
    IBOutlet UIButton *updateBtn;
    IBOutlet UIActivityIndicatorView *indicationView;
    IBOutlet UIButton *okBtn;
    
    IBOutlet UILabel *fileLbl;
    IBOutlet UILabel *alignLbl;
    IBOutlet UILabel *completeLbl;
    IBOutlet UILabel *infoLbl;
    IBOutlet UIImageView *watchProgress;
    IBOutlet UIView *syncView;
    IBOutlet UILabel *syncCover;
    IBOutlet UIImageView *watchSetup;
    IBOutlet NSLayoutConstraint *infoLblTopConstraint;
    IBOutlet NSLayoutConstraint *infoLblleftConstraint;
    IBOutlet NSLayoutConstraint *infoLblBottomContraint;
    IBOutlet NSLayoutConstraint *infoLblRightConstraint;
    IBOutlet NSLayoutConstraint *progressLblWidthContraint;
}

@property (weak, nonatomic) IBOutlet MBCircularProgressBarView *progressBar;
@property (weak, nonatomic) IBOutlet UIButton *tickButton;
@property (assign, nonatomic) CGFloat currentVal;
/**
 *  Dummy timer for checking the upgrade status. Need to remove this once 
 * main thing is implemented.
 */
@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic ) BOOL neededUpdate;
@property (nonatomic ) BOOL openedByMenu;
@property (nonatomic ) BOOL unstickBootloader;
@property (nonatomic ) BOOL retryUpdate;

@end
