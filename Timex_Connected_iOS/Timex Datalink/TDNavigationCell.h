//
//  TDNavigationCell.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 6/18/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDNavigationItem.h"
#import "UIImage+Tint.h"

@interface TDNavigationCell : UITableViewCell
{
    UILabel     * descrLabel;
    UIImageView * descrIcon;
}

@property (nonatomic, weak) TDNavigationItem * cellInfo;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier navOption: (TDNavigationItem *) info useFrame: (CGRect)rect;
@end
