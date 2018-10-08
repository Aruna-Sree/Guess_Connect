//
//  ConfigureSecondsViewController.h
//  Timex
//
//  Created by avemulakonda on 5/4/16.
//

#import <UIKit/UIKit.h>

@interface ConfigureSecondsViewController : UIViewController<UIPickerViewDelegate, UIPickerViewDataSource> {
    IBOutlet UILabel *infoLabel;
    IBOutlet UILabel *progressLbl;
    
    IBOutlet NSLayoutConstraint *infoLblTopConstraint;
    IBOutlet NSLayoutConstraint *infoLblleftConstraint;
    IBOutlet NSLayoutConstraint *infoLblBottomContraint;
    IBOutlet NSLayoutConstraint *infoLblRightConstraint;
    IBOutlet NSLayoutConstraint *progressLblWidthContraint;
    IBOutlet NSLayoutConstraint *nextButtonBottomContraint;
    
    IBOutlet UIImageView *watchImage;
    IBOutlet UIPickerView *secondsPicker;
}

@property (nonatomic ) BOOL openedByMenu;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@end
