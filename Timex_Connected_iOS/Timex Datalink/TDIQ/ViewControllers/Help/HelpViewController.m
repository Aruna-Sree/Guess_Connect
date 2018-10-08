//
//  HelpViewController.m
//  Timex
//
//  Created by Aruna Kumari Yarra on 27/06/16.
//

#import "HelpViewController.h"
#import "TDDefines.h"
#import "iDevicesUtil.h"
#import "MFSideMenuContainerViewController.h"
#import "SideMenuViewController.h"
#import "TDAppDelegate.h"
#import "OTLogUtil.h"
#import "TDWatchProfile.h"

@interface HelpViewController () {
    BOOL isSync;
    WKWebView *webView;
}

@end

@implementation HelpViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil fromSync:(BOOL)isSync_ {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        isSync = isSync_;
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
   
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
    if (![iDevicesUtil hasInternetConnectivity]){
        TDAppDelegate *appDelegate = (TDAppDelegate *)[[UIApplication sharedApplication]delegate];
        [appDelegate showAlertWithTitle:NSLocalizedString(@"Guess Connect",nil) Message:NSLocalizedString(@"The Internet connection appears to be offline",nil) andButtonTitle:NSLocalizedString(@"OK",nil)];
    }
    /*
    else
    {
        webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight) configuration:[[WKWebViewConfiguration alloc] init]];
        webView.UIDelegate = self;
        [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:TIMEX_HELP_IQ_URL]]];
        [self.view addSubview:webView];
    }
     */
//    if (isSync) {
//        UIButton *navBtn = [iDevicesUtil getBackButton];
//        [navBtn addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
//        UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:navBtn];
//        self.navigationItem.leftBarButtonItem = barBtn;
//    } else {
//        UIBarButtonItem *slideMenuItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(slideMenuTapped)];
//        self.navigationItem.leftBarButtonItem = slideMenuItem;
//    }
    

    if([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel) {
        [helpWebview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[TIMEX_HELP_TRAVEL_URL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]];
    }
    else {
        [helpWebview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[TIMEX_HELP_IQ_URL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]];
    }
    
    if (!isSync) {
        [self slideMenuTapped];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (isSync) {
        UIButton *navBtn = [iDevicesUtil getBackButton];
        [navBtn addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:navBtn];
        self.navigationItem.leftBarButtonItem = barBtn;
    }
}

- (void)didReceiveMemoryWarning {
     OTLog([NSString stringWithFormat:@"Recived Memory Warning  in %@ ",NSStringFromClass([self class])]);
    [super didReceiveMemoryWarning];
}

- (void)backButtonTapped {
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)slideMenuTapped {
    TDAppDelegate * delegate = (TDAppDelegate *)[UIApplication sharedApplication].delegate;
    SideMenuViewController *leftController = (SideMenuViewController *)((MFSideMenuContainerViewController *)delegate.window.rootViewController).leftMenuViewController;
    if (leftController == nil)
    {
        SideMenuViewController *leftController = [[SideMenuViewController alloc] init];
        ((MFSideMenuContainerViewController *)delegate.window.rootViewController).leftMenuViewController = leftController;
    }
}

- (void)updateButtons {
    if ([helpWebview isLoading]) {
        refershBtn.enabled = NO;
        backBtn.enabled = NO;
        nextBtn.enabled = NO;
    } else {
        refershBtn.enabled = YES;
        backBtn.enabled = [helpWebview canGoBack];
        nextBtn.enabled = [helpWebview canGoForward];
    }
}
#pragma mark WebView Delegate Methods
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return YES;
}
- (void)webViewDidStartLoad:(UIWebView *)webView_ {
    
    @try {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [self updateButtons];
    }
    @catch (NSException *exception) {
        OTLog(@"Exception At: %s %d %s %s %@", __FILE__, __LINE__, __PRETTY_FUNCTION__, __FUNCTION__,exception);
    }
    @finally {
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView_ {
    @try {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [self updateButtons];
    }
    @catch (NSException *exception) {
        //OTLog(@"Exception At: %s %d %s %s %@", __FILE__, __LINE__, __PRETTY_FUNCTION__, __FUNCTION__,exception);
    }
    @finally {
    }
}

- (void)webView:(UIWebView *)webView_ didFailLoadWithError:(NSError *)error {
    @try {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [self updateButtons];
    }
    @catch (NSException *exception) {
        //OTLog(@"Exception At: %s %d %s %s %@", __FILE__, __LINE__, __PRETTY_FUNCTION__, __FUNCTION__,exception);
    }
    @finally {
    }
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
