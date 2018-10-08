//
//  AlarmTableViewCell.h
//  Timex
//
//  Created by Aruna Kumari Yarra on 02/06/16.
//

#import <UIKit/UIKit.h>

@interface AlarmTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *alarmTextLbl;
@property (nonatomic, strong) IBOutlet UISwitch *onOffSwitch;
@property (strong, nonatomic) IBOutlet UIButton *editButton;

@end
