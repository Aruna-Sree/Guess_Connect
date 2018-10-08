//
//  SetSubDialDisplayViewController.h
//  Timex
//
//  Created by kpasupuleti on 5/4/16.
//

#import <UIKit/UIKit.h>
#import "TDRootViewController.h"
@interface SetSubDialDisplayViewController : UIViewController<UIPickerViewDelegate, UIPickerViewDataSource> {
    IBOutlet UIImageView *watchImageView;
    IBOutlet UILabel *infoLabel;
    IBOutlet UIPickerView *pickView;
    IBOutlet UIButton *selectedButton;
    
    IBOutlet NSLayoutConstraint *infoLblleftConstraint;
    IBOutlet NSLayoutConstraint *infoLblTopConstraint;
}


@end
