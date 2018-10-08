//
//  AboutViewController.h
//  Timex
//
//  Created by Aruna Kumari Yarra on 27/06/16.
//

#import <UIKit/UIKit.h>
#import "TDRootViewController.h"
#import "TDHTTPClient.h"
#import "MBProgressHUD.h"
#import <MessageUI/MessageUI.h>

@interface AboutViewController : TDRootViewController<TDHTTPClientDelegate, MBProgressHUDDelegate, MFMailComposeViewControllerDelegate> {
    IBOutlet UILabel *watchInfoLbl;
    IBOutlet UIButton *licenseAgreementBtn;
    IBOutlet UIButton *registerWatchBtn;
    IBOutlet UILabel *yourWatchLabel;
    
    IBOutlet UIButton *supportBtn;
    IBOutlet UIButton *watchBtn;
    IBOutlet UIButton *backBtn;
    IBOutlet UILabel *appVersionLbl;
    IBOutlet UIView *registrationView;
    IBOutlet UIScrollView *registrationScrollView;
}
@property (nonatomic) BOOL showBackButton;
@end
