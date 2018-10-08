//
//  TDDeviceTypeCellTableViewCell.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 5/5/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iDevicesUtil.h"

@interface TDDeviceTypeCellTableViewCell : UITableViewCell
{
    UILabel                         * descrLabel;
    UIImageView                     * watchLogo;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier withDevice: (timexDatalinkWatchStyle) device useFrame: (CGRect)rect;

@end
