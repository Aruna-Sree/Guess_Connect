//
//  CustomAlertViewController.h
//  timex
//
//  Created by Raghu on 16/01/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomAlertButton.h"

@interface CustomAlertViewController : UIViewController

-(id)initWithTitle:(NSString *)title andMessage:(NSString *)message;

@property (strong, nonatomic) IBOutlet UIView *transparenBackGroundView;
@property (strong, nonatomic) IBOutlet UIView *alertView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIImageView *alertTitleImageView;
@property (strong, nonatomic) IBOutlet UILabel *MessageLabel;
@property (strong, nonatomic) IBOutlet UIView *buttonsView;

-(void)addActionButton:(CustomAlertButton *)customAlertButton;
-(void)dismissView;
@end
