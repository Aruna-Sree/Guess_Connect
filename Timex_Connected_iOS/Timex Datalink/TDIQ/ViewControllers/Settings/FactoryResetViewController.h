//
//  FactoryResetViewController.h
//  timex
//
//  Created by Nick Graff on 1/12/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FactoryResetViewController : UIViewController
{
    
    IBOutlet UIImageView *checkmarkImage;
    IBOutlet UILabel *resetCompleteLabel;
    
    IBOutlet UIView *syncView;
    IBOutlet UILabel *syncLbl;
    IBOutlet UIImageView *watchSetup;
    IBOutlet UIActivityIndicatorView *syncViewActivityIndicator;
    
}

@end
