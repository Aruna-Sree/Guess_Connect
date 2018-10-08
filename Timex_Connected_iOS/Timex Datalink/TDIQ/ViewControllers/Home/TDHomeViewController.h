//
//  TDHomeViewController.h
//  Timex
//
//  Created by Aruna Kumari Yarra on 28/03/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JTCalendar.h"
#import "TDRootViewController.h"

@interface TDHomeViewController : TDRootViewController<UITableViewDelegate, UITableViewDataSource, JTCalendarDelegate> {
    
    IBOutlet UIView *calenderView;
    IBOutlet UIButton *higerBtn;
    IBOutlet UIButton *dismissBtn;
    IBOutlet UIView *view;
   
    IBOutlet UIImageView *goalImgView;
    IBOutlet UILabel *goalDescLbl;
    
    IBOutlet UIView *notificationView;
    
    IBOutlet NSLayoutConstraint *tableViewBottomConstraint;
    
}

@property (strong, nonatomic) UIBarButtonItem *calendarButtonItem;
@property (strong, nonatomic) UILabel *yearLabel;
@property (strong, nonatomic) UIButton *calPrevButton;
@property (strong, nonatomic) UIButton *calNextButton;
@property (strong, nonatomic) UIButton *calTodayButton;

@property (strong, nonatomic) NSDate *calDate;
@property (strong, nonatomic) NSMutableDictionary *eventsByDate;
@property (strong, nonatomic) NSDate *minDate;
@property (strong, nonatomic) NSDate *maxDate;
@property (strong, nonatomic) NSDate *dateSelected;

@property (strong, nonatomic) IBOutlet JTCalendarMenuView *calendarMenuView;
@property (strong, nonatomic) IBOutlet JTHorizontalCalendarView *calendarContentView;

@property (strong, nonatomic) UIView *calBgView;

@property (strong, nonatomic) JTCalendarManager *calendarManager;

@property (strong, nonatomic) IBOutlet UITableView *homeTableView;
@property (nonatomic, strong) IBOutlet UIButton *leftBtn;
@property (nonatomic, strong) IBOutlet UIButton *centerBtn;
@property (nonatomic, strong) IBOutlet UIButton *rightBtn;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *notificaitonHConstraint;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil doFirmwareCheck: (BOOL) firmwareCheckRequested initialSync:(BOOL)isInitialSync_;

- (IBAction)clickedOnDateBtn:(UIButton *)sender;

// Making it public for the customTabBar to sync properly.
-(void)initializeWorkoutsArray;

//- (void)syncDone;
@end
