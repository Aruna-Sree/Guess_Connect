//
//  TDOnBoardingTableViewCell.m
//  Timex
//
//  Created by Diego Santiago on 5/25/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import "TDOnBoardingTableViewCell.h"
#import "UIImage+Tint.h"
#import "TDDefines.h"

@implementation TDOnBoardingTableViewCell

@synthesize watchNameString         = _watchNameString;
@synthesize watchConnectingString   = _watchConnectingString;
@synthesize watchUIImage            = _watchUIImage;

- (void)setWatchNameString:(NSString *)watchNameString
{
    watchName.minimumScaleFactor = 0.5;
    watchName.font = [UIFont fontWithName:@"Roboto-Light" size:15];
    
    _watchNameString = watchNameString;
    watchName.text = _watchNameString;
}

-(void)setWatchConnectingString:(NSString *)watchConnectingString
{
    watchConnecting.minimumScaleFactor = 0.5;
    watchConnecting.font = [UIFont fontWithName:@"Roboto-Bold" size:14];
    watchConnecting.textColor = BlueOne;
    
    _watchConnectingString = watchConnectingString;
    watchConnecting.text = _watchConnectingString;
}
- (void)setWatchUIImage:(UIImage *)watchUIImage
{
    _watchUIImage = watchUIImage;
    watchImage.image = _watchUIImage;
}
- (void)setWatchIndicationActivityOn
{
    activityInWatch.hidden = NO;
    [activityInWatch startAnimating];
}
- (void)setWatchIndicationActivityOff
{
    [activityInWatch stopAnimating];
    activityInWatch.hidden = YES;
}

- (void)setWatchComleteImage:(UIImage *)image
{
    [imageComplete setHidden:false];
    [imageComplete setImage:[image imageWithTint:BlueOne]];
}


@end
