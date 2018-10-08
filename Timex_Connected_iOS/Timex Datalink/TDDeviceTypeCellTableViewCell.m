//
//  TDDeviceTypeCellTableViewCell.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 5/5/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "TDDeviceTypeCellTableViewCell.h"
#import "TDDefines.h"
#import "WhichApp.h"

@implementation TDDeviceTypeCellTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier withDevice: (timexDatalinkWatchStyle) device useFrame: (CGRect)rect
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        descrLabel = [[UILabel alloc] initWithFrame:CGRectMake(INITIAL_SETUP_WATCH_LIST_ICON_SIZE + INITIAL_SETUP_WATCH_LIST_FRAME_OFFSET * 2, rect.size.height/2 - INITIAL_SETUP_WATCH_LIST_FONT_SIZE/2, rect.size.width - (INITIAL_SETUP_WATCH_LIST_ICON_SIZE + INITIAL_SETUP_WATCH_LIST_FRAME_OFFSET * 3), INITIAL_SETUP_WATCH_LIST_FONT_SIZE + 6)];
        descrLabel.textAlignment = NSTextAlignmentLeft;
        descrLabel.font = [UIFont fontWithName: [iDevicesUtil getAppWideBoldFontName] size: INITIAL_SETUP_WATCH_LIST_FONT_SIZE];
        descrLabel.textColor = UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT_DARK);
        descrLabel.shadowColor = [UIColor clearColor];
        descrLabel.numberOfLines = 1;
        [descrLabel setTextAlignment: [WhichApp iPad] ? NSTextAlignmentCenter : NSTextAlignmentLeft];
        descrLabel.backgroundColor = [UIColor clearColor];
        
        watchLogo = [[UIImageView alloc] initWithFrame: CGRectMake(INITIAL_SETUP_WATCH_LIST_FRAME_OFFSET, rect.size.height/2 - INITIAL_SETUP_WATCH_LIST_ICON_SIZE/2, INITIAL_SETUP_WATCH_LIST_ICON_SIZE, INITIAL_SETUP_WATCH_LIST_ICON_SIZE)];
       
            
        switch (device)
        {
            case timexDatalinkWatchStyle_ActivityTracker:
                [watchLogo setImage: [UIImage imageNamed: @"watch_M053.png"]];
                descrLabel.text = NSLocalizedString([iDevicesUtil convertTimexModuleStringToProductName: M053_WATCH_MODEL], nil);
                break;
            case timexDatalinkWatchStyle_M054:
                [watchLogo setImage: [UIImage imageNamed: @"watch_M054.png"]];
                descrLabel.text = NSLocalizedString([iDevicesUtil convertTimexModuleStringToProductName: M054_WATCH_MODEL], nil);
                break;
            case timexDatalinkWatchStyle_Metropolitan:
                [watchLogo setImage: [UIImage imageNamed: @"watch_M372.png"]];
                descrLabel.text = NSLocalizedString([iDevicesUtil convertTimexModuleStringToProductName: M372_WATCH_MODEL], nil);
                break;
            case timexDatalinkWatchStyle_IQ:
                [watchLogo setImage: [UIImage imageNamed: @"watch_M328"]];
                watchLogo.contentMode =  UIViewContentModeScaleAspectFit;
                descrLabel.text = NSLocalizedString([iDevicesUtil convertTimexModuleStringToProductName:
                                   M328_WATCH_MODEL], nil);
                break;
            case timexDatalinkWatchStyle_IQTravel:
                [watchLogo setImage: [UIImage imageNamed: @"watch_M329"]];
                watchLogo.contentMode =  UIViewContentModeScaleAspectFit;
                descrLabel.text = NSLocalizedString([iDevicesUtil convertTimexModuleStringToProductName:
                                                     M329_WATCH_MODEL], nil);
                break;
            default:
                break;
        }
        
        
        [self.contentView addSubview: descrLabel];
        [self.contentView addSubview: watchLogo];
    }
    return self;
}


@end
