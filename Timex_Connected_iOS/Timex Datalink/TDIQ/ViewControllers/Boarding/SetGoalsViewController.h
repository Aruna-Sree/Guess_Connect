//
//  SetGoalsViewController.h
//  Timex
//
//  Created by avemulakonda on 5/4/16.
//

#import <UIKit/UIKit.h>
#import "TDRootViewController.h"

@interface SetGoalsViewController : UIViewController<UITableViewDelegate, UITableViewDataSource,UITextFieldDelegate>
{
    IBOutlet UIButton *activeBtn;
    IBOutlet UIButton *prettyActiveBtn;
    IBOutlet UIButton *veryActiveBtn;
    IBOutlet UIButton *nextBtn;
    
    IBOutlet UILabel *infoTextLbl;
    IBOutlet UILabel *progressLbl;
    IBOutlet UITableView *goalsTableView;
    
    IBOutlet NSLayoutConstraint *infoTextLblTopConstraint;
    IBOutlet NSLayoutConstraint *infoTextLblLeftConstraint;
    IBOutlet NSLayoutConstraint *infoTextLblRightContraint;
    IBOutlet NSLayoutConstraint *infoTextLblHeightContraint;
    IBOutlet NSLayoutConstraint *infoTextLblBottomContraint;
    
    IBOutlet NSLayoutConstraint *progressLblWidthContraint;
    IBOutlet NSLayoutConstraint *nextButtonBottomContraint;
    
    IBOutlet NSLayoutConstraint *btnsViewBottomConstrait;
    IBOutlet NSLayoutConstraint *goalsTypeViewWidthConstraint;
}

@property (nonatomic ) BOOL notOpenedByMenu;

@end
