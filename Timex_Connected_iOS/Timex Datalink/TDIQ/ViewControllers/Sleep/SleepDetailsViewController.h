//
//  SleepDetailsViewController.h
//  Timex
//
//  Created by Aruna Kumari Yarra on 20/05/16.
//

#import <UIKit/UIKit.h>
#import "CustomCollectionViewController.h"
#import "DBSleepEvents.h"
@interface SleepDetailsViewController : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate> {
    IBOutlet UITableView              *sleepDetailsTableView;
    IBOutlet UILabel                  *timeLabel;
    CustomCollectionViewController *collectionVC;
    DBSleepEvents *currentSleep;
    NSArray *sleepDetailsArray;
    NSInteger selectedRow;
    
    IBOutlet NSLayoutConstraint *tableViewBottomConstraint;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil workout: (DBSleepEvents *) sleep  sleepDetailsArray: (NSArray *) array selectedRow: (NSIndexPath *) selectedIndexPath;
@property (nonatomic) id caller;
@end
