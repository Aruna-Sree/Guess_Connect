//
//  HeightViewController.h
//  Timex
//
//  Created by avemulakonda on 5/4/16.
//

#import <UIKit/UIKit.h>

@interface HeightViewController : UIViewController<UITextFieldDelegate> {
    IBOutlet UILabel *infoLabel;
    IBOutlet UILabel *progressLbl;
    IBOutlet NSLayoutConstraint *infoLblTopConstraint;
    IBOutlet NSLayoutConstraint *infoLblleftConstraint;
    IBOutlet NSLayoutConstraint *infoLblBottomContraint;
    IBOutlet UIButton *infoButton;
    IBOutlet NSLayoutConstraint *infoBtnBottomContraint;
    IBOutlet NSLayoutConstraint *infoBtnleftConstraint;

    IBOutlet NSLayoutConstraint *dobLblTopContraint;
    
    IBOutlet NSLayoutConstraint *progressLblWidthContraint;
    IBOutlet UITextField *ftTextField,*inTextField;
    IBOutlet UILabel *ftlbl, *inlbl;
}


@end
