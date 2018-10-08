//
//  HelpViewController.h
//  Timex
//
//  Created by Aruna Kumari Yarra on 27/06/16.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "TDRootViewController.h"

@interface HelpViewController : TDRootViewController <UIWebViewDelegate, WKUIDelegate> {
    IBOutlet UIWebView *helpWebview;
    IBOutlet UIBarButtonItem *refershBtn;
    IBOutlet UIBarButtonItem *backBtn;
    IBOutlet UIBarButtonItem *nextBtn;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil fromSync:(BOOL)isSync_ ;
@end
