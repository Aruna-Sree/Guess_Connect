//
//  TDWebViewer.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 12/19/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "TDWebViewer.h"
#import "TDDefines.h"
#import "TDWatchProfile.h"
#import "TDAppDelegate.h"

@interface TDWebViewer ()
{
    IBOutlet UIWebView * myWebView;
    
    NSURL * urlToHit;
    BOOL    scaleToFit;
    id fromVC;
    BOOL isEula;
    UIActivityIndicatorView *indicatorView;
}
@end

@implementation TDWebViewer

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andURLtoVisit: (NSURL *) url scaleToFitFlag: (BOOL) scaleFlag fromVC:(id)caller isEula:(BOOL)eula
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        if (url != nil)
        {
            urlToHit = url;
            scaleToFit = scaleFlag;
            fromVC = caller;
            isEula = eula;
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
    
    myWebView.scalesPageToFit = scaleToFit;
    
    NSURLRequest * newRequest = [NSURLRequest requestWithURL: urlToHit cachePolicy: NSURLRequestReloadRevalidatingCacheData timeoutInterval: 30];
    [myWebView loadRequest: newRequest];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        
        indicatorView.center = CGPointMake([[UIScreen mainScreen] bounds].size.width/2, [[UIScreen mainScreen] bounds].size.height/2);
        
        [myWebView addSubview:indicatorView];
        
        [indicatorView startAnimating];
    });
    
    if (isEula) {
        myWebView.hidden = YES;
    }

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ ||
        [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan ||
        ![[TDWatchProfile sharedInstance] watchStyle])
    {
        UIButton *backBtn = [iDevicesUtil getBackButton];
        [backBtn addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
        self.navigationItem.leftBarButtonItem = barBtn;
        [((TDAppDelegate *)[[UIApplication sharedApplication] delegate]) setNavigationBarSettingsForM328:self.navigationController];
    }
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [indicatorView stopAnimating];
        [indicatorView setHidden:YES];
    });
    
    if (isEula) { // To fix artf26998
        int fontSize = 350;
        NSString *jsString = [[NSString alloc] initWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%d%%'", fontSize];
        [myWebView stringByEvaluatingJavaScriptFromString:jsString];
        [self performSelector:@selector(unhideWebView) withObject:nil afterDelay:0.5];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [indicatorView stopAnimating];
        [indicatorView setHidden:YES];
        
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString([error localizedDescription], nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    });
}

- (void)unhideWebView {
    myWebView.hidden = NO;
}
- (void) backButtonTapped {
    [self.navigationController popViewControllerAnimated:YES];
}
- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}
- (void)viewWillDisappear:(BOOL)animated {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(unhideWebView) object:nil];
}
@end
