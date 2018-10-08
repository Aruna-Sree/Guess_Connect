//
//  WelcomeViewController.h
//  Timex-iOS
//
//  Created by avemulakonda on 5/4/16.
//

#import <UIKit/UIKit.h>

@interface WelcomeViewController : UIViewController {
    
    IBOutlet UIImageView *welcomeImg;
    IBOutlet UILabel *welcomeTextLbl;
    IBOutlet UIButton *getStartedButton;
    IBOutlet UILabel *pleaseCreateYourProfileLabel;
    
    
    IBOutlet NSLayoutConstraint *welcomeTextLblTopConstraint;
    IBOutlet NSLayoutConstraint *welcomeTextLblLeftConstraint;
    IBOutlet NSLayoutConstraint *welcomeTextLblRightContraint;
    IBOutlet NSLayoutConstraint *welcomeTextLblHeightContraint;
    IBOutlet NSLayoutConstraint *welcomeTextLblBottomContraint;
    
    IBOutlet NSLayoutConstraint *imgsViewWidthContraint;
    IBOutlet NSLayoutConstraint *imgsViewHeightContraint;
    
    IBOutlet NSLayoutConstraint *bottomLblLeftConstraint;
    IBOutlet NSLayoutConstraint *bottomLblRightContraint;
    
    IBOutlet NSLayoutConstraint *nextButtonBottomContraint;
    
}

@end
