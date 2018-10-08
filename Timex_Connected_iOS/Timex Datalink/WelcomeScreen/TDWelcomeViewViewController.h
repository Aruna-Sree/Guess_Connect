//
//  TDWelcomeViewViewController.h
//  Timex
//
//  Created by Diego Santiago on 5/5/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDRootViewController.h"

@interface TDWelcomeViewViewController : TDRootViewController
{

    IBOutlet UIImageView *backArrow;
    IBOutlet UIImageView *timexLogo;
    IBOutlet UIView *topViewContainer;
    
    IBOutlet UILabel *welcomeLabel;
    
    IBOutlet UITextView *messageWelcome;
    
    IBOutlet UIImageView *welcomeSteps;
    IBOutlet UIImageView *welcomeDistance;
    IBOutlet UIImageView *welcomeCalories;
    IBOutlet UIImageView *welcomeSleep;
    
    IBOutlet UIView *bottomViewContainer;
    
    
    IBOutlet UITextView *createProfileMessage;
    
    IBOutlet UILabel *getStartedLabel;
    
    IBOutlet UIImageView *rightArrow;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

@end
