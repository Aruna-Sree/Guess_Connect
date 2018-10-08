//
//  TDCustomCollectionViewCell.h
//  TableViewCellTest
//
//  Created by Aruna Kumari Yarra on 30/03/16.
//

#import <UIKit/UIKit.h>

@interface TDCustomCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomLabelHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *topLabelYSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topLblWidthConstarint;

@property (strong, nonatomic) IBOutlet UILabel *topLabel;
@property (strong, nonatomic) IBOutlet UILabel *bottomLabel;

- (void)setDataToAllViews:(NSArray *)array indexPath:(NSIndexPath *)indexPath;
@end
