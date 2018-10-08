//
//  AlignSubDialHandViewController.h
//  Timex
//
//  Created by kpasupuleti on 5/4/16.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface AlignHandViewController : UIViewController <MFMailComposeViewControllerDelegate> {
//    IBOutlet NSLayoutConstraint *nextButtonBottomContraint;
//    IBOutlet NSLayoutConstraint *viewWidthContraint;
//    IBOutlet UILabel *infoLabel;
//    
//    CGAffineTransform affTransform;
    
    IBOutlet UILabel *infoLabel;
    IBOutlet UILabel *progressLbl;
    
    IBOutlet UIView *warningView;
    IBOutlet UILabel *warningLbl;
    IBOutlet NSLayoutConstraint *infoLblTopConstraint;
    IBOutlet NSLayoutConstraint *infoLblleftConstraint;
    IBOutlet NSLayoutConstraint *infoLblRightConstraint;
    IBOutlet NSLayoutConstraint *infoLblBottomContraint;
    
    IBOutlet NSLayoutConstraint *progressLblWidthContraint;
    IBOutlet UIImageView *headerImg;

}
//@property (weak, nonatomic) IBOutlet UIView *handView;
//@property (weak, nonatomic) IBOutlet UIView *subDialHandView;
@property (weak, nonatomic) IBOutlet UIButton *nextBtn;
/**
 *  Tracks if the alignment is from initial setup or
 * from the calibration
 */
@property (nonatomic) BOOL isFromSetup;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil viewType:(int)handType;
@end
