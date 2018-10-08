//
//  TDDefines.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 6/18/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#ifndef Timex_Datalink_TDDefines_h
#define Timex_Datalink_TDDefines_h

#define TCSTART @try{
#define TCEND  }@catch(NSException *e){NSLog(@"\n\n\n\n\n\n\
\n\n|EXCEPTION FOUND HERE...PLEASE DO NOT IGNORE\
\n\n|FILE NAME         %s\
\n\n|LINE NUMBER       %d\
\n\n|METHOD NAME       %s\
\n\n|EXCEPTION REASON  %@\
\n\n\n\n\n\n\n",strrchr(__FILE__,'/'),__LINE__, __PRETTY_FUNCTION__,e);};


#define IDIOM    UI_USER_INTERFACE_IDIOM()
#define IPAD     UIUserInterfaceIdiomPad
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define IS_WIDESCREEN ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double ) 568 ) < DBL_EPSILON )
#define WORKOUT_BLE_DOWNLOAD_ENABLED 1

#define FIRMWARE_UPGRADE_JSON_FILE_VERSION 1

#define NAVIGATION_BAR_HEADER_HEIGHT 70
#define NAVIGATION_BAR_FOOTER_IMAGE_HEIGHT 18
#define NAVIGATION_BAR_FOOTER_IMAGE_WIDTH 86
#define NAVIGATION_BAR_RED_SQUARE_EDGE_WIDTH 8
#define NAVIGATION_BAR_TIMEX_LOGO_TOP_OFFSET 35

#define NAVIGATION_ITEM_FONT_SIZE 14
#define NAVIGATION_ITEM_ICON_SIZE 32
#define NAVIGATION_ITEM_IMAGE_SIZE 24
#define NAVIGATION_ITEM_ICON_SPACER 4
#define NAVIGATION_ITEM_FRAME_OFFSET 4

#define M053_MAXIMUM_DISTANCE_GOAL 9999
#define M053_MAXIMUM_STEPS_GOAL 99999
#define M053_MAXIMUM_CALORIES_GOAL 9999

#define ONBOARDING_PAIR_WATCH_CELL_HEIGHT 55

#define INITIAL_SETUP_WATCH_LIST_CELL_HEIGHT 140
#define INITIAL_SETUP_WATCH_LIST_ICON_SIZE 96
#define INITIAL_SETUP_WATCH_LIST_FONT_SIZE 20
#define INITIAL_SETUP_WATCH_LIST_FRAME_OFFSET 6

#define GENERIC_TABLE_CELL_FONT_SIZE 16

#define SOUND_PICKER_TIMEX_LIST_FRAME_OFFSET 18

#define M054_WATCH_MODEL                @"M054"
#define M053_WATCH_MODEL                @"M053"
#define M372_WATCH_MODEL                @"M372"
#define M328_WATCH_MODEL                @"M328"
#define M329_WATCH_MODEL                @"M329"

#define TIMEX_EULA_URL_EN           @"http://shop.guessconnect.com/on/demandware.static/-/Sites-timex-master-catalog/default/dw4289f21a/sequel-manuals/EULAIQ+English1IOS.html"
#define TIMEX_EULA_URL_FR           @"http://shop.guessconnect.com/on/demandware.static/-/Sites-timex-master-catalog/default/dw4289f21a/sequel-manuals/EULAIQ+French1IOS.html"
#define TIMEX_EULA_URL_SP           @"http://shop.guessconnect.com/on/demandware.static/-/Sites-timex-master-catalog/default/dw4289f21a/sequel-manuals/EULAIQ+Spanish1IOS.html"
#define TIMEX_EULA_URL_PO           @"http://shop.guessconnect.com/on/demandware.static/-/Sites-timex-master-catalog/default/dw4289f21a/sequel-manuals/EULAIQ+English1IOS.html"
#define TIMEX_EULA_URL_IT           @"http://shop.guessconnect.com/on/demandware.static/-/Sites-timex-master-catalog/default/dw4289f21a/sequel-manuals/EULAIQ+English1IOS.html"
#define TIMEX_EULA_URL_DU           @"http://shop.guessconnect.com/on/demandware.static/-/Sites-timex-master-catalog/default/dw4289f21a/sequel-manuals/EULAIQ+English1IOS.html"
#define TIMEX_EULA_URL_GE           @"http://shop.guessconnect.com/on/demandware.static/-/Sites-timex-master-catalog/default/dw4289f21a/sequel-manuals/EULAIQ+English1IOS.html"

#define TIMEX_HELP_IQ_URL           @"http://shop.guessconnect.com/on/demandware.static/-/Sites-timex-master-catalog/default/dw4289f21a/sequel-manuals/Connect IQ+ User Manual.html"
#define TIMEX_HELP_TRAVEL_URL       @"http://assets.timex.com/firmware/M329/manual/M329_users_guide.htm"
#define TIMEX_CUSTOMER_SERVICE_URL  @"http://shop.guessconnect.com/customer-service.html"
#define TIMEX_URL                   @"http://shop.guessconnect.com"
#define CUSTOMER_SUPPORT_URL        @"support@guessconnect.com"

#define M372_GOOD_VOLTAGE_THRESHOLD 2.5f
#define KEY_BATTERRY_CHARGE_M372 @"M372BATTERYCHARGE"
#define M053_INTERVAL_TIMER_WORKOUTS_MORE_THEN_99_REPEATS NSIntegerMax
#define WATCH_SERIAL_NUMBER @"WatchSerialNumber"
#define PCCOMM_MAX_PACKET_LENGTH   64

// for M328

#define APP_HEADER_FONT_SIZE 16

#define M328_USER_DATA_AGE_MINIMUM 5
#define M328_USER_DATA_AGE_MAXIMUM 99

#define M328_USER_DATA_HEIGHT_MINIMUM_CENTIEMTERS 102
#define M328_USER_DATA_HEIGHT_MAXIMUM_CENTIEMTERS 218

#define M328_USER_DATA_WEIGHT_MINIMUM_KILOS 200
#define M328_USER_DATA_WEIGHT_MAXIMUM_KILOS 2000

#define M328_USER_DATA_DISTANCEADJUSTMENT_MINIMUM_PERCENTAGE -25
#define M328_USER_DATA_DISTANCEADJUSTMENT_MAXIMUM_PERCENTAGE 25

#define M328_MAXIMUM_DISTANCE_GOAL_KM 99.99
#define M328_MAXIMUM_STEPS_GOAL 99999
#define M328_MAXIMUM_CALORIES_GOAL 9999
#define M328_MAXIMUM_SLEEP_GOAL  24
#define	M328_MAXIMUM_DISTANCE_GOAL 10000

#define M328_NAVIGATION_BAR_FONT_SIZE 16

#define M328_SIDE_MENU_WIDTH 240
#define M328_SIDE_MENU_MAXIMUM_CELL_HEIGHT 70
#define M328_SIDE_MENU_TABLE_OFFSET_HZ 20
#define M328_SIDE_MENU_TABLE_OFFSET_VT 20

#define IS_IPAD (IDIOM == IPAD)

#define M328_MAIN_SCREEN_FONT_SIZE 12

#define M328_WELCOME_INFO_FONTSIZE ((IS_IPAD) ? 19 : 15)
#define M328_REGISTRATION_BIG_TITLE_FONTSIZE ((IS_IPAD) ? 33 : 28)
#define M328_REGISTRATION_TITLE_FONTSIZE ((IS_IPAD) ? 25 : 20)
#define M328_REGISTRATION_INFO_FONTSIZE ((IS_IPAD) ? 20 : 15)
#define M328_REGISTRATION_BOTTOM_CONSTRAINT_MINUSVALUE ((IS_IPAD) ? 340 : 190)
#define M328_REGISTRATION_TITLE__HIGHLIGHT_FONTSIZE ((IS_IPAD) ? 28 : 20)

#define M328_HOME_SCREEN_ROW_HEIGHT ((IS_IPAD) ? 120 : 100)
#define M328_HOME_SCREEN_TITLE_LABEL_FONT_SIZE ((IS_IPAD) ? 26.0 : 22.0)
#define M328_HOME_SCREEN_FORMAT_STRING_FONT_SIZE ((IS_IPAD) ? 16 : 12.0)
#define M328_HOME_SCREEN_CALENDER_VIEW_FONT_SIZE ((IS_IPAD) ? 17 : 13.0)
#define M328_HOME_TODAY_BUTTON_FONT_SIZE ((IS_IPAD) ? 14 : 14)

#define M328_SLEEPHISTORY_SCREEN_TIME_FONT_SIZE ((IS_IPAD) ? 20 : 16)
#define M328_SLEEPHISTORY_SCREEN_HRS_FONT_SIZE ((IS_IPAD) ? 20 : 16)
#define M328_SLEEPHISTORY_SCREEN_FORMAT_FONT_SIZE ((IS_IPAD) ? 10 : 9)
#define M328_SLEEP_LIST_CELL_HEIGHT ((IS_IPAD) ? 100 : 80)
#define M328_SLEEP_DETAILS_CELL_TITLE_FONT_SIZE ((IS_IPAD) ? 15 : 11)
#define M328_SLEEP_DETAILS_TOTAL_TIME_TITLE_FONT_SIZE ((IS_IPAD) ? 35 : 30)
#define M328_SLEEP_DETAILS_TABLE_HEADER_HEIGHT ((IS_IPAD) ? 350 : 245)
#define M328_SLEEP_DETAILS_TABLE_HEADER_WIDTH ((IS_IPAD) ? 500 : 315)

#define M328_STEPS_SCREEN_MAX_CAL_FONT_SIZE ((IS_IPAD) ? 33.0 : 29.0)
#define M328_STEPS_SCREEN_HEADING_FONT_SIZE ((IS_IPAD) ? 13.0 : 9.0)
#define M328_STEPS_SCREEN_STEPS_FONT_SIZE ((IS_IPAD) ? 33.0 : 29.0)
#define M328_STEPS_SCREEN_DISTANCE_FONT_SIZE ((IS_IPAD) ? 19.0 : 15.0)

#define M328_GOALS_SCREEN_CURRENT_FONT_SIZE ((IS_IPAD) ? 12 : 10)
#define M328_GOALS_SCREEN_TAG_FONT_SIZE ((IS_IPAD) ? 14 : 12.0)
#define M328_GOALS_SCREEN_GOALS_FONT_SIZE ((IS_IPAD) ? 20 : 18.0)
#define M328_GOALS_SCREEN_TITLE_FONT_SIZE ((IS_IPAD) ? 18 : 16.0)

#define M328_SLIDE_MENU_CELL_FONT_SIZE ((IS_IPAD) ? 20 : 16)
#define M328_SLIDE_MENU_CELL_HEIGHT ((IS_IPAD) ? 70 : 50)
#define M328_SLIDE_MENU_HEADER_HEIGHT ((IS_IPAD) ? 100 : 60)
#define M328_SETTINGS_DETAIL_FONT_SIZE ((IS_IPAD) ? 17 : 13)
#define M328_CONFIRM_CHANGE_BUTTON_WIDTH ((IS_IPAD) ? 350 : 190)
#define M328_SUB_DIAL_DISTANCE_HEIGHT ((IS_IPAD) ? 300 : 200)
#define M328_SUB_DIAL_DISTANCE_WIDTH ((IS_IPAD) ? 300 : 200)
#define M328_SLEEP_COLLECTION_VIEW_HEIGHT ((IS_IPAD) ? 300 : 180)
#define M328_ABOUT_TEXT_FONT_SIZE 13
#define M328_TABLE_HEADER_FONT_SIZE 16
#define M328_FOOTER_BUTTON_FONT_SIZE 18
#define M328_SLEEP_DETAILS_TABLE_TIME_FONT_SIZE ((IS_IPAD) ? 12 : 10)
#define M328_SLEEP_DETAILS_ARC_SEGMENT_WIDTH ((IS_IPAD) ? 50 : 40)
#define SECONDS_PER_DAY 86400

#define degreesToRadian(x) (M_PI * (x) / 180.0)

#define DEGREES 360

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define UIColorFromRGBAlpha(rgbValue,alphaVal)  [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:alphaVal]

#pragma mark - Color Codes

#define AppColorRed 0xca4a47
#define AppColorDarkGray  [UIColor colorWithRed: 55.0/255.0 green: 55.0/255.0 blue: 55.0/255.0 alpha: 1.0]
#define AppColorLightGray [UIColor colorWithRed: 111.0/255.0 green: 111.0/255.0 blue: 111.0/255.0 alpha: 1.0]
#define RedUnselected       [UIColor colorWithRed:255/255.0 green:21/255.0 blue:27/255.0 alpha:0.5]
#define BlueOne     [UIColor colorWithRed:99/255.0 green:196/255.0 blue:195/255.0 alpha:1.0]
#define INFO_ICON_TINT_COLOR 0x6c6c6c

#define M328_STEPS_GRAPH_COLOR 0xC3E2E3
#define M328_STEPS_COLOR 0x60b1b6

#define M328_DISTANCE_COLOR 0xca4a47
#define M328_DISTANCE_GRAPH_COLOR 0xE4A4A3

#define M328_CALORIES_COLOR 0xf9a728
#define M328_CALORIES_GRAPH_COLOR 0xFCD393

#define M328_SLEEP_COLOR 0x1b4d90
#define M328_SLEEP_GRAPH_COLOR 0x8DA6C7
#define M328_HOME_SLEEP_DARK_COLOR [UIColor colorWithRed:55/255.0 green:85/255.0 blue:161/255.0 alpha:1.0]
#define M328_HOME_SLEEP_LIGHT_COLOR [UIColor colorWithRed:174/255.0 green:191/255.0 blue:226/255.0 alpha:1.0]
#define M328_HOME_SLEEP_AWAKE_COLOR [UIColor colorWithRed:235/255.0 green:240/255.0 blue:255/255.0 alpha:1.0]

#define M328_PROGRESS_GREEN_COLOR 0x76ce82

#define M328_DATE_MAGENTA 0x2b006c
#define M328_SECONDS_GREEN 0xb3cd40

#define COLOR_DEFAULT_TIMEX_WHITE 0xFFFFFF
#define COLOR_DEFAULT_TIMEX_FONT 0x808080
#define COLOR_DEFAULT_TIMEX_FONT_DARK 0x404040
#define COLOR_DEFAULT_TIMEX_ACCENT  0xF5002F

#define M328_TABLEVIEW_HEADER_GRAY_COLOR 0xf6f6f6
#define VERY_LIGHT_GRAY_COLOR 0xECECEC
#define COLOR_LIGHT_GRAY 0xe7e7e7
#define MEDIUM_GRAY_COLOR 0xBDBDBD
#define GROUPED_TABLEVIEW_BACKGROUND_COLOR 0xEFEFF4

#define ACTIVITY_TRACKER_COLOR_ORANGE 0xE4763D
#define ACTIVITY_TRACKER_COLOR_GREEN  0x6DBD92
#define ACTIVITY_TRACKER_COLOR_YELLOW 0xF2B354
#define ACTIVITY_TRACKER_COLOR_RED    0xED1A33

#pragma mark - Screen Sizes

#define ScreenWidth [[UIScreen mainScreen] bounds].size.width
#define ScreenHeight [[UIScreen mainScreen] bounds].size.height
#define NUMBER_TOOLBAR_HEIGHT ((IS_IPAD) ? 50 : 30)


#define SECONDS_PER_MINUTE (60)
#define MINUTES_PER_HOUR (60)
#define SECONDS_PER_HOUR (SECONDS_PER_MINUTE * MINUTES_PER_HOUR)
#define HOURS_PER_DAY (24)

#define M328_SLEEP_AWAKE_STR @"C"
#define M328_SLEEP_LIGHT_STR @"B"
#define M328_SLEEP_DEEP_STR @"A"

#define MAXIMUM_DISTANCE_GOAL_KM 99.99
#define MAXIMUM_STEPS_GOAL 99999
#define MAXIMUM_CALORIES_GOAL 9999
#define MAXIMUM_SLEEP_GOAL  24
// Maximum idle time before the idle screen shows up.
// Keep 5 for testing.
// Live idle time 120 (2 minutes)
/// Maximum idle time before the idle screen shows up.
#define M328_IDLE_TIME_MAX 120

#define M328_USER_STATIC_AGE 25


#define M328_HourHandRows 12
#define M328_MinuteHandRows 60
#define M328_SecondHandRows 60
#define M328_SubdialHandRows 120
#define CALORIES   @"calories"
#define SLEEPTIME  @"sleepTime"
#define STEPS      @"steps"
#define GOALTYPE   @"type"
#define DISTANCE   @"distance"
#define USER_UNITS @"units"
#define USER_ALARM @"USER_ALARM"

#define GOAL_TYPE_ACTIVE                   @"Active"
#define GOAL_TYPE_PRETTY_ACTIVE            @"Pretty_Active"
#define GOAL_TYPE_VERY_ACTIVE              @"Very_Active"
#define GOAL_TYPE_CUSTOM                   @"Custom"

#define AFTER_SYNC_TIMEOUT 2.0

//M328 settings keys


// Firmware upgrade settings and checking
#define kFirmwareCheckQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) //1
#define kTimexFirmwareCheckURL [NSURL URLWithString:@"http://assets.timex.com/firmware/version.json"] //2

#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define DLog(...)
#endif


#define USERID_USERDEFAULT  "userIdFirebase"
#define ALL_THE_DATA_IN_EPOCHS "allEPochsReaded"
#define DAYS_READ_BEFORE "daysBefore"
#define DATA_DATAIL_BY_DAY "detailDataByDay"
#define FIRST_SYNC "firstEpochs"

#define M372_MIGRATION_DONE @"M372MigrationDone"
#define M372_SLEEP_REFRESH_MIGRATION @"M372SleepRefreshMigration"

#define WATCHID_COREDATA_MIGRATION_DONE @"CoredataMigrationDone"

#define DistanceDecimalCorrectionKey @"kDistanceDecimalCorrectionKey"

#define TIMEX_GROUP_IDENTIFIER @"group.TimexUSA.TimexConnected"
#endif
