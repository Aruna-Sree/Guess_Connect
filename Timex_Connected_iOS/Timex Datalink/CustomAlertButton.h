//
//  CustomAlertButton.h
//  timex
//
//  Created by Raghu on 16/01/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomAlertButton : UIButton

-(id)initWithTitle:(NSString *)title andActionBlock:(void (^)(void))block;

-(void)performAlertButtonClickAction;

@end
