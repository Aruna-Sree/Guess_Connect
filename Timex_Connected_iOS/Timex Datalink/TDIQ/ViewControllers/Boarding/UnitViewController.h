//
//  NameViewController.h
//  Timex-iOS
//
//  Created by kpasupuleti on 5/4/16.
//

#import <UIKit/UIKit.h>

@interface UnitViewController : UIViewController {
    IBOutlet UILabel *infoLabel;
    IBOutlet UILabel *progressLbl;
    IBOutlet UIButton *imperialBtn;
    IBOutlet UIButton *metricBtn;
    
    IBOutlet UILabel *milesLabel;
    IBOutlet UILabel *kiloMetersLabel;
    IBOutlet UIButton *nextButton;
    
    IBOutlet NSLayoutConstraint *infoLblTopConstraint;
    IBOutlet NSLayoutConstraint *infoLblleftConstraint;
    IBOutlet NSLayoutConstraint *infoLblBottomContraint;
    
    IBOutlet NSLayoutConstraint *fieldViewTopContraint;
    IBOutlet NSLayoutConstraint *progressLblWidthContraint;
}

@end


