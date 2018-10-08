//
//  CustomAlertViewController.m
//  timex
//
//  Created by Raghu on 16/01/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import "CustomAlertViewController.h"

@interface CustomAlertViewController ()

@end

@implementation CustomAlertViewController
{
    NSMutableArray *customAlertButtonsArray;
    NSString *alertTitle;
    NSString *messageString;
}

-(id)initWithTitle:(NSString *)title andMessage:(NSString *)message
{
    self = [super initWithNibName:@"CustomAlertViewController" bundle:nil];
    customAlertButtonsArray = [[NSMutableArray alloc] init];
    alertTitle = title;
    messageString = message;
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self.titleLabel setText:alertTitle];
    [self.MessageLabel setText:messageString];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissView)];
    [self.transparenBackGroundView addGestureRecognizer:tapGesture];
    
    [self.alertView setHidden:YES];
    [self.transparenBackGroundView setHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self performSelector:@selector(addActionButtonsToView) withObject:nil afterDelay:0.5];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void)addActionButtonsToView
{
    if([customAlertButtonsArray count] > 0)
    {
        CGFloat x = 0;
        
        CGFloat width = self.buttonsView.frame.size.width/[customAlertButtonsArray count];
        
        for (CustomAlertButton *cab in customAlertButtonsArray)
        {
            CGRect frame = CGRectMake(x, 0, width, self.buttonsView.frame.size.height);
            [cab setFrame:frame];
            
            [cab addTarget:self action:@selector(customAlertButtonAction:) forControlEvents:UIControlEventTouchUpInside];
            [self.buttonsView addSubview:cab];
            
            x = x+width;
        }
    }
    
    [self.alertView setHidden:NO];
    [self.transparenBackGroundView setHidden:NO];
}

-(void)addActionButton:(CustomAlertButton *)customAlertButton
{
    [customAlertButtonsArray addObject:customAlertButton];
}

-(void)customAlertButtonAction:(CustomAlertButton *)sender
{
    [self dismissViewControllerAnimated:NO completion:^
    {
        [sender performAlertButtonClickAction];
    }];
    
}

-(void)dismissView
{
    [self dismissViewControllerAnimated:NO completion:nil];
}
@end
