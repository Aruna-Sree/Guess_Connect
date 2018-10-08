//
//  TDFactoryResetViewController.h
//  timex
//
//  Created by Raghu on 06/03/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDFactoryResetViewController : UIViewController
{
    IBOutlet UILabel *resetCompleteLabel;
    IBOutlet UIImageView *checkmarkImage;
    
    IBOutlet UIView *syncView;
    IBOutlet UILabel *syncLbl;
    IBOutlet UIImageView *watchSetup;
    IBOutlet UIActivityIndicatorView *syncViewActivityIndicator;
}

@end
