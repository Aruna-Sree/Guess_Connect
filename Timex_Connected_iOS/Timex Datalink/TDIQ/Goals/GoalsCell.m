//
//  HomeCell.m
//  Timex
//
//  Created by avemulakonda on 5/12/16.
//

#import "GoalsCell.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"
@implementation GoalsCell
@synthesize titleLbl, currentLabel, goalsTextFd, tagLbl, profileImageView;
- (void)awakeFromNib {
    [super awakeFromNib];
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 1, currentLabel.frame.size.width, 0.5)];
    lineView.backgroundColor = UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT);
    [currentLabel addSubview:lineView];
    
    currentLabel.font = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size: M328_GOALS_SCREEN_CURRENT_FONT_SIZE];
    currentLabel.textColor = UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT);
    
    tagLbl.font = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size: M328_GOALS_SCREEN_TAG_FONT_SIZE];
    tagLbl.textColor = UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT);
    
    goalsTextFd.font = [UIFont fontWithName: [iDevicesUtil getAppWideMediumFontName] size: M328_GOALS_SCREEN_GOALS_FONT_SIZE];
    goalsTextFd.textColor = [UIColor blackColor];
    goalsTextFd.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    
    UIButton *edit = [UIButton buttonWithType:UIButtonTypeCustom];
    edit.frame = CGRectMake(0, 0, 15, 15);
    [edit setImage:[UIImage imageNamed:@"EditIcon"] forState:UIControlStateNormal];
    [edit addTarget:self action:@selector(editBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    self.accessoryView = edit;
}
- (void)editBtnClicked {
    [goalsTextFd becomeFirstResponder];
}
- (void)inputAccessoryviewForTextfield {
    UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, ScreenWidth, NUMBER_TOOLBAR_HEIGHT)];
    numberToolbar.barStyle = UIBarStyleDefault;
    numberToolbar.translucent = YES;
    numberToolbar.barTintColor = [UIColor whiteColor];
    
    UIButton *nextBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    nextBtn.frame = CGRectMake(0, 0, 50, NUMBER_TOOLBAR_HEIGHT);
    [nextBtn setTitleColor:UIColorFromRGB(AppColorRed) forState:UIControlStateNormal];
    if (goalsTextFd.indexPath.row > 2) {
        [nextBtn setTitle:NSLocalizedString(@"DONE", nil) forState:UIControlStateNormal];
    } else {
        [nextBtn setTitle:NSLocalizedString(@"Next", nil) forState:UIControlStateNormal];
    }
    
    [nextBtn.titleLabel setFont:[UIFont fontWithName:[iDevicesUtil getAppWideBoldFontName] size:13]];
    [nextBtn addTarget:goalsTextFd.delegate action:@selector(keyboardNextButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    nextBtn.tag = goalsTextFd.indexPath.row + 1;
    numberToolbar.items = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                            [[UIBarButtonItem alloc] initWithCustomView:nextBtn]];
    goalsTextFd.inputAccessoryView = numberToolbar;
}
@end
