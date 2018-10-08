//
//  SleepHistoryViewController.h
//  Timex
//
//  Created by Aruna Kumari Yarra on 19/05/16.
//

#import <UIKit/UIKit.h>
#import "HMSegmentedControl.h"
#import <Charts/Charts-Swift.h>


@interface SleepHistoryViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, ChartViewDelegate, IChartAxisValueFormatter> {
    HMSegmentedControl *rangeSegments;
    IBOutlet UITableView *sleepTable;
    /// For the initial table at the events segment
    /// this will store into section based arrays.
    NSMutableArray * sleepHistoryArray;
    
    IBOutlet NSLayoutConstraint *tableViewBottomConstraint;
    IBOutlet NSLayoutConstraint *dashedLeftConstraint;
    IBOutlet NSLayoutConstraint *dashedLineBottomConstraint;

    IBOutlet UIView *chatDisplayView;
    IBOutlet UIView *headerView;
    IBOutlet UILabel *leftLabel;
    IBOutlet UILabel *rightLabel;
    IBOutlet UILabel *middleLabel;
    IBOutlet UIImageView *dashedLine;
    IBOutlet BarChartView *chartView;
    CGFloat lastZoom;
    double limit;
    
    IBOutlet UILabel *noDataDescriptionLabl;
    IBOutlet UIImageView *backgroundImgView;
}
@property (nonatomic, strong) id caller;
- (void)syncDone;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil selectedDate:(NSDate *)date;
@end
