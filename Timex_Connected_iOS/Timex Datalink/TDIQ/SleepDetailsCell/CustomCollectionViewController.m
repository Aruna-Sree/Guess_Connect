//
//  CustomCollectionViewController.m
//  TableViewCellTest
//
//  Created by Aruna Kumari Yarra on 30/03/16.
//

#import "CustomCollectionViewController.h"
#import "TDCustomCollectionViewCell.h"
#import "OTLogUtil.h"
#import "SleepExplanationPopup.h"
#import "TDDefines.h"
#import "TDAppDelegate.h"

@interface CustomCollectionViewController ()

@end

@implementation CustomCollectionViewController

NSString *reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.collectionView registerNib:[UINib nibWithNibName:@"TDCustomCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:reuseIdentifier];
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
}

- (void)didReceiveMemoryWarning {
     OTLog([NSString stringWithFormat:@"Recived Memory Warning  in %@ ",NSStringFromClass([self class])]);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.view layoutIfNeeded];
}
- (void) reloadCollectionView:(NSArray *)array {
    list = array;
    [self.collectionView reloadData];
}

#pragma mark <UICollectionViewDataSource>
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 3;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = ScreenWidth/([collectionView numberOfItemsInSection:indexPath.section]);
    CGFloat height = self.view.frame.size.height/([collectionView numberOfSections]);
    return CGSizeMake(width,height);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TDCustomCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.layer.borderWidth = 0.3f;
    cell.layer.borderColor = [UIColor lightGrayColor].CGColor;
    cell.layer.masksToBounds = YES;
    [cell setDataToAllViews:list indexPath:indexPath];
    return cell;
}

#pragma mark <UICollectionViewDelegate>
/*
 // Uncomment this method to specify if the specified item should be highlighted during tracking
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
 }



 // Uncomment this method to specify if the specified item should be selected
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
     return YES;
 }
 */
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        SleepExplanationPopup *popup = [[SleepExplanationPopup alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
        [popup setImageNDescriptionBasedOnSleepType:(int)indexPath.row];
        TDAppDelegate *appDel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDel.window addSubview:popup];
    }
}

/*
 // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
 }
 
 - (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
 }
 
 - (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
     NSLog(@"collectionView selected item \n Row : %ld        Section : %ld",indexPath.row, indexPath.section);
 }
 */
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
