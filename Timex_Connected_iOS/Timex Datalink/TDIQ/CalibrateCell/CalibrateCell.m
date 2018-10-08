//
//  CalibrateCell.m
//  Timex
//
//  Created by Aruna Kumari Yarra on 25/05/16.
//

#import "CalibrateCell.h"
#import "TDDefines.h"
#import "iDevicesUtil.h"

@implementation CalibrateCell

@synthesize calibrateLbl, skipBtn;
- (void)awakeFromNib {
    [super awakeFromNib];
    calibrateLbl.font = [UIFont fontWithName: [iDevicesUtil getAppWideMediumFontName] size:13];
    
    [calibrateLbl setText:NSLocalizedString(@"Adjust Now", nil)];
    
    [skipBtn setTitle:[NSString stringWithFormat:@"%@  ", NSLocalizedString(@"SKIP", nil)] forState:UIControlStateNormal];
    skipBtn.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    skipBtn.titleLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    skipBtn.imageView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
