//
//  SleepExplanationPopup.h
//  timex
//
//  Created by Aruna Kumari Yarra on 07/12/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SleepExplanationPopup : UIView {
    IBOutlet UILabel *backgroundLabl;
    IBOutlet UIView *popupView;
    IBOutlet UIButton *titleBtn;
    IBOutlet UILabel *descriptionLbl;
    UITapGestureRecognizer *tap;
}
- (void)setImageNDescriptionBasedOnSleepType:(int)sleepType;
@end
