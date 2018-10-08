//
//  EditSleepEventsViewController.h
//  timex
//
//  Created by Raghu on 10/04/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DBSleepEvents.h"

@interface EditSleepEventsViewController : UIViewController

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andCurrentSleep:(DBSleepEvents *) sleep;

@end
