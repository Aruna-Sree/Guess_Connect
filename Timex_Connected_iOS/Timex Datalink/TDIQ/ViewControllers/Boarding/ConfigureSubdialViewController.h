//
//  ConfigureSubdialViewController.h
//  Timex
//
//  Created by avemulakonda on 5/4/16.
//

#import <UIKit/UIKit.h>

@interface ConfigureSubdialViewController : UIViewController<UIPickerViewDelegate, UIPickerViewDataSource> {
    IBOutlet UILabel *infoLabel;
    IBOutlet UILabel *progressLbl;
    
    IBOutlet NSLayoutConstraint *infoLblTopConstraint;
    IBOutlet NSLayoutConstraint *infoLblleftConstraint;
    IBOutlet NSLayoutConstraint *infoLblRightConstraint;
    IBOutlet NSLayoutConstraint *infoLblBottomContraint;
    
    IBOutlet NSLayoutConstraint *progressLblWidthContraint;
    IBOutlet NSLayoutConstraint *nextButtonBottomContraint;
    
    IBOutlet UIPickerView *pickView;
    IBOutlet UIImageView *watchImage;
    IBOutlet UIButton *selectedButton;
}

@property (nonatomic ) BOOL openedByMenu;
@property (weak, nonatomic) IBOutlet UIButton *NextButton;

@end
