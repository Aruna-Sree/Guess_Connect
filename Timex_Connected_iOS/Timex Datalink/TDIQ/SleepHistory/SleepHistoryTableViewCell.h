//
//  SleepHistoryTableViewCell.h
//  Timex
//
//  Created by Aruna Kumari Yarra on 19/05/16.
//

#import <UIKit/UIKit.h>

@interface SleepHistoryTableViewCell : UITableViewCell {
    int radiusSegment;
    int SegmentWidth;
    UIColor *choiceColor;
    CGFloat segementStart;
    CGFloat segementEnd;
}
@property (nonatomic, strong) IBOutlet UILabel *sleepDetailLbl;
@property (nonatomic, strong) IBOutlet UIView *progessView;
- (void)executeSegments:(NSString *)information andSide:(BOOL)side hours: (float )hours;
@end
