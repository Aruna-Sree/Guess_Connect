//
//  TDCustomHomeTableViewCell.m
//  Timex
//
//  Created by Aruna Kumari Yarra on 12/04/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import "TDCustomHomeTableViewCell.h"

@implementation TDCustomHomeTableViewCell

@synthesize progressView, titleLabel, cellImgView, progressViewWidthConstraint, imgViewWidthConstraint, subdialView, handView;
- (void)awakeFromNib {
    [super awakeFromNib];
    //Testing
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
