//
//  CustomCollectionViewController.h
//  TableViewCellTest
//
//  Created by Aruna Kumari Yarra on 30/03/16.
//

#import <UIKit/UIKit.h>


@interface CustomCollectionViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout> {
    NSArray *list;
}
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
- (void) reloadCollectionView:(NSArray *)array;
@end
