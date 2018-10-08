//
//  SleepDetailHeaderView.m
//  Timex
//
//  Created by Aruna Kumari Yarra on 26/05/16.
//

#import "SleepDetailHeaderView.h"
#import "TDDefines.h"
#import "iDevicesUtil.h"

@implementation SleepDetailHeaderView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (id)initWithFrame:(CGRect)frame {
    self = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] objectAtIndex:0];
    self.frame = frame;
    
    if (IS_IPAD) {
        _totalLblHeightConstraint.constant = 200;
        _totalLblWidthConstraint.constant = 200;
    }
    _leftLblWidthConstraint.constant = M328_SLEEP_DETAILS_ARC_SEGMENT_WIDTH;
    _rightLblWidthConstraint.constant = M328_SLEEP_DETAILS_ARC_SEGMENT_WIDTH;
    [_totalTimeLbl layoutIfNeeded];
    _totalTimeLbl.layer.cornerRadius = _totalTimeLbl.frame.size.height/2;
    _totalTimeLbl.layer.masksToBounds = YES;
    return self;
}
- (void)setStartTimeWithText:(NSString *)textStr {
    if (textStr.length > 3) {
        _startTimeLbl.attributedText = [self getAttributedStrWithText:textStr range:NSMakeRange((textStr.length - 2), 2)];
    }
}

- (void)setEndTimeWithText:(NSString *)textStr  {
    if (textStr.length > 3) {
        _endTimeLbl.attributedText = [self getAttributedStrWithText:textStr range:NSMakeRange((textStr.length - 2), 2)];
    }
}

- (void)setTotalTimeWithText:(NSString *)textStr {
    UIFont *font1 = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size: M328_SLEEP_DETAILS_CELL_TITLE_FONT_SIZE];
    NSDictionary *dict1 = [NSDictionary dictionaryWithObjectsAndKeys:font1, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *atrrStr = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"TOTAL\n",nil) attributes:dict1];
    
    UIFont *font2 = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size: M328_SLEEP_DETAILS_TOTAL_TIME_TITLE_FONT_SIZE];
    NSDictionary *dict2 = [NSDictionary dictionaryWithObjectsAndKeys:font2, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSAttributedString *timeStr = [[NSAttributedString alloc] initWithString:textStr attributes:dict2];
    [atrrStr appendAttributedString:timeStr];
    
    UIFont *font3 = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size: M328_SLEEPHISTORY_SCREEN_FORMAT_FONT_SIZE];
    NSDictionary *dict3 = [NSDictionary dictionaryWithObjectsAndKeys:font3, NSFontAttributeName, UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),NSForegroundColorAttributeName, nil];
    NSAttributedString *formatAtrStr = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"\nHOURS",nil) attributes:dict3];
    [atrrStr appendAttributedString:formatAtrStr];
    
    _totalTimeLbl.attributedText = atrrStr;
}

- (NSAttributedString *)getAttributedStrWithText:(NSString *)textStr range:(NSRange)formatStrRange {
    UIFont *textFont = [UIFont fontWithName:[iDevicesUtil getAppWideFontName] size:M328_SLEEPHISTORY_SCREEN_FORMAT_FONT_SIZE];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:textFont, NSFontAttributeName,[UIColor blackColor], NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *textAtrStr = [[NSMutableAttributedString alloc] initWithString:textStr attributes:dict];
    
    NSDictionary *atrsDict = [NSDictionary dictionaryWithObjectsAndKeys:textFont, NSFontAttributeName, UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),NSForegroundColorAttributeName, nil];
    [textAtrStr addAttributes:atrsDict range:formatStrRange];
    
    return textAtrStr;
}

@end
