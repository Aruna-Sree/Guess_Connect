//
//  HomeCell.h
//  Timex
//
//  Created by Aruna on 5/12/16.
//

#import <UIKit/UIKit.h>
#import "GoalTextField.h"
@interface GoalsCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLbl;
@property (weak, nonatomic) IBOutlet GoalTextField *goalsTextFd;
@property (weak, nonatomic) IBOutlet UILabel *currentLabel;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *tagLbl;
@property (weak, nonatomic) IBOutlet UIImageView *subdialImg;

- (void)inputAccessoryviewForTextfield;
@end
