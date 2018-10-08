//
//  TDCustomCollectionViewCell.m
//  TableViewCellTest
//
//  Created by Aruna Kumari Yarra on 30/03/16.
//

#import "TDCustomCollectionViewCell.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"

@implementation TDCustomCollectionViewCell

- (id)init {
    self = [super init];
   
    return self;
}
- (void)setDataToAllViews:(NSArray *)array indexPath:(NSIndexPath *)indexPath {
    
    _topLabel.font = [UIFont fontWithName:[iDevicesUtil getAppWideFontName] size:M328_SLEEP_DETAILS_CELL_TITLE_FONT_SIZE];
    _bottomLabel.font = [UIFont fontWithName:[iDevicesUtil getAppWideFontName] size:M328_SLEEP_DETAILS_CELL_TITLE_FONT_SIZE];
    
    _topLabel.backgroundColor = [UIColor clearColor];
    _topLabel.textColor = AppColorLightGray;
    _bottomLabel.textColor = AppColorLightGray;
    
    if (array.count > 0) {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                _topLabel.backgroundColor = M328_HOME_SLEEP_DARK_COLOR;
                _topLabel.textColor = [UIColor whiteColor];
                _topLabel.text = NSLocalizedString(@"DEEP", nil);
                _bottomLabel.attributedText = [self getAttributedStrWithText:[array objectAtIndex:0] formatStr:NSLocalizedString(@"\nHRS", nil)];
            } else if (indexPath.row == 1) {
                _topLabel.backgroundColor = M328_HOME_SLEEP_LIGHT_COLOR;
                _topLabel.textColor = [UIColor whiteColor];
                _topLabel.text = NSLocalizedString(@"LIGHT", nil);
                _bottomLabel.attributedText = [self getAttributedStrWithText:[array objectAtIndex:1] formatStr:NSLocalizedString(@"\nHRS", nil)];
                
            } else {
                _topLabel.backgroundColor = M328_HOME_SLEEP_AWAKE_COLOR;
                _topLabel.textColor = AppColorLightGray;
                _topLabel.text = NSLocalizedString(@"AWAKE", nil);
                _bottomLabel.attributedText = [self getAttributedStrWithText:[array objectAtIndex:2] formatStr:NSLocalizedString(@"\nHRS", nil)];
            }
        } else {
            if (indexPath.row == 0) {
                _topLabel.text = NSLocalizedString(@"EFFICIENCY", nil);
                _bottomLabel.attributedText = [self getAttributedStrWithText:[array objectAtIndex:3] formatStr:@"\n%"];
            } else if (indexPath.row == 1) {
                _topLabel.text = NSLocalizedString(@"GOAL", nil);
                _bottomLabel.attributedText = [self getAttributedStrWithText:[array objectAtIndex:4] formatStr:NSLocalizedString(@"\nHRS", nil)];
                
            } else {
                _topLabel.text = NSLocalizedString(@"AVERAGE", nil);
                _bottomLabel.attributedText = [self getAttributedStrWithText:[iDevicesUtil convertMinutesToStringHHDecimalFormat:([[array objectAtIndex:5] doubleValue] * MINUTES_PER_HOUR)] formatStr:NSLocalizedString(@"\nHRS", nil)];
            }
        }
    }
    
    if (IDIOM == IPAD) {
        self.topLabelYSpaceConstraint.constant = 20;
        self.bottomLabelHeightConstraint.constant = (self.frame.size.height - (20+25+5));
        self.topLblWidthConstarint.constant = 100;
    } else {
        self.topLabelYSpaceConstraint.constant = 10;
         self.bottomLabelHeightConstraint.constant = (self.frame.size.height - (10+25+5));
    }
    self.topLabel.layer.cornerRadius = 12.0f;
    self.topLabel.layer.masksToBounds = YES;
    [self layoutIfNeeded];
}


- (NSAttributedString *)getAttributedStrWithText:(NSString *)textStr formatStr:(NSString *)formatStr {
    UIFont *textFont = [UIFont fontWithName:[iDevicesUtil getAppWideFontName] size:M328_SLEEPHISTORY_SCREEN_TIME_FONT_SIZE];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:textFont, NSFontAttributeName, nil];
    NSMutableAttributedString *textAtrStr = [[NSMutableAttributedString alloc] initWithString:textStr attributes:dict];
    
    UIFont *formatFont = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size: M328_SLEEP_DETAILS_CELL_TITLE_FONT_SIZE];
    NSDictionary *atrsDict = [NSDictionary dictionaryWithObjectsAndKeys:formatFont, NSFontAttributeName, UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),NSForegroundColorAttributeName, nil];
    NSAttributedString *formatAtrStr = [[NSAttributedString alloc] initWithString:formatStr attributes:atrsDict];
    [textAtrStr appendAttributedString:formatAtrStr];
    
    return textAtrStr;
}
- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}
@end
