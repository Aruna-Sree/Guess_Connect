//
//  TDOnBoardingTableViewCell.h
//  Timex
//
//  Created by Diego Santiago on 5/25/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iDevicesUtil.h"

@interface TDOnBoardingTableViewCell : UITableViewCell

{

    IBOutlet UIImageView *watchImage;
    IBOutlet UILabel *watchName;
    IBOutlet UILabel *watchConnecting;
    IBOutlet UIActivityIndicatorView *activityInWatch;
    IBOutlet UIImageView *imageComplete;
    
}
@property (nonatomic ) NSString *watchNameString;
@property (nonatomic ) NSString *watchConnectingString;
@property (nonatomic ) UIImage  *watchUIImage;

- (void)setWatchNameString:(NSString *)watchNameString;
- (void)setWatchConnectingString:(NSString *)watchConnectingString;
- (void)setWatchUIImage:(UIImage *)watchUIImage;
- (void)setWatchIndicationActivityOn;
- (void)setWatchIndicationActivityOff;
- (void)setWatchComleteImage:(UIImage *)image;

@end
