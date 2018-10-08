//
//  TDConnectionStatusWindow.m
//  TabPopupTest
//
//  Created by Marin Todorov on 05/09/2012.
//

// MIT License
//
// Copyright (C) 2012 Marin Todorov
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "TDConnectionStatusWindow.h"
#import "TDWatchProfile.h"
#import "TDDeviceManager.h"
#import "PCCommWhosThere.h"
#import "PCCommChargeInfo.h"
#import "BLEManager.h"
#import "WhichApp.h"
#import "MFSideMenuContainerViewController.h"
#import "TDAppDelegate.h"
#import "SideMenuViewController.h"
#import "OTLogUtil.h"
#import "TDDefines.h"

#define kCloseBtnDiameter 30
#define kDefaultMargin 18
static CGSize kWindowMarginSize;

//
// Interface to declare the private class variables
//
@interface TDConnectionStatusWindow()
{
    UIView* _dimView;
    UIView* _bgView;
    UIActivityIndicatorView* _loader;
    
    BOOL mDoActionPostFirmwareUpdateRestart;
}

@property (nonatomic, readonly) TDConnectionStatus_PurposeEnum dialogPurpose;
@end

//
// The close button has its own class to implement
// the custom drawing method
//
@interface TDConnectionStatusWindowCloseButton : UIButton
+ (id)buttonInView:(UIView*)v;
@end

//
// Few helper methods to make maximizing windows
// setting ui elements sizes, and positioning
// easier
//
@interface UIView(TDConnectionStatusWindowLayoutShortcuts)
-(void)replaceConstraint:(NSLayoutConstraint*)c;
-(void)layoutCenterInView:(UIView*)v;
-(void)layoutInView:(UIView*)v setSize:(CGSize)s;
-(void)layoutMaximizeInView:(UIView*)v withInsetW:(float)insetW andInsetH: (float) insetH withVerticalOffset: (float) offsetV andHorizontalOffset: (float) offsetH;
-(void)layoutMaximizeInView:(UIView*)v withInsetSize:(CGSize)insetSize withVerticalOffset: (float) offsetV andHorizontalOffset: (float) offsetH;
@end


@implementation TDConnectionStatusWindow
@synthesize delegate = _delegate;
@synthesize currentWatchRepresentation = _currentWatchRepresentation;
@synthesize buildString = _buildString;
@synthesize connectionStatus = _connectionStatus;
@synthesize dialogPurpose = _dialogPurpose;

+ (void)initialize
{
    kWindowMarginSize = CGSizeMake(kDefaultMargin, kDefaultMargin);
}

+(void)setWindowMargin:(CGSize)margin
{
    kWindowMarginSize = margin;
}



/**
 * Inject setupUI into the init initializer
 */
-(id)initFor: (TDConnectionStatus_PurposeEnum) purpose
{
    self = [super init];
    if (self)
    {
        //customzation
        [self setupUI];
        
        _dialogPurpose = purpose;
        if (_dialogPurpose == TDConnectionStatus_PurposeConnectionStatus)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchInfoRead:) name: kTDWatchInfoReadSuccessfullyNotification object: nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchInfoReadFailed:) name: kTDWatchInfoReadUnsuccessfullyNotification object: nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchChargeInfoRead:) name: kTDWatchChargeInfoReadSuccessfullyNotification object: nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchChargeInfoReadFailed:) name: kTDWatchChargeInfoReadUnsuccessfullyNotification object: nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchInfoReadFailed:) name: kBLEManagerDisconnectedPeripheralNotification object: nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(RequestWatchInformationWithDelay) name: kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object: nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FirmwareUpdatedResumed) name: kTDFirmwareUpdateResumed object: nil];
            
            mDoActionPostFirmwareUpdateRestart = NO;
        }
        else if (_dialogPurpose == TDConnectionStatus_PurposePhoneFinderStatus)
        {
            //for TDConnectionStatus_PurposeConnectionStatus, we are not allowing orientation change
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
        }
    }
    return self;
}

- (void)dealloc
{
    if (_dialogPurpose == TDConnectionStatus_PurposeConnectionStatus)
    {
        [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDWatchInfoReadSuccessfullyNotification object: nil];
        [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDWatchInfoReadUnsuccessfullyNotification object: nil];
        [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDWatchChargeInfoReadSuccessfullyNotification object: nil];
        [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDWatchChargeInfoReadUnsuccessfullyNotification object: nil];
        [[NSNotificationCenter defaultCenter] removeObserver: self name: kBLEManagerDisconnectedPeripheralNotification object: nil];
        [[NSNotificationCenter defaultCenter] removeObserver: self name: kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object: nil];
        [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDFirmwareUpdateResumed object: nil];
    }
    else if (_dialogPurpose == TDConnectionStatus_PurposePhoneFinderStatus)
    {
        [[NSNotificationCenter defaultCenter] removeObserver: self name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    }
}

/**
 * Shows the popup window in the root view controller
 */
-(void)show
{
    UIView* view = [[UIApplication sharedApplication] keyWindow].rootViewController.view;
    [self showInView:view];
}

/**
 * Adds a hierarchy of views to the target view
 * then calls the method to animate the popup window in
 *
 *  v is the target view
 *  +- _dimView - a semi-opaque black background
 *  +- _bgView - the container of the popup window
 *    +- self - this is the popup window instance
 *      +- self.webView - is the web view to show your HTML content
 *      +- btnClose - the custom close button
 *    +- fauxView - an empty view, where the popup window animates into
 *
 * @param UIView* v The view to add the popup window to
 */
-(void)showInView:(UIView*)v
{
    //add the dim layer behind the popup
    _dimView = [[UIView alloc] init];
    [v addSubview: _dimView];
    [_dimView layoutMaximizeInView:v withInsetW:0 andInsetH: 0 withVerticalOffset: 0.0 andHorizontalOffset: 0.0];
    UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closePopupWindow)];
    [_dimView addGestureRecognizer:singleFingerTap];
    
    //add the popup container
    _bgView = [[UIView alloc] init];
    [v addSubview: _bgView];
    
    [_bgView layoutMaximizeInView:v withInsetW: [WhichApp iPhone] ?  50 : 483 andInsetH: [WhichApp iPhone] ?  (IS_WIDESCREEN ? 120 : 50) : 457 withVerticalOffset: 0.0 andHorizontalOffset: 0.0];
    
    [self positionControls];

    // Attempt to alert the delegate.
    if ([_delegate respondsToSelector:@selector(willShowTDConnectionStatusWindow:)])
        [_delegate willShowTDConnectionStatusWindow:self];
  
    //animate the popup window in
    [self performSelector:@selector(animatePopup:) withObject:v afterDelay:0.01];
    
    //only request this if the purpose of the dialog is to get connection status
    if (_dialogPurpose == TDConnectionStatus_PurposeConnectionStatus)
    {
        [self RequestWatchInformation];
    }
}

- (void) orientationChanged
{
    MFSideMenuContainerViewController * mainController = (MFSideMenuContainerViewController *)[[UIApplication sharedApplication] keyWindow].rootViewController;
    UIDeviceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
    NSUInteger supportedOrientations = [mainController supportedInterfaceOrientations];
    
    if (supportedOrientations & (1 << currentOrientation))
    {
        //first, remove all subviews because we are going to reposition them according to the new orientation
        while([self.subviews count] > 0)
        {
            [[self.subviews objectAtIndex: 0] removeFromSuperview];
        }
    
        [self positionControls];
    }
}

- (void) positionControls
{
    self.currentWatchRepresentation = [[UIImageView alloc] init];
    self.currentWatchRepresentation.contentMode = UIViewContentModeScaleAspectFit;
    timexDatalinkWatchStyle currentStyle = [[TDWatchProfile sharedInstance] watchStyle];
    if (currentStyle == timexDatalinkWatchStyle_ActivityTracker)
        [self.currentWatchRepresentation setImage: [UIImage imageNamed: @"watch_M053"]];
    else
        [self.currentWatchRepresentation setImage: [UIImage imageNamed: @"watch_M054"]];
    [self addSubview: self.currentWatchRepresentation];
    
    [self.currentWatchRepresentation layoutMaximizeInView:self withInsetW:0 andInsetH: 50 withVerticalOffset: 0.0 andHorizontalOffset: 0.0];
    self.currentWatchRepresentation.userInteractionEnabled = NO;
    
    self.connectionStatus = [[UILabel alloc] init];
    self.connectionStatus.font = [UIFont fontWithName: [iDevicesUtil getAppWideBoldFontName] size: 18];
    self.connectionStatus.textAlignment = NSTextAlignmentCenter;
    [self.connectionStatus setTextColor: [UIColor blackColor]];
    
    if (_dialogPurpose == TDConnectionStatus_PurposeConnectionStatus)
    {
        if ([[TDDeviceManager sharedInstance] isWatchConnected])
            self.connectionStatus.text = NSLocalizedString(@"CONNECTED", nil);
        else
        {
            [self.connectionStatus setTextColor: [UIColor redColor]];
            self.connectionStatus.text = NSLocalizedString(@"NOT CONNECTED", nil);
        }
    }
    else if (_dialogPurpose == TDConnectionStatus_PurposePhoneFinderStatus)
        self.connectionStatus.text = NSLocalizedString(@"PHONE FINDER ON", nil);
    
    [self addSubview: self.connectionStatus];
    
    MFSideMenuContainerViewController * mainController = (MFSideMenuContainerViewController *)[[UIApplication sharedApplication] keyWindow].rootViewController;
    UIDeviceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
    NSUInteger supportedOrientations = [mainController supportedInterfaceOrientations];
    
    if ((currentOrientation == UIDeviceOrientationLandscapeLeft || currentOrientation == UIDeviceOrientationLandscapeRight) && supportedOrientations & UIInterfaceOrientationMaskLandscapeLeft)
        [self.connectionStatus layoutMaximizeInView:self withInsetW:0 andInsetH: 0 withVerticalOffset: 0 andHorizontalOffset: [WhichApp iPhone] ?  -150.0 : -170.0];
    else
        [self.connectionStatus layoutMaximizeInView:self withInsetW:0 andInsetH: 0 withVerticalOffset: -150.0 andHorizontalOffset: 0.0];
    
    
    self.buildString = [[UILabel alloc] init];
    self.buildString.textAlignment = NSTextAlignmentCenter;

    if (_dialogPurpose == TDConnectionStatus_PurposeConnectionStatus)
    {
        self.buildString.font = [UIFont fontWithName: [iDevicesUtil getAppWideBoldFontName] size: 14];
        self.buildString.text = [self _getConnectionStatusBottomString];
        self.buildString.numberOfLines = 3;
    }
    else if (_dialogPurpose == TDConnectionStatus_PurposePhoneFinderStatus)
    {
        self.buildString.font = [UIFont fontWithName: [iDevicesUtil getAppWideBoldFontName] size: 18];
        self.buildString.text = NSLocalizedString(@"YOU FOUND ME!", nil);
        self.buildString.numberOfLines = 1;
    }
    
    [self addSubview: self.buildString];
    
    if ((currentOrientation == UIDeviceOrientationLandscapeLeft || currentOrientation == UIDeviceOrientationLandscapeRight) && supportedOrientations & UIInterfaceOrientationMaskLandscapeLeft)
        [self.buildString layoutMaximizeInView:self withInsetW:0 andInsetH: 0.0 withVerticalOffset: 0 andHorizontalOffset: [WhichApp iPhone] ? 150.0 : 170];
    else
        [self.buildString layoutMaximizeInView:self withInsetW:0 andInsetH: 0 withVerticalOffset: 170.0 andHorizontalOffset: 0.0];
    
    
    //make the close button
    TDConnectionStatusWindowCloseButton* btnClose = [TDConnectionStatusWindowCloseButton buttonInView:self];
    [btnClose addTarget:self action:@selector(closePopupWindow) forControlEvents:UIControlEventTouchUpInside];
}

- (NSString *) _getConnectionStatusBottomString
{
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice == nil || ([timexDevice isFirmwareUpgradeInProgress] == FALSE && [timexDevice isFirmwareUpgradePaused] == FALSE))
        return nil;
    else
        return NSLocalizedString(@"UPLOADING FIRMWARE", nil);
}

- (void) WatchInfoRead: (NSNotification*)notification
{
    [self.connectionStatus setTextColor: [UIColor blackColor]];
    self.connectionStatus.text = NSLocalizedString(@"CONNECTED", nil);
    
    PCCommWhosThere * newSettings = [notification.userInfo objectForKey: kDeviceWatchInfoKey];
    if (newSettings)
    {
        NSString * mappedName = [iDevicesUtil convertTimexModuleStringToProductName: newSettings.mModelNumber];
        if (mappedName == nil)
            mappedName = newSettings.mModelNumber;
        
        if ([self _getConnectionStatusBottomString])
        {
            self.buildString.text = [NSString stringWithFormat: @"%@  %@ %@\n%@ %@\n%@", mappedName, NSLocalizedString(@"S/N", nil), newSettings.mSerialNumber, NSLocalizedString(@"Firmware", nil), [newSettings.mProductRev stringByReplacingOccurrencesOfString:@" " withString:@""], [self _getConnectionStatusBottomString]];
        }
        else
        {
            self.buildString.text = [NSString stringWithFormat: @"%@  %@ %@\n%@ %@", mappedName, NSLocalizedString(@"S/N", nil), newSettings.mSerialNumber, NSLocalizedString(@"Firmware", nil), [newSettings.mProductRev stringByReplacingOccurrencesOfString:@" " withString:@""]];
        }

        
        
        PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
        if (timexDevice && [timexDevice isFirmwareUpgradePaused])
        {
            mDoActionPostFirmwareUpdateRestart = YES;
        }
        else
        {
            [self RequestWatchChargheInformation];
        }
    }
}
- (void) WatchInfoReadFailed: (id) sender
{
    [self.connectionStatus setTextColor: [UIColor redColor]];
    self.connectionStatus.text = NSLocalizedString(@"NOT CONNECTED", nil);
    self.buildString.text = [self _getConnectionStatusBottomString];
}

- (void) WatchChargeInfoRead: (NSNotification*)notification
{
    PCCommChargeInfo * chargeInfo = [notification.userInfo objectForKey: kDeviceWatchChargeInfoKey];
    if (chargeInfo)
    {
        [[NSUserDefaults standardUserDefaults] setFloat:chargeInfo.voltage forKey:KEY_BATTERRY_CHARGE_M372];
        
        if (self.buildString.text == nil)
        {
            OTLog(@"build string is NULL");
        }
        else
        {
            NSMutableString * current = [NSMutableString stringWithString: self.buildString.text];
            
            if ([self _getConnectionStatusBottomString])
            {
                NSRange rangeTWTR = [current rangeOfString: [self _getConnectionStatusBottomString] options: NSCaseInsensitiveSearch];
                NSRange rangeBattery = [current rangeOfString: NSLocalizedString(@"Battery", nil) options: NSCaseInsensitiveSearch];
                if ( rangeBattery.location == NSNotFound && rangeTWTR.location != NSNotFound && rangeTWTR.location > 0 && [current characterAtIndex: rangeTWTR.location - 1] == 0xA) //NewLine character
                {
                    [current insertString: [NSString stringWithFormat: @"  %@ %.0f%%", NSLocalizedString(@"Battery", nil), chargeInfo.charge] atIndex: rangeTWTR.location - 1];
                    self.buildString.text = current;
                }
            }
            else
            {
                NSRange rangeBattery = [current rangeOfString: NSLocalizedString(@"Battery", nil) options: NSCaseInsensitiveSearch];
                if ( rangeBattery.location == NSNotFound)
                {
                    [current appendString: [NSString stringWithFormat: @"  %@ %.0f%%", NSLocalizedString(@"Battery", nil), chargeInfo.charge]];
                    if (chargeInfo.USBStatus)
                    {
                        [current appendString: [NSString stringWithFormat: @"\n%@", NSLocalizedString(@"(PLUGGED IN)", nil)]];
                    }
                    self.buildString.text = current;
                }
            }
        }
    }
}
- (void) WatchChargeInfoReadFailed: (id) sender
{
    
}
- (void) FirmwareUpdatedResumed
{
    if (mDoActionPostFirmwareUpdateRestart)
    {
        mDoActionPostFirmwareUpdateRestart = NO;
        [self RequestWatchChargheInformation];
    }
}
- (void) RequestWatchInformationWithDelay
{
    //we need a delay because when we get the notification, the DeviceManager is not yet aware of that device... the delay takes care of that
    [self performSelector:@selector(RequestWatchInformation) withObject:nil afterDelay: 1];
    OTLog(@"RequestWatchInformationWithDelay executed");
}
- (void) RequestWatchInformation
{
    OTLog(@"RequestWatchInformation executed");
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice != nil)
    {
        [timexDevice requestDeviceInfo];
    }
}
- (void) RequestWatchChargheInformation
{
    OTLog(@"RequestWatchChargeInformation executed");
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice != nil)
    {
        [timexDevice requestDeviceChargeInfo];
    }
}

/**
 * Adds a blank view and then animates the popup window
 * into the parent view
 *
 * @param UIView* v the parent view to do the animations in
 */
-(void)animatePopup:(UIView*)v
{
    __weak TDConnectionStatusWindow * weakSelf = self;
    
    //add the faux view to transition from
    UIView* fauxView = [[UIView alloc] init];
    fauxView.backgroundColor = [UIColor redColor];
    [_bgView addSubview: fauxView];

    [fauxView layoutMaximizeInView:_bgView withInsetW: kDefaultMargin andInsetH: kDefaultMargin withVerticalOffset: 0.0 andHorizontalOffset: 0.0];

    //animation options
    UIViewAnimationOptions options =
        UIViewAnimationOptionTransitionFlipFromRight |
        UIViewAnimationOptionAllowUserInteraction    |
        UIViewAnimationOptionBeginFromCurrentState;
    
    //run the animations
    [UIView transitionWithView:_bgView
                      duration:0.4
                       options:options
                    animations:^{
                        
                        //replace the blank view with the popup window
                        [fauxView removeFromSuperview];
                        [_bgView addSubview: self];
                        
                        //maximize the popup window in the parent view
                        TDConnectionStatusWindow * strongSelf = weakSelf;
                        [strongSelf layoutMaximizeInView:_bgView withInsetSize: kWindowMarginSize withVerticalOffset: 0.0 andHorizontalOffset: 0.0];
                        
                        //turn the background view to black color
                        _dimView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
                        
                    } completion:^(BOOL finished) {
                        //OTLog(@"Finsihed");
                      
                        // Attempt to alert the delegate.
                        if ([_delegate respondsToSelector:@selector(didShowTDConnectionStatusWindow:)])
                            [_delegate didShowTDConnectionStatusWindow:self];
                    }];
}

/**
 * Closes the popup window
 * the method animates the popup window out
 * and removes it from the view hierarchy
 */
-(void)closePopupWindow
{
    __weak TDConnectionStatusWindow * weakSelf = self;
    if (_dialogPurpose == TDConnectionStatus_PurposeConnectionStatus)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDWatchInfoReadSuccessfullyNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDWatchInfoReadUnsuccessfullyNotification object:nil];
    }
    
    // Attempt to alert the delegate.
    if ([_delegate respondsToSelector:@selector(willCloseTDConnectionStatusWindow:)])
        [_delegate willCloseTDConnectionStatusWindow:self];
  
    //animation options
    UIViewAnimationOptions options =
        UIViewAnimationOptionTransitionFlipFromLeft |
        UIViewAnimationOptionAllowUserInteraction   |
        UIViewAnimationOptionBeginFromCurrentState;
    
    //animate the popup window out
    [UIView transitionWithView:_bgView
                      duration:0.4
                       options:options
                    animations:^{
                        
                        //fade out the black background
                        _dimView.backgroundColor = [UIColor clearColor];
                        
                        //remove the popup window from the view hierarchy
                        TDConnectionStatusWindow * strongSelf = weakSelf;
                        [strongSelf removeFromSuperview];
                        
                    } completion:^(BOOL finished) {
                        
                        //remove the container view
                        [_bgView removeFromSuperview];
                        _bgView = nil;
                        
                        //remove the black backgorund
                        [_dimView removeFromSuperview];
                        _dimView = nil;
                      
                        // Attempt to alert the delegate.
                        if ([_delegate respondsToSelector:@selector(didCloseTDConnectionStatusWindow:)])
                            [_delegate didCloseTDConnectionStatusWindow:self];
                    }];
}

/**
 * Sets up some basic UI properties
 */
-(void)setupUI
{
    self.layer.borderWidth = 2.0;
    self.layer.borderColor = [UIColor blackColor].CGColor;
    self.layer.cornerRadius = 15.0;
    self.backgroundColor = [UIColor whiteColor];
}
@end

/**
 * The close button for the popup window
 */
@implementation TDConnectionStatusWindowCloseButton

/**
 * creates a button instance and adds it as a subview to the view, passed as argument
 * the convenience method also creates all the autolayout constraints
 *
 * @param UIView* v - the view to add the close button to
 */
+ (id)buttonInView:(UIView*)v
{
    int closeBtnOffset = 5;
    
    //create button instance
    TDConnectionStatusWindowCloseButton* closeBtn = [TDConnectionStatusWindowCloseButton buttonWithType:UIButtonTypeCustom];
    if ([closeBtn respondsToSelector:@selector(setTranslatesAutoresizingMaskIntoConstraints:)]) {
        [closeBtn setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    [v addSubview: closeBtn];

    //create the contraints to stick the button
    //to the top-right corner of the parent view
    NSLayoutConstraint* rightc = [NSLayoutConstraint constraintWithItem: closeBtn
                                                              attribute: NSLayoutAttributeRight
                                                              relatedBy: NSLayoutRelationEqual
                                                                 toItem: v
                                                              attribute: NSLayoutAttributeRight
                                                             multiplier: 1.0f
                                                               constant: -closeBtnOffset];
    
    NSLayoutConstraint* topc = [NSLayoutConstraint constraintWithItem: closeBtn
                                                            attribute: NSLayoutAttributeTop
                                                            relatedBy: NSLayoutRelationEqual
                                                               toItem: v
                                                            attribute: NSLayoutAttributeTop
                                                           multiplier: 1.0f
                                                             constant: closeBtnOffset];
    
    NSLayoutConstraint* wwidth = [NSLayoutConstraint constraintWithItem: closeBtn
                                                              attribute: NSLayoutAttributeWidth
                                                              relatedBy: NSLayoutRelationEqual
                                                                 toItem: v
                                                              attribute: NSLayoutAttributeWidth
                                                             multiplier: 0.0f
                                                               constant: kCloseBtnDiameter];
    
    NSLayoutConstraint* hheight = [NSLayoutConstraint constraintWithItem: closeBtn
                                                               attribute: NSLayoutAttributeHeight
                                                               relatedBy: NSLayoutRelationEqual
                                                                  toItem: v
                                                               attribute: NSLayoutAttributeHeight
                                                              multiplier: 0.0f
                                                                constant: kCloseBtnDiameter];
    //replace the automatically created constraints
    [v replaceConstraint: topc];
    [v replaceConstraint: rightc];
    [v replaceConstraint: wwidth];
    [v replaceConstraint: hheight];
    
    //return the instance
    return closeBtn;
}

/**
 * Draw a circle with a X inside
 */
- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGContextAddEllipseInRect(ctx, CGRectOffset(rect, 0, 0));
    CGContextSetFillColor(ctx, CGColorGetComponents([[UIColor colorWithRed:0.66 green:0.66 blue:0.66 alpha:1] CGColor]));
    CGContextFillPath(ctx);

    CGContextAddEllipseInRect(ctx, CGRectInset(rect, 1, 1));
    CGContextSetFillColor(ctx, CGColorGetComponents([[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1] CGColor]));
    CGContextFillPath(ctx);

    CGContextAddEllipseInRect(ctx, CGRectInset(rect, 4, 4));
    CGContextSetFillColor(ctx, CGColorGetComponents([[UIColor colorWithRed:1 green:1 blue:1 alpha:1] CGColor]));
    CGContextFillPath(ctx);
    
    
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1].CGColor);
    CGContextSetLineWidth(ctx, 3.0);
    CGContextMoveToPoint(ctx, kCloseBtnDiameter/4+1,kCloseBtnDiameter/4+1); //start at this point
    CGContextAddLineToPoint(ctx, kCloseBtnDiameter/4*3+1,kCloseBtnDiameter/4*3+1); //draw to this point
    CGContextStrokePath(ctx);

    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1].CGColor);
    CGContextSetLineWidth(ctx, 3.0);
    CGContextMoveToPoint(ctx, kCloseBtnDiameter/4*3+1,kCloseBtnDiameter/4+1); //start at this point
    CGContextAddLineToPoint(ctx, kCloseBtnDiameter/4+1,kCloseBtnDiameter/4*3+1); //draw to this point
    CGContextStrokePath(ctx);
}

@end

//
// Few handy helper methods as a category to UIView
// to help building contraints
//
@implementation UIView(TDConnectionStatusWindowLayoutShortcuts)

-(void)replaceConstraint:(NSLayoutConstraint*)c
{
    for (int i=0;i<[self.constraints count];i++) {
        NSLayoutConstraint* c1 = self.constraints[i];
        if (c1.firstItem==c.firstItem && c1.firstAttribute == c.firstAttribute) {
            [self removeConstraint:c1];
        }
    }
    [self addConstraint:c];
}

-(void)layoutCenterInView:(UIView*)v
{
    if ([self respondsToSelector:@selector(setTranslatesAutoresizingMaskIntoConstraints:)]) {
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    
    NSLayoutConstraint* centerX = [NSLayoutConstraint constraintWithItem: self
                                                               attribute: NSLayoutAttributeCenterX
                                                               relatedBy: NSLayoutRelationEqual
                                                                  toItem: v
                                                               attribute: NSLayoutAttributeCenterX
                                                              multiplier: 1.0f
                                                                constant: 0.0f];
    
    NSLayoutConstraint* centerY = [NSLayoutConstraint constraintWithItem: self
                                                               attribute: NSLayoutAttributeCenterY
                                                               relatedBy: NSLayoutRelationEqual
                                                                  toItem: v
                                                               attribute: NSLayoutAttributeCenterY
                                                              multiplier: 1.0f
                                                                constant: 0.0f];
    
    [v replaceConstraint:centerX];
    [v replaceConstraint:centerY];
    
    [v setNeedsLayout];
}

-(void)layoutInView:(UIView*)v setSize:(CGSize)s
{
    if ([self respondsToSelector:@selector(setTranslatesAutoresizingMaskIntoConstraints:)]) {
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    
    NSLayoutConstraint* wwidth = [NSLayoutConstraint constraintWithItem: self
                                                              attribute: NSLayoutAttributeWidth
                                                              relatedBy: NSLayoutRelationEqual
                                                                 toItem: v
                                                              attribute: NSLayoutAttributeWidth
                                                             multiplier: 0.0f
                                                               constant: s.width];
    
    NSLayoutConstraint* hheight = [NSLayoutConstraint constraintWithItem: self
                                                               attribute: NSLayoutAttributeHeight
                                                               relatedBy: NSLayoutRelationEqual
                                                                  toItem: v
                                                               attribute: NSLayoutAttributeHeight
                                                              multiplier: 0.0f
                                                                constant: s.height];
    [v replaceConstraint: wwidth];
    [v replaceConstraint: hheight];
    
    [v setNeedsLayout];
}

-(void)layoutMaximizeInView:(UIView*)v withInsetW:(float)insetW andInsetH: (float)insetH withVerticalOffset: (float) offsetV andHorizontalOffset: (float) offsetH
{
    [self layoutMaximizeInView:v withInsetSize:CGSizeMake(insetW, insetH) withVerticalOffset: offsetV andHorizontalOffset: offsetH];
}

-(void)layoutMaximizeInView:(UIView*)v withInsetSize:(CGSize)insetSize withVerticalOffset: (float) offsetV andHorizontalOffset: (float) offsetH
{
    if ([self respondsToSelector:@selector(setTranslatesAutoresizingMaskIntoConstraints:)]) {
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    
    NSLayoutConstraint* centerX = [NSLayoutConstraint constraintWithItem: self
                                                               attribute: NSLayoutAttributeCenterX
                                                               relatedBy: NSLayoutRelationEqual
                                                                  toItem: v
                                                               attribute: NSLayoutAttributeCenterX
                                                              multiplier: 1.0f
                                                                constant: offsetH];
    
    NSLayoutConstraint* centerY = [NSLayoutConstraint constraintWithItem: self
                                                               attribute: NSLayoutAttributeCenterY
                                                               relatedBy: NSLayoutRelationEqual
                                                                  toItem: v
                                                               attribute: NSLayoutAttributeCenterY
                                                              multiplier: 1.0f
                                                                constant: offsetV];
    
    NSLayoutConstraint* wwidth = [NSLayoutConstraint constraintWithItem: self
                                                              attribute: NSLayoutAttributeWidth
                                                              relatedBy: NSLayoutRelationEqual
                                                                 toItem: v
                                                              attribute: NSLayoutAttributeWidth
                                                             multiplier: 1.0f
                                                               constant: -insetSize.width];
    
    NSLayoutConstraint* hheight = [NSLayoutConstraint constraintWithItem: self
                                                               attribute: NSLayoutAttributeHeight
                                                               relatedBy: NSLayoutRelationEqual
                                                                  toItem: v
                                                               attribute: NSLayoutAttributeHeight
                                                              multiplier: 1.0f
                                                                constant: -insetSize.height];
    
    
    [v replaceConstraint: centerX];
    [v replaceConstraint: centerY];
    [v replaceConstraint: wwidth];
    [v replaceConstraint: hheight];
    
    [v setNeedsLayout];
}

@end
