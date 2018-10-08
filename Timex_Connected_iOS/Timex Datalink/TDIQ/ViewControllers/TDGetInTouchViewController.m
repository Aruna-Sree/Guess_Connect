//
//  TDGetInTouchViewController.m
//  timex
//
//  Created by Aruna Kumari Yarra on 14/03/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import "TDGetInTouchViewController.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "TDAppDelegate.h"
#import "AboutViewController.h"
#import "TDEmailSuccessViewController.h"

@interface TDGetInTouchViewController () {
    TDAppDelegate *appDelegate;
    IBOutlet UILabel *headerLbl;
}

@end

@implementation TDGetInTouchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    appDelegate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
    
    UIButton *backBtn = [iDevicesUtil getBackButton];
    [backBtn addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = barBtn;
    
    headerLbl.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Let's get in touch.", nil) formatStr:[NSString stringWithFormat:@"\n\n%@",NSLocalizedString(@"Choose the best way for us to reach you.", nil)]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSAttributedString *)getAttributedStrWithText:(NSString *)textStr formatStr:(NSString *)formatStr {
    
    UIFont *textFont = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:M328_REGISTRATION_TITLE_FONTSIZE];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:textFont, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *textAtrStr = [[NSMutableAttributedString alloc] initWithString:textStr attributes:dict];
    
    UIFont *formatFont = [UIFont fontWithName: [iDevicesUtil getAppWideMediumFontName] size:M328_WELCOME_INFO_FONTSIZE];
    NSDictionary *atrsDict = [NSDictionary dictionaryWithObjectsAndKeys:formatFont, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *formatAtrStr = [[NSMutableAttributedString alloc] initWithString:formatStr attributes:atrsDict];
    
    [textAtrStr appendAttributedString:formatAtrStr];
    
    return textAtrStr;
}

- (void)backButtonTapped {
    // For poviewcontroller completion block
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [appDelegate.customTabbar backFromGetInTouchScreen];
    }];
    [self.navigationController popViewControllerAnimated:YES];
    [CATransaction commit];
}
- (IBAction)clcikedOnEmail:(id)sender {
    NSString *emailTitle = @"SYSBLOCK.BIN files";
    NSString *messageBody = @"";
    NSArray *toRecipents = [NSArray arrayWithObject:CUSTOMER_SUPPORT_URL];
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:emailTitle];
    [mc setMessageBody:messageBody isHTML:NO];
    [mc setToRecipients:toRecipents];
    
    NSArray *files = [TDM328WatchSettingsUserDefaults storedNames];
    NSString *file = @"";
    // Add attachments
    for (file in files)
    {
        // Determine the file name and extension
        NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *directoryFix = [NSString stringWithFormat:@"%@/%@", documentsDirectory, file];
        
        // Get the resource path and read the file using NSData
        NSData *fileData = [NSData dataWithContentsOfFile:directoryFix];
        [mc addAttachmentData:fileData mimeType:@"application/x-binary" fileName:file];
    }
    
    // Present mail view controller on screen
    [self.navigationController presentViewController:mc animated:YES completion:nil];
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            break;
        case MFMailComposeResultSaved:
            break;
        case MFMailComposeResultSent: {
            [controller dismissViewControllerAnimated:YES completion:nil];
            TDEmailSuccessViewController *emailSuccsVC = [[TDEmailSuccessViewController alloc] initWithNibName:@"TDEmailSuccessViewController" bundle:nil];
            [self.navigationController pushViewController:emailSuccsVC animated:YES];
            return;
        }
            break;
        case MFMailComposeResultFailed:
            break;
        default:
            break;
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)clickedOnAboutWatch:(id)sender {
    AboutViewController *aboutVC = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
    aboutVC.showBackButton = YES;
    [self.navigationController pushViewController:aboutVC animated:YES];
}

- (IBAction)clcikedOnCall:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:TIMEX_CUSTOMER_SERVICE_URL]];
    [self.navigationController popViewControllerAnimated:YES];
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
