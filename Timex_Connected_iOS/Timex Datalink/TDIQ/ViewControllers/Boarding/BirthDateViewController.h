//
//  BirthDateViewController.h
//  Timex-iOS
//
//  Created by avemulakonda on 5/4/16.
//

#import <UIKit/UIKit.h>

@interface BirthDateViewController : UIViewController {
    IBOutlet UILabel *infoLabel;
    IBOutlet UILabel *progressLbl;
    IBOutlet UIButton *nextButton;
    IBOutlet NSLayoutConstraint *infoLblTopConstraint;
    IBOutlet NSLayoutConstraint *infoLblleftConstraint;
    IBOutlet NSLayoutConstraint *infoLblBottomContraint;
    IBOutlet UIButton *infoButton;
    IBOutlet NSLayoutConstraint *infoBtnBottomContraint;
    IBOutlet NSLayoutConstraint *infoBtnleftConstraint;
    
    IBOutlet NSLayoutConstraint *dobLblTopContraint;
    IBOutlet NSLayoutConstraint *dobLblBottomContraint;
    
    IBOutlet NSLayoutConstraint *progressLblWidthContraint;
}

@property (weak, nonatomic) IBOutlet UILabel *dobTextLbl;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;

@end
