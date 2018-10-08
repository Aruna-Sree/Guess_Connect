//
//  SleepHistoryTableViewCell.m
//  Timex
//
//  Created by Aruna Kumari Yarra on 19/05/16.
//

#import "SleepHistoryTableViewCell.h"
#import "TDDefines.h"
#import "TDAppDelegate.h"
//#import "Goals.h"
#import "iDevicesUtil.h"
#import "OTLogUtil.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "TDWatchProfile.h"
@implementation SleepHistoryTableViewCell
@synthesize sleepDetailLbl, progessView;
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)executeSegments:(NSString *)information andSide:(BOOL)side hours: (float )hours {
    @autoreleasepool {
        if (self.progessView.layer.sublayers.count > 1) {
            self.progessView.layer.sublayers = nil;
        }
        
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            //Sgment Color
            NSString * newString = [information substringWithRange:NSMakeRange(0, 1)];
            
            if ([newString isEqualToString:M328_SLEEP_AWAKE_STR]) {
                choiceColor = M328_HOME_SLEEP_AWAKE_COLOR;
                
            } else if ([newString isEqualToString:M328_SLEEP_LIGHT_STR]) {
                choiceColor = M328_HOME_SLEEP_LIGHT_COLOR;
                
            } else if ([newString isEqualToString:M328_SLEEP_DEEP_STR]) {
                choiceColor = M328_HOME_SLEEP_DARK_COLOR;
            }
            //Radius of circle * number 30 is to set center the arc, it could be chhanged
            radiusSegment = self.progessView.bounds.size.width;
            //Line
            SegmentWidth = self.progessView.frame.size.height;
            //Start and End points
            segementStart = 0.5f;
            segementEnd   = 1.0f;
            
            //number of segments
            for (int i = 0; i< information.length; i++) {
                //Background Thread
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    //Draw segment
                    [self addSegement:SegmentWidth andArcRadius:radiusSegment andStrokeStart:segementStart andStrokeEnd:segementEnd  andShadowRadius:0.0 andShadowOpacity:0.0 andShadowOffsset:CGSizeZero andChoiceColor:choiceColor andSide:TRUE andHours:hours];
                    //Sett new values
                    float result = .5 / information.length;
                    //NSLog(@"DiegoSantiagoREsultArch: %f",result);
                    segementStart = segementStart + result;//0.6f;
                    segementEnd   = segementEnd + result;//0.7f;
                    NSString * newString = [information substringWithRange:NSMakeRange(i, 1)];
                    
                    if ([newString isEqualToString:M328_SLEEP_AWAKE_STR]) {
                        choiceColor = M328_HOME_SLEEP_AWAKE_COLOR;
                        
                    } else if ([newString isEqualToString:M328_SLEEP_LIGHT_STR]) {
                        choiceColor = M328_HOME_SLEEP_LIGHT_COLOR;
                        
                    } else if ([newString isEqualToString:M328_SLEEP_DEEP_STR]) {
                        choiceColor = M328_HOME_SLEEP_DARK_COLOR;
                    }
                });
            }
        });
        self.progessView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    }
}

- (void)addSegement:(CGFloat)lineWidth andArcRadius:(int)ArcRadius andStrokeStart:(CGFloat)StrokeStart andStrokeEnd:(CGFloat)StrokeEnd andShadowRadius:(CGFloat)ShadowRadius andShadowOpacity:(CGFloat)ShadowOpacity andShadowOffsset:(CGSize)ShadowOffsset andChoiceColor:(UIColor *)colorBar andSide:(BOOL)side andHours:(float)hours{
    
    
    //Cordinate
    int X = self.progessView.bounds.size.width; //(CGRectGetMidX(self.view.bounds)/2);
    int Y = self.progessView.bounds.origin.y ; //+ self.arcView.frame.size.height;//(CGRectGetMidY(self.view.bounds)/2);
    
    //Create the layer to put inthere the segment
    CAShapeLayer *arc = [CAShapeLayer layer];
    
    float segmentsTotal = self.progessView.bounds.size.width;
    CGFloat goal = 0;
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ) {
        NSDictionary *goalsDict = [[NSUserDefaults standardUserDefaults] valueForKey: [iDevicesUtil getGoalTypeStringFormat:(GoalType)[TDM328WatchSettingsUserDefaults goalType]]];
        goal = [[goalsDict objectForKey:SLEEPTIME] doubleValue];
    } else {
        NSString * key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372_PropertyClass_Goals andIndex: appSettingsM372_PropertyClass_Goals_Sleep];
        goal = (CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey: key]/10;
    }
    
    segmentsTotal = segmentsTotal / goal;
    
    segmentsTotal = segmentsTotal * hours;
    
    if (segmentsTotal >= self.progessView.bounds.size.width)
        segmentsTotal = self.progessView.bounds.size.width;
    
    
    [arc setPath:[[UIBezierPath bezierPathWithRect:CGRectMake(X, Y, segmentsTotal -(segmentsTotal *2), 0)] CGPath]];
    
    
    //Set up the layer
    arc.lineWidth     = lineWidth;
    arc.strokeStart   = StrokeStart;
    arc.strokeEnd     = StrokeEnd;
    arc.strokeColor   = [colorBar CGColor];
    arc.fillColor     = [UIColor blackColor].CGColor;
    arc.shadowColor   = [UIColor blackColor].CGColor;
    arc.shadowOpacity = ShadowOpacity;
    arc.shadowOffset  = ShadowOffsset;
    arc.shadowRadius  = ShadowRadius;
    
    @autoreleasepool {
        [self.progessView.layer addSublayer:arc];
    }
}


@end
