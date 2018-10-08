//
//  NameViewController.h
//  Timex-iOS
//
//  Created by kpasupuleti on 5/4/16.
//

#import <UIKit/UIKit.h>

@interface NameViewController : UIViewController<UITextFieldDelegate> {
    IBOutlet UILabel *infoLabel;
    IBOutlet UILabel *progressLbl;
    IBOutlet UITextField *nameTextField;
    IBOutlet UIButton *femaleBtn;
    IBOutlet UIButton *maleBtn;
    IBOutlet UIButton *infoBtn;
    IBOutlet UIButton *nextButton;
    
    IBOutlet NSLayoutConstraint *infoLblTopConstraint;
    IBOutlet NSLayoutConstraint *infoLblleftConstraint;
    IBOutlet NSLayoutConstraint *infoLblBottomContraint;
    
    IBOutlet NSLayoutConstraint *infoBtnBottomContraint;
    IBOutlet NSLayoutConstraint *infoBtnleftConstraint;
    
    IBOutlet NSLayoutConstraint *fieldViewTopContraint;
    IBOutlet NSLayoutConstraint *fieldViewWidthContraint;
    
    IBOutlet NSLayoutConstraint *progressLblWidthContraint;
}

@end


