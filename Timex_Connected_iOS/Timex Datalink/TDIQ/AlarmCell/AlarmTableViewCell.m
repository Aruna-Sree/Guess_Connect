//
//  AlarmTableViewCell.m
//  Timex
//
//  Created by Aruna Kumari Yarra on 02/06/16.
//

#import "AlarmTableViewCell.h"
#import "TDDefines.h"
@implementation AlarmTableViewCell
@synthesize alarmTextLbl, onOffSwitch;
- (void)awakeFromNib {
    [super awakeFromNib];
    [onOffSwitch setOnTintColor:UIColorFromRGB(AppColorRed)];
    [_editButton setTitle:NSLocalizedString(_editButton.currentTitle, nil) forState:UIControlStateNormal];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
