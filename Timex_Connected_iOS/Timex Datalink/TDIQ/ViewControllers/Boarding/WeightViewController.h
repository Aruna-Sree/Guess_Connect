//
//  WeightViewController.h
//  Timex
//
//  Created by avemulakonda on 5/4/16.
//

#import <UIKit/UIKit.h>

@interface WeightViewController : UIViewController<UITextFieldDelegate> {
    IBOutlet UILabel *infoLabel;
    IBOutlet UILabel *progressLbl;
    IBOutlet NSLayoutConstraint *infoLblTopConstraint;
    IBOutlet NSLayoutConstraint *infoLblleftConstraint;
    IBOutlet NSLayoutConstraint *infoLblBottomContraint;
    
    IBOutlet NSLayoutConstraint *dobLblTopContraint;
    
    IBOutlet NSLayoutConstraint *progressLblWidthContraint;
    IBOutlet UITextField *weightTextField;
    IBOutlet UILabel *weightlbl;
    
    IBOutlet UIButton *infoBtn;
    IBOutlet NSLayoutConstraint *infoBtnBottomContraint;
    IBOutlet NSLayoutConstraint *infoBtnleftConstraint;
}
- (IBAction)clickedOnInfoBtn:(id)sender;

@end
