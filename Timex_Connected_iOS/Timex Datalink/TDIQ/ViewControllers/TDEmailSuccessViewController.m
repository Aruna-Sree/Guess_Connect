//
//  TDEmailSuccessViewController.m
//  timex
//
//  Created by Aruna Kumari Yarra on 27/03/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import "TDEmailSuccessViewController.h"
#import "TDAppDelegate.h"
#import "TDDefines.h"
#import "TDM328WatchSettingsUserDefaults.h"
@interface TDEmailSuccessViewController () {
    IBOutlet UILabel *msgLbl;
    IBOutlet UIButton *okBtn;
    IBOutlet UILabel *bgLbl;
    TDAppDelegate *appDelegate;
}

@end

@implementation TDEmailSuccessViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    appDelegate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
    self.navigationItem.hidesBackButton = YES;
    
    msgLbl.font = [UIFont fontWithName:[iDevicesUtil getAppWideFontName] size:17];
    msgLbl.text = [NSString stringWithFormat:@"%@,\n%@\n\n%@\n\n%@\n%@",[TDM328WatchSettingsUserDefaults userName],NSLocalizedString(@"An email has been sent to Guess Connect customer service, containing detailed information about your watch, that will help us determine next steps.", nil),NSLocalizedString(@"Please keep an eye out for email from Guess Connect with instructions on how to proceed.", nil),NSLocalizedString(@"Sincerely,", nil),NSLocalizedString(@"Guess Connect Team", nil)];
    [msgLbl sizeToFit];
    
    [okBtn setTitle:[NSString stringWithFormat:@"%@  ", NSLocalizedString(@"OK", nil)] forState:UIControlStateNormal];
    okBtn.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    okBtn.titleLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    okBtn.imageView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    
    bgLbl.layer.cornerRadius = 15;
    bgLbl.layer.masksToBounds = YES;
}
- (void)viewDidLayoutSubviews {
    [msgLbl sizeToFit];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)clickedOnOkBtn:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
