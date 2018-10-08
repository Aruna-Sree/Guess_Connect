//
//  TDNavigationCell.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 6/18/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "TDNavigationCell.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"


@implementation TDNavigationCell

@synthesize cellInfo = _cellInfo;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier navOption: (TDNavigationItem *) info useFrame: (CGRect)rect;
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        _cellInfo = info;
        //TestLog_NewMenuForSleepTracker start
        timexDatalinkWatchStyle existingStyle = [iDevicesUtil getActiveWatchProfileStyle];
        if ((existingStyle == timexDatalinkWatchStyle_Metropolitan || existingStyle == timexDatalinkWatchStyle_IQ || existingStyle == timexDatalinkWatchStyle_IQTravel) && [iDevicesUtil checkForActiveProfilePresence])
        {
            if (existingStyle == timexDatalinkWatchStyle_IQ || existingStyle == timexDatalinkWatchStyle_IQTravel) {
                descrLabel = [[UILabel alloc] initWithFrame:CGRectMake(NAVIGATION_ITEM_ICON_SIZE + (NAVIGATION_ITEM_FRAME_OFFSET * 2), 0, rect.size.width - (NAVIGATION_ITEM_ICON_SIZE + (NAVIGATION_ITEM_FRAME_OFFSET * 2)), M328_SLIDE_MENU_CELL_HEIGHT)];
                descrLabel.textAlignment = NSTextAlignmentLeft;
                descrLabel.font = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:M328_SLIDE_MENU_CELL_FONT_SIZE];
                descrLabel.textColor = UIColorFromRGB(MEDIUM_GRAY_COLOR);
                descrLabel.text = [_cellInfo navigationLabel];
                
                descrIcon = [[UIImageView alloc] initWithFrame:CGRectMake(NAVIGATION_ITEM_FRAME_OFFSET, (rect.size.height - NAVIGATION_ITEM_ICON_SIZE) / 2, NAVIGATION_ITEM_ICON_SIZE, NAVIGATION_ITEM_ICON_SIZE)];
                [descrIcon setImage: [[_cellInfo navigationIcon] imageWithTint:UIColorFromRGB(MEDIUM_GRAY_COLOR)]];
            } else {
                
                // This is for Metropolitan
                descrLabel = [[UILabel alloc] initWithFrame:CGRectMake(NAVIGATION_ITEM_ICON_SIZE + (NAVIGATION_ITEM_FRAME_OFFSET * 2), (rect.size.height - NAVIGATION_ITEM_FONT_SIZE - 15) / 2, rect.size.width - (NAVIGATION_ITEM_ICON_SIZE + (NAVIGATION_ITEM_FRAME_OFFSET * 2)), NAVIGATION_ITEM_FONT_SIZE+15)];
                descrLabel.textAlignment = NSTextAlignmentLeft;
                descrLabel.font = [UIFont fontWithName: [iDevicesUtil getAppWideMediumFontName] size: M328_SLIDE_MENU_CELL_FONT_SIZE];
                descrLabel.textColor = [UIColor whiteColor];
                //descrLabel.shadowColor = [UIColor clearColor];
                //descrLabel.backgroundColor = [UIColor purpleColor];
                descrLabel.text = [_cellInfo navigationLabel];
                
                descrIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, (rect.size.height - NAVIGATION_ITEM_ICON_SIZE) / 2, NAVIGATION_ITEM_ICON_SIZE, NAVIGATION_ITEM_ICON_SIZE)];
                [descrIcon setImage: [[_cellInfo navigationIcon] imageWithTint:[UIColor grayColor]]];
            }
        }
        else
        {
            descrLabel = [[UILabel alloc] initWithFrame:CGRectMake(NAVIGATION_ITEM_ICON_SIZE + (NAVIGATION_ITEM_FRAME_OFFSET * 2), (rect.size.height - NAVIGATION_ITEM_FONT_SIZE) / 2, rect.size.width - (NAVIGATION_ITEM_ICON_SIZE + (NAVIGATION_ITEM_FRAME_OFFSET * 2)), NAVIGATION_ITEM_FONT_SIZE)];
            descrLabel.textAlignment = NSTextAlignmentLeft;
            descrLabel.font = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size: NAVIGATION_ITEM_FONT_SIZE];
            descrLabel.textColor = [UIColor whiteColor];
            descrLabel.shadowColor = [UIColor clearColor];
            descrLabel.backgroundColor = [UIColor clearColor];
            descrLabel.text = [_cellInfo navigationLabel];
            
            descrIcon = [[UIImageView alloc] initWithFrame:CGRectMake(NAVIGATION_ITEM_FRAME_OFFSET, (rect.size.height - NAVIGATION_ITEM_ICON_SIZE) / 2, NAVIGATION_ITEM_ICON_SIZE, NAVIGATION_ITEM_ICON_SIZE)];
            [descrIcon setImage: [_cellInfo navigationIcon]];
        }
        [self.contentView addSubview: descrIcon];
        [self.contentView addSubview: descrLabel];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    if (selected)
    {
        //TestLog_SleepTrackerImplementation
        timexDatalinkWatchStyle existingStyle = [iDevicesUtil getActiveWatchProfileStyle];
        if ((existingStyle == timexDatalinkWatchStyle_Metropolitan || existingStyle == timexDatalinkWatchStyle_IQ || existingStyle == timexDatalinkWatchStyle_IQTravel) && [iDevicesUtil checkForActiveProfilePresence])
        {
            if (existingStyle == timexDatalinkWatchStyle_IQ || existingStyle == timexDatalinkWatchStyle_IQTravel) {
                descrLabel.textColor = AppColorDarkGray;
                descrIcon.image = [_cellInfo navigationIconSelected];
            } else {
                descrLabel.textColor = [UIColor lightGrayColor];
                [descrIcon setImage: [[_cellInfo navigationIconSelected] imageWithTint:[iDevicesUtil getTimexRedColor]]];
            }
        }
        else
        {
            descrLabel.textColor = [iDevicesUtil getTimexRedColor];
            [descrIcon setImage: [_cellInfo navigationIconSelected]];
        }
    }
    else
    {
        //TestLog_SleepTrackerImplementation
        timexDatalinkWatchStyle existingStyle = [iDevicesUtil getActiveWatchProfileStyle];
        if ((existingStyle == timexDatalinkWatchStyle_Metropolitan || existingStyle == timexDatalinkWatchStyle_IQ || existingStyle == timexDatalinkWatchStyle_IQTravel) && [iDevicesUtil checkForActiveProfilePresence])
        {
            if (existingStyle == timexDatalinkWatchStyle_IQ || existingStyle == timexDatalinkWatchStyle_IQTravel) {
                descrLabel.textColor = UIColorFromRGB(MEDIUM_GRAY_COLOR);
                descrIcon.image = [_cellInfo navigationIcon];
            } else {
                descrLabel.textColor = [UIColor blackColor];
                [descrIcon setImage: [[_cellInfo navigationIcon] imageWithTint:[UIColor grayColor]]];
            }
        }
        else
        {
            descrLabel.textColor = [UIColor whiteColor];
            [descrIcon setImage: [_cellInfo navigationIcon]];
        }
    }
}

@end
