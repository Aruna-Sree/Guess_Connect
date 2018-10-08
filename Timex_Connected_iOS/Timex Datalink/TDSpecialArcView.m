//
//  TDSpecialArcView.m
//  Timex
//
//  Created by Diego Santiago on 5/11/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import "TDSpecialArcView.h"

@implementation TDSpecialArcView

- (void) awakeFromNib:(NSString *)segments hours:(float )hours
{
    [super awakeFromNib];
    
   
}

//- (void)executeSegments:(NSString *)information andSide:(BOOL)side{
//
//    CAShapeLayer *arc = [CAShapeLayer layer];
//    if (self.arcTest.layer.sublayers.count > 1)
//    {
//        NSMutableArray *arcsToDelete = [[NSMutableArray alloc]init];
//        for (arc in self.arcTest.layer.sublayers)
//        {
//            [arcsToDelete addObject:arc];
//        }
//        for (int x = 0; x < arcsToDelete.count; x++)
//        {
//            CAShapeLayer *arc = [arcsToDelete objectAtIndex:x];
//            [arc removeFromSuperlayer];
//        }
//    }
//    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
//        
//        //Radius of circle * number 30 is to set center the arc, it could be chhanged
//        _radiusSegment = self.arcTest.frame.size.width -65;
//        
//        //Segment Width
//        _SegmentWidth = 40;
//        
//        //Sgment Color
//        NSString * newString = [information substringWithRange:NSMakeRange(0, 1)];
//        if ([newString isEqualToString:@"A"])
//            _choiceColor = 2;
//        
//        else if ([newString isEqualToString:@"B"])
//            _choiceColor = 1;
//        
//        else if ([newString isEqualToString:@"C"])
//            _choiceColor = 0;
//        
//        //Start and End points
//        _segementStart = 0.5f;
//        _segementEnd   = 1.0f;
//        
//        //number of segments
//        for (int i=0; i< information.length; i++)
//        {
//            //Sleepy
//            //[NSThread sleepForTimeInterval:0.01f];
//            
//            //Background Thread
//            dispatch_async(dispatch_get_main_queue(), ^(void){
//                //Draw segment
//                [self addSegement:_SegmentWidth andArcRadius:_radiusSegment andStrokeStart:_segementStart andStrokeEnd:_segementEnd  andShadowRadius:0.0 andShadowOpacity:0.0 andShadowOffsset:CGSizeZero andChoiceColor:_choiceColor andSide:side];
//                //Sett new values
//                float result = .5 / information.length;
//                //NSLog(@"DiegoSantiagoREsultArch: %f",result);
//                _segementStart = _segementStart + result;//0.6f;
//                _segementEnd   = _segementEnd + result;//0.7f;
//                
//                NSString * newString = [information substringWithRange:NSMakeRange(i, 1)];
//                
//                if ([newString isEqualToString:@"A"])
//                {
//                    _choiceColor = 2;
//                }
//                
//                else if ([newString isEqualToString:@"B"])
//                {
//                    _choiceColor = 1;
//                }
//                
//                else if ([newString isEqualToString:@"C"])
//                {
//                    _choiceColor = 0;
//                }
//            });
//        }
//    });
//    
//    for (int i=0; i< information.length; i++)
//    {
//        
//        NSString * newString = [information substringWithRange:NSMakeRange(i, 1)];
//        
//        if ([newString isEqualToString:@"A"])
//        {
//            counterA = counterA + 1;
//        }
//        
//        else if ([newString isEqualToString:@"B"])
//        {
//            counterB = counterB +1;
//        }
//        
//        else if ([newString isEqualToString:@"C"])
//        {
//            counterC = counterC + 1;
//        }
//    }
//    float a = counterA + counterB;
//    float b = (float)information.length;
//    float c = a/b;
//    
//    if (c <= 1)
//        c = c * 100;
//    else
//        c = (c *10)/100;
//    
//    efficiency = c;
//}
//- (void)addSegement:(CGFloat)lineWidth andArcRadius:(int)ArcRadius andStrokeStart:(CGFloat)StrokeStart andStrokeEnd:(CGFloat)StrokeEnd andShadowRadius:(CGFloat)ShadowRadius andShadowOpacity:(CGFloat)ShadowOpacity andShadowOffsset:(CGSize)ShadowOffsset andChoiceColor:(int)ChoiceColor andSide:(BOOL)side{
//    
//    //Cordinate
//    int X = self.arcTest.frame.origin.x +35; //(CGRectGetMidX(self.view.bounds)/2);
//    int Y = self.arcTest.frame.origin.y +65;//+ self.arcView.frame.size.height;//(CGRectGetMidY(self.view.bounds)/2);
//    
//    //Create the layer to put inthere the segment
//    CAShapeLayer *arc = [CAShapeLayer layer];
//    
//    //Add figure inthere
//    [arc setPath:[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(X, Y, ArcRadius, ArcRadius)] CGPath]];
//    
//    //Creates the color
//    UIColor * colorBar = [self getColor:ChoiceColor];
//    
//    //Set up the layer
//    arc.lineWidth     = lineWidth;
//    arc.strokeStart   = StrokeStart;
//    arc.strokeEnd     = StrokeEnd;
//    arc.strokeColor   = [colorBar CGColor];
//    arc.fillColor     = [UIColor clearColor].CGColor;
//    arc.shadowColor   = [UIColor darkGrayColor].CGColor;
//    arc.shadowOpacity = ShadowOpacity;
//    arc.shadowOffset  = ShadowOffsset;
//    arc.shadowRadius  = ShadowRadius;
//    
//    //[self.arcTest.layer removeFromSuperlayer];
//    [self.arcTest.layer addSublayer:arc];
//}
//
//-(UIColor*)getColor:(int)ChoiceColor{
//    
//    //Creates the color
//    UIColor * colorBar = [UIColor alloc];
//    
//    //Pick up the reight color
//    UIColor * color1 = [UIColor colorWithRed:0.659 green:0.302 blue:0.576 alpha:1];
//    UIColor * color2 = [UIColor colorWithRed:0.559 green:0.202 blue:0.476 alpha:1];
//    UIColor * color3 = [UIColor colorWithRed:0.459 green:0.102 blue:0.376 alpha:1];
//    
//    switch (ChoiceColor) {
//        case 0://Strong Pink
//            //colorBar = [UIColor colorWithRed:255.0f/255.0f green:105.0f/255.0f blue:180.0f/255.0f alpha:1.0];
//            colorBar = color1;
//            break;
//            
//        case 1://Purple
//            //colorBar = [UIColor colorWithRed:123.0f/255.0f green:104.0f/255.0f blue:238.0f/255.0f alpha:1.0];
//            colorBar = color2;
//            break;
//            
//        case 2://Weak Pink
//            //colorBar = [UIColor colorWithRed:255.0f/255.0f green:192.0f/255.0f blue:203.0f/255.0f alpha:1.0];
//            colorBar = color3;
//            break;
//        default:
//            colorBar = [UIColor whiteColor];
//            break;
//            
//    }
//    return colorBar;
//}

@end
