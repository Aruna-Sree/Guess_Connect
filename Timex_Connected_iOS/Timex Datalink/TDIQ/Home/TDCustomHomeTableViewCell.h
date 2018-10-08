//
//  TDCustomHomeTableViewCell.h
//  Timex
//
//  Created by Aruna Kumari Yarra on 12/04/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBCircularProgressBarView.h"
@interface TDCustomHomeTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet MBCircularProgressBarView *progressView;
@property (nonatomic, strong) IBOutlet UIImageView *cellImgView;
@property (nonatomic, strong) IBOutlet UILabel * titleLabel;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* progressViewWidthConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* imgViewWidthConstraint;
@property (nonatomic, strong) IBOutlet UIView *subdialView;
@property (nonatomic, strong) IBOutlet UIView *handView;
@property (strong, nonatomic) IBOutlet UIImageView *subdialImg;
@end
