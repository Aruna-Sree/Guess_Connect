//
//  AutoSyncViewController.h
//  timex
//
//  Created by Nick Graff on 9/6/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AutoSyncViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>
{
    __weak IBOutlet UITableView *syncTableView;
    IBOutlet UILabel *topLbl;
}
@end
