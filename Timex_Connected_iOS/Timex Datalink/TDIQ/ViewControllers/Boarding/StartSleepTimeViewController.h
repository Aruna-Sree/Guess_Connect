//
//  BirthDateViewController.h
//  Timex-iOS
//
//  Created by avemulakonda on 5/4/16.
//

#import <UIKit/UIKit.h>

@interface StartSleepTimeViewController : UIViewController {
    IBOutlet UILabel *infoLabel;
    IBOutlet UILabel *progressLbl;
    IBOutlet UIButton *nextButton;
    IBOutlet NSLayoutConstraint *infoLblTopConstraint;
    IBOutlet NSLayoutConstraint *infoLblleftConstraint;
    IBOutlet NSLayoutConstraint *infoLblBottomContraint;
    
    IBOutlet NSLayoutConstraint *progressLblWidthContraint;
    
    IBOutlet UIButton *infoBtn;
    IBOutlet NSLayoutConstraint *infoBtnBottomContraint;
    IBOutlet NSLayoutConstraint *infoBtnleftConstraint;
    
    IBOutlet NSLayoutConstraint *pickerLblTopContraint;
}

@property (weak, nonatomic) IBOutlet UIDatePicker *timePicker;
@property (nonatomic) BOOL isAwakeVC;

@end
