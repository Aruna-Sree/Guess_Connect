//
//  TDWebViewer.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 12/19/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iDevicesUtil.h"
#import "TDRootViewController.h"

@interface TDWebViewer : TDRootViewController<UIWebViewDelegate>
{
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andURLtoVisit: (NSURL *) url scaleToFitFlag: (BOOL) scaleFlag fromVC:(id)caller isEula:(BOOL)eula;
@end
