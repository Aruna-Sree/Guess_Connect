//
//  StepsViewController.h
//  Timex
//
//  Created by avemulakonda on 5/11/16.
//

#import <UIKit/UIKit.h>
#import "HMSegmentedControl.h"
#import <Charts/Charts-Swift.h>

@interface StepsViewController : UIViewController<ChartViewDelegate, IChartAxisValueFormatter>
{
    HMSegmentedControl *rangeSegments;

    IBOutlet UIView *headerView;
    
    IBOutlet BarChartView *chartView;
    IBOutlet UIImageView *dashedLine;
    IBOutlet UIImageView *backgroundImgView;
    
    double limit;
    IBOutlet NSLayoutConstraint *dashedLineBottomConstraint;
    IBOutlet NSLayoutConstraint *chartBottomConstraint;
    IBOutlet NSLayoutConstraint *headerViewHeightConstraint;
}
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *chartLeftConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *dashedLeftConstraint;

@property(nonatomic, assign) NSInteger segmentedindex;

@property(nonatomic, weak) IBOutlet UILabel *leftLabel;
@property(nonatomic, weak) IBOutlet UILabel *rightLabel;
@property(nonatomic, weak) IBOutlet UILabel *middleLabel;
@property(nonatomic, assign) NSInteger selectedRow;
@property (nonatomic, strong) id caller;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil selectedDate:(NSDate *)date;

@end
