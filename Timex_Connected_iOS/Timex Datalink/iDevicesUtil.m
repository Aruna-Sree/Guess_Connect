//
//  iDevicesUtil.m
//  Timex Connected
//
//  Created by Mark Daigle on 6/5/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "iDevicesUtil.h"
#import "TimexWatchDB.h"
#import "WhichApp.h"
#import "TDDefines.h"
#import "TDDeviceManager.h"
#import "TDWatchProfile.h"
#import "TDWorkoutData+Writeable.h"
#import "Flurry.h"
#import "TDWebViewer.h"
#import <sys/sysctl.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "UIImage+Tint.h"
#import "MBProgressHUD.h"
#import "WelcomeViewController.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "OTLogUtil.h"
NSString* const kCONNECTED_DEVICE_UUID_PREF_NAME = @"kCONNECTED_DEVICE_UUID_PREF_NAME";

@implementation iDevicesUtil

+ (UIImageView *)getNavigationTitle {
    
    UIImageView* logo = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"NavTitleLogo"] imageWithTint: [UIColor whiteColor]]];
    return logo;
    //self.navigationItem.titleView = logo;
}
+ (NSAttributedString *)getAttributedStrWithText:(NSString *)textStr highLightStr:(NSString *)highLightStr {
    
    UIFont *font = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size:M328_REGISTRATION_INFO_FONTSIZE];
    NSDictionary *atrsDict = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *formatAtrStr = [[NSMutableAttributedString alloc] initWithString:textStr attributes:atrsDict];
    
    NSRange foundRange = [textStr rangeOfString:highLightStr];
    if (foundRange.length > 0) {
        UIFont *font = [UIFont fontWithName: [iDevicesUtil getAppWideMediumFontName] size:M328_REGISTRATION_INFO_FONTSIZE];
        NSDictionary *higDict = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
        [formatAtrStr addAttributes:higDict range:foundRange];
    }
    return formatAtrStr;
}

+ (UIButton *)getBackButton
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageNamed:@"leftarrow"] forState:UIControlStateNormal];
    [btn setContentEdgeInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
    btn.frame = CGRectMake(10, 0, 40, 40);
    
    return btn;
}
+(NSDate *)getWeekStartDate:(NSDate *)date
{
    //Week Start Date
    
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    
    NSDateComponents *components = [gregorian components:NSCalendarUnitWeekday | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
    
    NSInteger dayofweek = [[[NSCalendar currentCalendar] components:NSCalendarUnitWeekday fromDate:date] weekday];// this will give you current day of week
    
    [components setDay:([components day] - ((dayofweek) - 1))];// for beginning of the week. Week starts from sunday //artf27057
    
    NSDate *beginningOfWeek = [gregorian dateFromComponents:components];
    
    return beginningOfWeek;
    
}

+(NSDate *)getWeekEndDate:(NSDate *)date
{
    
    NSCalendar *gregorianEnd = [NSCalendar currentCalendar];
    
    NSDateComponents *componentsEnd = [gregorianEnd components:NSCalendarUnitWeekday | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
    
    NSInteger Enddayofweek = [[[NSCalendar currentCalendar] components:NSCalendarUnitWeekday fromDate:date] weekday];// this will give you current day of week
    
    [componentsEnd setDay:([componentsEnd day]+(7-Enddayofweek))];// for end day of the week
    
    NSDate *endOfWeek = [gregorianEnd dateFromComponents:componentsEnd];
    
    return endOfWeek;
    
}

+(NSDate *)getFirstDateOfPreviousMonth:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[NSTimeZone systemTimeZone]];
    
    NSDateComponents *components = [calendar components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:date];
    
    components.month = components.month - 1;
    components.day = 1;
    
    NSDate *newDate = [calendar dateFromComponents:components];
    
    return newDate;
    
}

+(NSDate *)getFirstDateOfNextMonth:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[NSTimeZone systemTimeZone]];
    
    NSDateComponents *components = [calendar components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:date];
    
    components.month = components.month + 1;
    components.day = 1;
    
    NSDate *newDate = [calendar dateFromComponents:components];
    
    return newDate;
    
}

+(NSDate *)getFirstDateInMonth:(NSDate *)date
{
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    [gregorian setTimeZone:[NSTimeZone systemTimeZone]];
    NSDateComponents *comp = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    [comp setDay:1];
    NSDate *firstDayOfMonthDate = [gregorian dateFromComponents:comp];
    
    
    return firstDayOfMonthDate;
}

+(NSDate *)getLastDateInMonth:(NSDate *)date
{
    NSDate *curDate = date;
    NSCalendar* calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[NSTimeZone systemTimeZone]];
    NSDateComponents* comps = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitWeekOfYear|NSCalendarUnitWeekday fromDate:curDate]; // Get necessary date components
    
    // set last of month
    [comps setMonth:[comps month]+1];
    [comps setDay:0];
    NSDate *tDateMonth = [calendar dateFromComponents:comps];
    
    return tDateMonth;
}

+(NSDate *)getFirstDateInYear:(NSDate *)date
{
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    [gregorian setTimeZone:[NSTimeZone systemTimeZone]];
    NSDateComponents *comp = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    [comp setDay:1];
    [comp setMonth:1];
    NSDate *firstDayOfMonthDate = [gregorian dateFromComponents:comp];
    
    return firstDayOfMonthDate;
}
+(NSDate *)getLastDateInYear:(NSDate *)date
{
    NSDate *curDate = date;
    NSCalendar* calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[NSTimeZone systemTimeZone]];
    NSDateComponents* comps = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitWeekOfYear|NSCalendarUnitWeekday fromDate:curDate]; // Get necessary date components
    [comps setDay:31];
    [comps setMonth:12];
    NSDate *tDateMonth = [calendar dateFromComponents:comps];
    
    return tDateMonth;
}
+(NSDate *)getFirstDateOfPreviousYear:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[NSTimeZone systemTimeZone]];
    
    NSDateComponents *components = [calendar components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:date];
    
    components.year = components.year - 1;
    components.month = 1;
    components.day = 1;
    
    NSDate *newDate = [calendar dateFromComponents:components];
    
    return newDate;
    
}

+(NSDate *)getFirstDateOfNextYear:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[NSTimeZone systemTimeZone]];
    
    NSDateComponents *components = [calendar components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:date];
    
    components.year = components.year + 1;
    components.month = 1;
    components.day = 1;
    
    NSDate *newDate = [calendar dateFromComponents:components];
    
    return newDate;
    
}

+ (NSDate *) yesterdayDateAtMidnight
{
    NSDate* result = nil;
    
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    NSDateComponents *comps = [gregorian components: NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate: [NSDate date]];
    [comps setHour: -24];
    [comps setMinute: 0];
    [comps setSecond: 0];
    
    result = [gregorian dateFromComponents: comps];
    return result;
}

+ (UIImage *)imageFromColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+(NSString *) getAppWideBoldFontName
{
    return @"Roboto-Bold";
}
+(NSString *) getAppWideMediumFontName
{
    return @"Roboto-Regular";
}

+(NSString *) getAppWideItalicFontName
{
    return @"Roboto-Italic";
}
+ (CGFloat)getProgressBarValueBasedOnRegistrationEnum:(enum RegistartionProgressValues)enumValue {
    if (enumValue == setupComplete) {
        return 1;
    } else if (enumValue == callibrateWatch) {
        return 0.9;
    } else if (enumValue == updateFirmware) {
        return 0.8;
    } else if (enumValue == setupWatch) {
        return 0.7;
    } else if (enumValue == configureSubDial) {
        return 0.6;
    } else if (enumValue == settingGoals) {
        return 0.5;
    } else if (enumValue == weight) {
        return 0.4;
    } else if (enumValue == height) {
        return 0.3;
    } else if (enumValue == birthdate) {
        return 0.2;
    } else if (enumValue == nameandsex) {
        return 0.1;
    }
    return 0.0;
}

+ (UIColor *) getActivityColorBasedOnPercentage: (CGFloat) percentage andType:(NSString *)activityType
{
    UIColor * color = nil;
    if ([activityType isEqualToString:@"steps"]) {
        //if (percentage == 0)
        //    color = UIColorFromRGB(MEDIUM_GRAY_COLOR);
        //else
            color = UIColorFromRGB(M328_STEPS_COLOR);
    } else if ([activityType isEqualToString:@"distance"]) {
        //if (percentage == 0)
        //    color = UIColorFromRGB(MEDIUM_GRAY_COLOR);
        //else
            color = UIColorFromRGB(M328_DISTANCE_COLOR);
    } else if ([activityType isEqualToString:@"calories"]) {
        //if (percentage == 0)
        //    color = UIColorFromRGB(MEDIUM_GRAY_COLOR);
        //else
            color = UIColorFromRGB(M328_CALORIES_COLOR);
    } else {
        //if (percentage == 0)
        //    color = UIColorFromRGB(MEDIUM_GRAY_COLOR);
        //else
            color = UIColorFromRGB(M328_SLEEP_COLOR);
    }
    return color;
}

+(void)showProgressHUDInView:(UIView *)view withText:(NSString *)text {
    
    @try {
        MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
        hud.labelText = text;
        
    }
    @catch (NSException *exception) {
        OTLog(@"Exception At: %s %d %s %s %@", __FILE__, __LINE__, __PRETTY_FUNCTION__, __FUNCTION__,exception);
    }
    @finally {
        
    }
}
+(void)removeProgressHUDInView:(UIView *)view {
    
    @try {
        [MBProgressHUD hideHUDForView:view animated:YES];
    }
    @catch (NSException *exception) {
        OTLog(@"Exception At: %s %d %s %s %@", __FILE__, __LINE__, __PRETTY_FUNCTION__, __FUNCTION__,exception);
    }
    @finally {
    }
}

+ (CGFloat) device_window_height
{
    return [[UIScreen mainScreen] bounds].size.height;
}

+ (CGFloat) device_window_width
{
    return [[UIScreen mainScreen] bounds].size.width;
}

+ (CGFloat) window_height
{
    return [UIScreen mainScreen].applicationFrame.size.height;
}

+ (CGFloat) window_width
{
    return [UIScreen mainScreen].applicationFrame.size.width;
}

+ (NSString *)getViewControllerToPush:(Class)aClass {

    NSString *name = NSStringFromClass ([aClass class]);

    if ([WhichApp iPhone]) {
           name = [@"iPhone_" stringByAppendingString:name];
    
    }
    else {
        if ([[NSBundle mainBundle] pathForResource:[@"iPad_" stringByAppendingString:name] ofType:@"nib"] != nil) { //nib4x  babu
            name = [@"iPad_" stringByAppendingString:name];
        } else {
            name = [@"iPhone_" stringByAppendingString:name];
        }
       
    }

    return name;
}

+ (int) getRandomInRangeFrom:(int) min To:(int)max
{
    return rand() % (max - min) + min; 
}

+ (UIButton *) getNavBarButtonBasedOnText: (NSString *) text
{
    CGRect labelRect = [text
                        boundingRectWithSize:CGSizeMake([[UIScreen mainScreen] bounds].size.width, CGFLOAT_MAX)
                        options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                        attributes:@{
                                     NSFontAttributeName : [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size: M328_NAVIGATION_BAR_FONT_SIZE]
                                     }
                        context:nil];
    
    UIButton *but = [[UIButton alloc] initWithFrame:labelRect];
    [but setTitle: text forState: UIControlStateNormal];
    [but setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
    [but.titleLabel setFont: [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size: M328_NAVIGATION_BAR_FONT_SIZE]];
    
    return but;
}

+(NSString *) getAppWideFontName
{
    NSString * fontName = nil;
    
//    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
//        fontName = @"HelveticaNeue-Light";
//    else
        fontName = @"AvenirNext-Regular";
    
    return fontName;
}

+ (NSString*) appVersionString
{
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    //NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    return [NSString stringWithFormat:@" Version %@", version];
}
+ (NSString *) appVersionStringSleepTracker
{
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    //NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    return [NSString stringWithFormat:@"%@", version];
}
+ (NSString *)stringFromTimeInterval:(NSTimeInterval)interval
{
    NSInteger ti = (NSInteger)interval;
    NSInteger milliseconds = (ti % 1000);
    NSInteger hundredthOfSecond = milliseconds / 10;
    NSInteger seconds = (ti % 60000) / 1000;
    NSInteger minutes = (ti / 60000) % 60;
    NSInteger hours = (ti / 3600000);
    
    NSString * result = nil;
    
    if (hours != 0)
        result = [NSString stringWithFormat:@"%li:%02li.%02li.%02li", (long)hours, (long)minutes, (long)seconds, (long)hundredthOfSecond];
    else if (hours == 0 && minutes != 0)
        result = [NSString stringWithFormat:@"%li.%02li.%02li", (long)minutes, (long)seconds, (long)hundredthOfSecond];
    else if (hours == 0 && minutes == 0 && seconds != 0)
        result = [NSString stringWithFormat:@"%li.%02li", (long)seconds, (long)hundredthOfSecond];
    else
        result = [NSString stringWithFormat:@"0.%li", (long)hundredthOfSecond];
    
    return result;
}

+ (NSString *)stringFromTimeIntervalNoMilliseconds:(NSTimeInterval)interval
{
    NSInteger ti = (NSInteger)interval;

    NSInteger seconds = (ti % 60000) / 1000;
    NSInteger minutes = (ti / 60000) % 60;
    NSInteger hours = (ti / 3600000);
    
    NSString * result = nil;
    
    if (hours > 0)
        result = [NSString stringWithFormat:@"%li:%02li:%02li hrs", (long)hours, (long)minutes, (long)seconds];
    else if (hours == 0 && minutes > 0)
        result = [NSString stringWithFormat:@"%li:%02li min", (long)minutes, (long)seconds];
    else
        result = [NSString stringWithFormat:@"%li sec", (long)seconds];
    
    return result;
}

+(BOOL) checkForActiveProfilePresence
{
//    NSString *sourceString = [[NSThread callStackSymbols] objectAtIndex:1];
//    NSCharacterSet *separatorSet = [NSCharacterSet characterSetWithCharactersInString:@" -[]+?.,"];
//    NSMutableArray *array = [NSMutableArray arrayWithArray:[sourceString  componentsSeparatedByCharactersInSet:separatorSet]];
//    [array removeObject:@""];
//    
//    OTLog(@"Caller stack array %@", array);
    
    BOOL result = FALSE;
    
    NSString * expression = [NSString stringWithFormat: @"SELECT rowID FROM Profiles WHERE ProfileActive = 1;"];
    
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
    
    if (query) {
        if (query->getRowCount() > 0) {
            result = TRUE;
        } else {
            NSString *savedValue = [[NSUserDefaults standardUserDefaults]stringForKey:@USERID_USERDEFAULT];
            if (savedValue != nil)
            {
                result = true;
            }
        }
        delete query;
    }
    
    //Check any data loss
    expression = [NSString stringWithFormat: @"SELECT rowID FROM Profiles;"];
    
    query = [[TimexWatchDB sharedInstance] createQuery : expression];
    
    if (query) {
        if (query->getRowCount() < [TDWatchProfile rowCount]) {
            OTLog(@"WARNING: DATA LOSS. ATTEMPTING TO RECOVER");
            //[[TDWatchProfile sharedInstance] databaseRecover];
        }
        delete query;
    }
    return result;
}
+(timexDatalinkWatchStyle) getActiveWatchProfileStyle;
{
//    NSString *sourceString = [[NSThread callStackSymbols] objectAtIndex:1];
//    NSCharacterSet *separatorSet = [NSCharacterSet characterSetWithCharactersInString:@" -[]+?.,"];
//    NSMutableArray *array = [NSMutableArray arrayWithArray:[sourceString  componentsSeparatedByCharactersInSet:separatorSet]];
//    [array removeObject:@""];
//    
//    OTLog(@"Caller stack array %@", array);
    
    NSString *savedValue = [[NSUserDefaults standardUserDefaults]stringForKey:@USERID_USERDEFAULT];
    
    timexDatalinkWatchStyle result = timexDatalinkWatchStyle_Unselected;
    
    NSString * expression = [NSString stringWithFormat: @"SELECT WatchStyle FROM Profiles WHERE ProfileActive = 1;"];
    
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
    
    if (query)
    {
        if (query->getRowCount() > 0)
        {
            result = (timexDatalinkWatchStyle)query->getIntColumnForRow(0, @"WatchStyle");
        }
        
        delete query;
    }
    // Logic is that if there is a saved value, it is supposed to be metropolitan.
    // Only for metropolitan, the watch style etc. are not stored in Profiles.
    if(result == timexDatalinkWatchStyle_Unselected && savedValue!=nil ){
        return timexDatalinkWatchStyle_Metropolitan;
    }

    return result;
}

+(void) saveUserAppUnitMode:(NSString *)mode
{
     NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults  setValue:mode forKey:@"UserAppUnitMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSInteger) daysBetweenThis:(NSDate *)dt1 andThat:(NSDate *)dt2
{
    NSUInteger unitFlags = NSCalendarUnitDay;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:unitFlags fromDate:dt1 toDate:dt2 options:0];
    return [components day] + 1;
}


+ (PeripheralDevice *) getConnectedTimexDevice;
{
    PeripheralDevice * timexDevice = nil;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString * storedUUID = [userDefaults objectForKey: kCONNECTED_DEVICE_UUID_PREF_NAME];
    
    NSArray * connectedDevices = [[TDDeviceManager sharedInstance] getAllConnectedDevices];
    if ([connectedDevices count] > 0)
    {
        //find timex device
        for (PeripheralDevice * device in connectedDevices)
        {
            PeripheralProxy * proxy = device.peripheral;
            if (proxy != nil)
            {
                ServiceProxy* service = [proxy findService: [PeripheralDevice timexDatalinkServiceId]];
                
                if (service != nil)
                {
                    //is it the one we are looking for? there could be multiple connected devices, you know...
                    if (storedUUID != nil && [storedUUID isEqualToString: device.peripheral.UUID.UUIDString])
                    {
                        timexDevice = device;
                        break;
                    }
                }
            }
        }
    }
    
    return timexDevice;
}

+(BOOL) isSocialMediaImageSharingAllowed
{
    BOOL isAllowed = FALSE;
    
    NSString * key = [self createKeyForAppSettingsPropertyWithClass: appSettings_PropertyClass_General andIndex: appSettings_PropertyClass_General_SocialMediaAllowImages];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey: key] == nil)
    {
        isAllowed = TRUE;
        [userDefaults setBool: isAllowed forKey: key]; //default
    }
    else
    {
        isAllowed = [userDefaults boolForKey: key];
    }
    
    return isAllowed;
}



+(NSString *) getUserAppUnitMode
{
    #define ENGLISH                         @"English"
    #define METRIC                          @"Metric"
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *mode = [defaults stringForKey:@"UserAppUnitMode"];
    
    if (!mode)
    {
        [defaults setValue: ENGLISH forKey:@"UserAppUnitMode"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return ENGLISH;
    }
    else
    {
        return mode;
    }
}


+(NSString *) createKeyForWatchControlPropertyWithClass: (NSInteger) propClass andIndex: (NSInteger) index
{
    timexDatalinkWatchStyle currentWatchStyle = [[TDWatchProfile sharedInstance] watchStyle];
    
    return [NSString stringWithFormat:@"watchSetting_style%d_class%ld_idx%ld", currentWatchStyle, (long)propClass, (long)index];
}

+(NSString *) createKeyForAppSettingsPropertyWithClass: (NSInteger) propClass andIndex: (NSInteger) index
{
    timexDatalinkWatchStyle currentWatchStyle = [[TDWatchProfile sharedInstance] watchStyle];
    
    return [NSString stringWithFormat:@"appSetting_style%d_class%ld_idx%ld", currentWatchStyle, (long)propClass, (long)index];
}

+(NSString *) createKeyForUploadSiteSetting: (TimexUploadServicesOptions) propClass andIndex: (uploadSites_PropertyClass_settingTypeEnum) index
{
    return [NSString stringWithFormat:@"uploadSiteSetting_class%ld_idx%d", (long)propClass, index];
}

+ (NSString *) convertAlarmTimeSettingToString: (calendar_alarmTimeOptions) setting
{
    NSString * result = nil;
    
    if (setting == calendar_alarmTimeOptions_Now)
        result = NSLocalizedString(@"Instant", nil);
    else if (setting == calendar_alarmTimeOptions_15min)
        result = NSLocalizedString(@"15 min.", nil);
    else if (setting == calendar_alarmTimeOptions_30min)
        result = NSLocalizedString(@"30 min.", nil);
    else if (setting == calendar_alarmTimeOptions_60min)
        result = NSLocalizedString(@"1 hour", nil);
    else if (setting == calendar_alarmTimeOptions_120min)
        result = NSLocalizedString(@"2 hours", nil);
    
    return result;
}
+ (NSString *) convertGeneralLightModeSettingToString: (programWatch_PropertyClass_General_LightModeEnum)setting
{
    NSString * result = nil;
    
    if (setting == programWatch_PropertyClass_General_LightModeManual)
        result = NSLocalizedString(@"TAP", nil);
    else if (setting == programWatch_PropertyClass_General_LightModeNightMode)
        result = NSLocalizedString(@"Night Mode", nil);
    else if (setting == programWatch_PropertyClass_General_LightModeAlwaysOn)
        result = NSLocalizedString(@"Constant On", nil);
    
    return result;
}
+ (NSString *) convertGeneralTapForceSettingToString: (programWatch_PropertyClass_General_TapForceEnum)setting
{
    NSString * result = nil;
    
    if (setting == programWatch_PropertyClass_General_TapForceLight)
        result = NSLocalizedString(@"Light", nil);
    else if (setting == programWatch_PropertyClass_General_TapForceMedium)
        result = NSLocalizedString(@"Medium", nil);
    else if (setting == programWatch_PropertyClass_General_TapForceHard)
        result = NSLocalizedString(@"Hard", nil);
    
    return result;
}
+ (NSString *) convertGeneralTextColorSettingToString: (programWatch_PropertyClass_General_TextColorEnum)setting
{
    NSString * result = nil;
    
    if (setting == programWatch_PropertyClass_General_TextColorBlack)
        result = NSLocalizedString(@"Black", nil);
    else if (setting == programWatch_PropertyClass_General_TextColorWhite)
        result = NSLocalizedString(@"White", nil);
    
    return result;
}
+ (NSString *) convertGeneralLanguageSettingToString: (programWatch_PropertyClass_General_LanguageEnum)setting
{
    NSString * result = nil;
    
    if (setting == programWatch_PropertyClass_General_LanguageEnglish)
        result = NSLocalizedString(@"English", nil);
    else if (setting == programWatch_PropertyClass_General_LanguageSpanish)
        result = NSLocalizedString(@"Spanish", nil);
    else if (setting == programWatch_PropertyClass_General_LanguageFrench)
        result = NSLocalizedString(@"French", nil);
    else if (setting == programWatch_PropertyClass_General_LanguageGerman)
        result = NSLocalizedString(@"German", nil);
    else if (setting == programWatch_PropertyClass_General_LanguagePortuguese)
        result = NSLocalizedString(@"Portuguese", nil);
    else if (setting == programWatch_PropertyClass_General_LanguageItalian)
        result = NSLocalizedString(@"Italian", nil);
    else if (setting == programWatch_PropertyClass_General_LanguageDutch)
        result = NSLocalizedString(@"Dutch", nil);
    
    return result;
}

+ (NSString *) convertTimexRingtoneSettingToString: (appSettings_PropertyClass_PhoneFinderTimexRingtoneEnum) setting
{
    NSString * result = nil;
    
    if (setting == appSettings_PropertyClass_PhoneFinderTimexRingtoneTone1)
        result = @"Dog Bark";
    else if (setting == appSettings_PropertyClass_PhoneFinderTimexRingtoneTone2)
        result = @"Quack";
    else if (setting == appSettings_PropertyClass_PhoneFinderTimexRingtoneTone3)
        result = @"Sonar";
    
    return result;
}

+ (NSString *) convertTimexRingtoneSettingToLocalizedString: (appSettings_PropertyClass_PhoneFinderTimexRingtoneEnum) setting
{
    NSString * result = nil;
    
    if (setting == appSettings_PropertyClass_PhoneFinderTimexRingtoneTone1)
        result = NSLocalizedString(@"Dog Bark", nil);
    else if (setting == appSettings_PropertyClass_PhoneFinderTimexRingtoneTone2)
        result = NSLocalizedString(@"Quack", nil);
    else if (setting == appSettings_PropertyClass_PhoneFinderTimexRingtoneTone3)
        result = NSLocalizedString(@"Sonar", nil);
    
    return result;
}

+ (NSString *) convertIntervalTimerLabelSettingToString: (programWatch_PropertyClass_IntervalTimer_LabelEnum)setting
{
    NSString * result = nil;
    
    if (setting == programWatch_PropertyClass_IntervalTimer_LabelFast)
        result = NSLocalizedString(@"Fast", nil);
    else if (setting == programWatch_PropertyClass_IntervalTimer_LabelSlow)
        result = NSLocalizedString(@"Slow", nil);
    else if (setting == programWatch_PropertyClass_IntervalTimer_LabelEasy)
        result = NSLocalizedString(@"Easy", nil);
    else if (setting == programWatch_PropertyClass_IntervalTimer_LabelHard)
        result = NSLocalizedString(@"Hard", nil);
    else if (setting == programWatch_PropertyClass_IntervalTimer_LabelRun)
        result = NSLocalizedString(@"Run", nil);
    else if (setting == programWatch_PropertyClass_IntervalTimer_LabelWalk)
        result = NSLocalizedString(@"Walk", nil);
    else if (setting == programWatch_PropertyClass_IntervalTimer_LabelLift)
        result = NSLocalizedString(@"Lift", nil);
    else if (setting == programWatch_PropertyClass_IntervalTimer_LabelRest)
        result = NSLocalizedString(@"Rest", nil);
    else if (setting == programWatch_PropertyClass_IntervalTimer_LabelSwim)
        result = NSLocalizedString(@"Swim", nil);
    else if (setting == programWatch_PropertyClass_IntervalTimer_LabelBike)
        result = NSLocalizedString(@"Bike", nil);
    else if (setting == programWatch_PropertyClass_IntervalTimer_LabelMax)
        result = NSLocalizedString(@"Max", nil);
    else if (setting == programWatch_PropertyClass_IntervalTimer_LabelGo)
        result = NSLocalizedString(@"Go", nil);
    
    return result;
}

+ (NSString *) convertTimeOfDayTimeZoneTimeFormatSettingToString: (programWatch_PropertyClass_TimeOfDay_TZTimeFormatEnum) setting
{
    NSString * result = nil;
    
    if (setting == programWatch_PropertyClass_TimeOfDay_TZTimeFormat24HR)
        result = NSLocalizedString(@"24-HR", nil);
    else if (setting == programWatch_PropertyClass_TimeOfDay_TZTimeFormat12HR)
        result = NSLocalizedString(@"12-HR", nil);
    
    return result;
}

+ (NSString *) convertTimeOfDayWatchTimeSyncSettingToString: (programWatch_PropertyClass_TimeOfDay_FollowPhoneTimeEnum) setting
{
    NSString * result = nil;
    
    if (setting == programWatch_PropertyClass_TimeOfDay_FollowPhoneTimeFollowPhone)
        result = NSLocalizedString(@"Follow Phone", nil);
    else if (setting == programWatch_PropertyClass_TimeOfDay_FollowPhoneTimeFollowTimeZone)
        result = NSLocalizedString(@"Select Time Zone", nil);
    else if (setting == programWatch_PropertyClass_TimeOfDay_FollowPhoneTimeManual)
        result = NSLocalizedString(@"Manual", nil);
    
    return result;
}

+ (NSString *) convertTimeOfDayTimeZoneDateFormatSettingToString: (programWatch_PropertyClass_TimeOfDay_TZDateFormatEnum) setting
{
    NSString * result = nil;
        
    if (setting == programWatch_PropertyClass_TimeOfDay_TZDateFormatMMMDD)
        result = NSLocalizedString(@"MMM DD", nil);
    else if (setting == programWatch_PropertyClass_TimeOfDay_TZDateFormatMMDDYY)
        result = NSLocalizedString(@"MM/DD/YY", nil);
    else if (setting == programWatch_PropertyClass_TimeOfDay_TZDateFormatDDMMYY)
        result = NSLocalizedString(@"DD.MM.YY", nil);
    else if (setting == programWatch_PropertyClass_TimeOfDay_TZDateFormatYYYYMMDD)
        result = NSLocalizedString(@"YYYY-MM-DD", nil);
    
    return result;
}

+ (NSString *) convertTimeOfDayTimeZoneOtherDateFormatSettingToString: (programWatch_PropertyClass_TimeOfDay_TZOtherDateFormatEnum) setting
{
    NSString * result = nil;
    
    if (setting == programWatch_PropertyClass_TimeOfDay_TZOtherDateFormatMMDDYY)
        result = NSLocalizedString(@"MM/DD/YY", nil);
    else if (setting == programWatch_PropertyClass_TimeOfDay_TZOtherDateFormatDDMMYY)
        result = NSLocalizedString(@"DD.MM.YY", nil);
    
    return result;
}

+ (NSString *) convertM053TimeOfDayTimeZoneDateFormatSettingToString: (programWatchM053_PropertyClass_TimeOfDay_TZDateFormatEnum) setting
{
    NSString * result = nil;
    
    if (setting == programWatchM053_PropertyClass_TimeOfDay_TZDateFormatMMDD)
        result = NSLocalizedString(@"MM-DD", nil);
    else if (setting == programWatchM053_PropertyClass_TimeOfDay_TZDateFormatDDMM)
        result = NSLocalizedString(@"DD.MM", nil);
    
    return result;
}

+ (NSString *) convertM372TimeOfDayTimeZoneDateFormatSettingToString: (programWatchM372_PropertyClass_TimeOfDay_TZDateFormatEnum) setting
{
    NSString * result = nil;
    
    if (setting == programWatchM372_PropertyClass_TimeOfDay_TZDateFormatMMDD)
        result = NSLocalizedString(@"MM-DD", nil);
    else if (setting == programWatchM372_PropertyClass_TimeOfDay_TZDateFormatDDMM)
        result = NSLocalizedString(@"DD.MM", nil);
    
    return result;
}

+ (NSString *) convertUserGenderSettingToString: (programWatchActivityTracker_PropertyClass_UserInfo_GenderEnum) setting
{
    NSString * result = nil;
    
    if (setting == programWatchActivityTracker_PropertyClass_UserInfo_Gender_Male)
        result = NSLocalizedString(@"Male", nil);
    else if (setting == programWatchActivityTracker_PropertyClass_UserInfo_Gender_Female)
        result = NSLocalizedString(@"Female", nil);
    
    return result;
}
+ (NSString *) convertM053GoalsStatusSettingToString: (programWatchM053_PropertyClass_GoalsStatusEnum) setting
{
    NSString * result = nil;
    
    if (setting == programWatchM053_PropertyClass_GoalsStatus_Off)
        result = NSLocalizedString(@"Off", nil);
    else if (setting == programWatchM053_PropertyClass_GoalsStatus_Steps)
        result = NSLocalizedString(@"Steps", nil);
    if (setting == programWatchM053_PropertyClass_GoalsStatus_Distance)
        result = NSLocalizedString(@"Distance", nil);
    if (setting == programWatchM053_PropertyClass_GoalsStatus_Calories)
        result = NSLocalizedString(@"Calories", nil);
    
    return result;
}
+ (NSString *) convertM053SensorSensitivitySettingToString: (programWatchM053_PropertyClass_Activity_SensorSensitivityEnum)setting
{
    NSString * result = nil;
    
    if (setting == programWatchM053_PropertyClass_Activity_SensorSensitivityLow)
        result = NSLocalizedString(@"Low", nil);
    else if (setting == programWatchM053_PropertyClass_Activity_SensorSensitivityMedium)
        result = NSLocalizedString(@"Medium", nil);
    else if (setting == programWatchM053_PropertyClass_Activity_SensorSensitivityHigh)
        result = NSLocalizedString(@"High", nil);
    
    return result;
}
//TestLog_SleepTracker
+ (NSString *) convertM372SensorSensitivitySettingToStringSleep: (programWatchM372Sleep_PropertyClass_Activity_SensorSensitivityEnum)setting
{
    NSString * result = nil;
    
    if (setting == programWatchM372Sleep_PropertyClass_Activity_SensorSensitivityLow)
        result = NSLocalizedString(@"Low", nil);
    else if (setting == programWatchM372Sleep_PropertyClass_Activity_SensorSensitivityMedium)
        result = NSLocalizedString(@"Medium", nil);
    else if (setting == programWatchM372Sleep_PropertyClass_Activity_SensorSensitivityHigh)
        result = NSLocalizedString(@"High", nil);
    
    return result;
}
//TestLog_SleepTracker
+ (NSString *) convertM372SensorSensitivitySettingToString: (programWatchM372_PropertyClass_Activity_SensorSensitivityEnum)setting
{
    NSString * result = nil;
    
    if (setting == programWatchM372_PropertyClass_Activity_SensorSensitivityLow)
        result = NSLocalizedString(@"Low", nil);
    else if (setting == programWatchM372_PropertyClass_Activity_SensorSensitivityMedium)
        result = NSLocalizedString(@"Medium", nil);
    else if (setting == programWatchM372_PropertyClass_Activity_SensorSensitivityHigh)
        result = NSLocalizedString(@"High", nil);
    
    return result;
}
//TestLog_SleepTracker
+ (NSString *) convertM372TrackSleepSettingToString: (appSettingsM372Sleeptracker_PropertyClass_TrackSleepEnum)setting
{
    NSString * result = nil;
    
    if (setting == appSettingsM372_PropertyClass_ActivityTracking_AllDay)
        result = NSLocalizedString(@"All Day", nil);
    else if (setting == appSettingsM372_PropertyClass_ActivityTracking_DuringBedTime)
        result = NSLocalizedString(@"During Bedtime", nil);
    return result;
}
+ (NSString *) convertUnitsOfMeasureSettingToString: (programWatchActivityTracker_PropertyClass_General_UnitsEnum) setting
{
    NSString * result = nil;
    
    if (setting == programWatchActivityTracker_PropertyClass_General_Units_Imperial)
        result = NSLocalizedString(@"Imperial", nil);
    else if (setting == programWatchActivityTracker_PropertyClass_General_Units_Metric)
        result = NSLocalizedString(@"Metric", nil);
    
    return result;
}
+ (NSString *) convertUnitsOfMeasureSettingToStringSleep: (programWatchActivityTrackerSleep_PropertyClass_General_UnitsEnum) setting
{
    NSString * result = nil;
    
    if (setting == programWatchActivityTrackerSleep_PropertyClass_General_Units_Imperial)
        result = NSLocalizedString(@"Imperial", nil);
    else if (setting == programWatchActivityTrackerSleep_PropertyClass_General_Units_Metric)
        result = NSLocalizedString(@"Metric", nil);
    
    return result;
}


+ (NSString *) convertAlarmFrequencySettingToString: (programWatch_PropertyClass_Alarm_FrequencyEnum) setting
{
    NSString * result = nil;
    
    if (setting == programWatch_PropertyClass_Alarm_Frequency_Once)
        result = NSLocalizedString(@"Once", nil);
    else if (setting == programWatch_PropertyClass_Alarm_Frequency_Daily)
        result = NSLocalizedString(@"Daily", nil);
    else if (setting == programWatch_PropertyClass_Alarm_Frequency_Weekdays)
        result = NSLocalizedString(@"Weekdays", nil);
    else if (setting == programWatch_PropertyClass_Alarm_Frequency_Weekends)
        result = NSLocalizedString(@"Weekends", nil);
    else if (setting == programWatch_PropertyClass_Alarm_Frequency_Monday)
        result = NSLocalizedString(@"Monday", nil);
    else if (setting == programWatch_PropertyClass_Alarm_Frequency_Tuesday)
        result = NSLocalizedString(@"Tuesday", nil);
    else if (setting == programWatch_PropertyClass_Alarm_Frequency_Wednesday)
        result = NSLocalizedString(@"Wednesday", nil);
    else if (setting == programWatch_PropertyClass_Alarm_Frequency_Thursday)
        result = NSLocalizedString(@"Thursday", nil);
    else if (setting == programWatch_PropertyClass_Alarm_Frequency_Friday)
        result = NSLocalizedString(@"Friday", nil);
    else if (setting == programWatch_PropertyClass_Alarm_Frequency_Saturday)
        result = NSLocalizedString(@"Saturday", nil);
    else if (setting == programWatch_PropertyClass_Alarm_Frequency_Sunday)
        result = NSLocalizedString(@"Sunday", nil);
    
    return result;
}
+ (NSString *) convertIntervalTimerActionAtEndM053ToString: (programWatchM053_PropertyClass_IntervalTimers_ActionAtEndEnum) setting
{
    NSString * result = nil;
    
    if (setting == programWatchM053_PropertyClass_IntervalTimers_ActionAtEnd_Repeat)
        result = NSLocalizedString(@"Repeat", nil);
    else if (setting == programWatchM053_PropertyClass_IntervalTimers_ActionAtEnd_Stop)
        result = NSLocalizedString(@"Stop", nil);

    return result;
}
+ (NSString *) convertIntervalTimerActionAtEndM372ToString: (programWatchM372_PropertyClass_IntervalTimers_ActionAtEndEnum) setting
{
    NSString * result = nil;
    
    if (setting == programWatchM372_PropertyClass_IntervalTimers_ActionAtEnd_Repeat)
        result = NSLocalizedString(@"Repeat", nil);
    else if (setting == programWatchM372_PropertyClass_IntervalTimers_ActionAtEnd_Stop)
        result = NSLocalizedString(@"Stop", nil);
    
    return result;
}
+ (NSString *) convertAlarmFrequencySettingM053ToString: (programWatchM053_PropertyClass_Alarm_FrequencyEnum) setting
{
    NSString * result = nil;
    
    if (setting == programWatchM053_PropertyClass_Alarm_Frequency_Daily)
        result = NSLocalizedString(@"Daily", nil);
    else if (setting == programWatchM053_PropertyClass_Alarm_Frequency_Weekdays)
        result = NSLocalizedString(@"Weekdays", nil);
    else if (setting == programWatchM053_PropertyClass_Alarm_Frequency_Weekends)
        result = NSLocalizedString(@"Weekends", nil);
    else if (setting == programWatchM053_PropertyClass_Alarm_Frequency_Monday)
        result = NSLocalizedString(@"Monday", nil);
    else if (setting == programWatchM053_PropertyClass_Alarm_Frequency_Tuesday)
        result = NSLocalizedString(@"Tuesday", nil);
    else if (setting == programWatchM053_PropertyClass_Alarm_Frequency_Wednesday)
        result = NSLocalizedString(@"Wednesday", nil);
    else if (setting == programWatchM053_PropertyClass_Alarm_Frequency_Thursday)
        result = NSLocalizedString(@"Thursday", nil);
    else if (setting == programWatchM053_PropertyClass_Alarm_Frequency_Friday)
        result = NSLocalizedString(@"Friday", nil);
    else if (setting == programWatchM053_PropertyClass_Alarm_Frequency_Saturday)
        result = NSLocalizedString(@"Saturday", nil);
    else if (setting == programWatchM053_PropertyClass_Alarm_Frequency_Sunday)
        result = NSLocalizedString(@"Sunday", nil);
    
    return result;
}
+ (NSString *) convertAlarmFrequencySettingM372ToString: (programWatchM372_PropertyClass_Alarm_FrequencyEnum) setting
{
    NSString * result = nil;
    
    if (setting == programWatchM372_PropertyClass_Alarm_Frequency_Daily)
        result = NSLocalizedString(@"Daily", nil);
    else if (setting == programWatchM372_PropertyClass_Alarm_Frequency_Weekdays)
        result = NSLocalizedString(@"Weekdays", nil);
    else if (setting == programWatchM372_PropertyClass_Alarm_Frequency_Weekends)
        result = NSLocalizedString(@"Weekends", nil);
    else if (setting == programWatchM372_PropertyClass_Alarm_Frequency_Monday)
        result = NSLocalizedString(@"Monday", nil);
    else if (setting == programWatchM372_PropertyClass_Alarm_Frequency_Tuesday)
        result = NSLocalizedString(@"Tuesday", nil);
    else if (setting == programWatchM372_PropertyClass_Alarm_Frequency_Wednesday)
        result = NSLocalizedString(@"Wednesday", nil);
    else if (setting == programWatchM372_PropertyClass_Alarm_Frequency_Thursday)
        result = NSLocalizedString(@"Thursday", nil);
    else if (setting == programWatchM372_PropertyClass_Alarm_Frequency_Friday)
        result = NSLocalizedString(@"Friday", nil);
    else if (setting == programWatchM372_PropertyClass_Alarm_Frequency_Saturday)
        result = NSLocalizedString(@"Saturday", nil);
    else if (setting == programWatchM372_PropertyClass_Alarm_Frequency_Sunday)
        result = NSLocalizedString(@"Sunday", nil);
    
    return result;
}
+ (NSString *) convertAlarmAlertSettingToString: (programWatch_PropertyClass_Alarm_AlertEnum) setting
{
    NSString * result = nil;
    
    if (setting == programWatch_PropertyClass_Alarm_AlertAudible)
        result = NSLocalizedString(@"Sound Only", nil);
    else if (setting == programWatch_PropertyClass_Alarm_AlertVibrate)
        result = NSLocalizedString(@"Vibrate Only", nil);
    else if (setting == programWatch_PropertyClass_Alarm_AlertBoth)
        result = NSLocalizedString(@"Both", nil);
    
    return result;
}

+ (NSString *) convertNotificationsAlertSettingToString: (programWatch_PropertyClass_Notifications_AlertEnum) setting
{
    NSString * result = nil;
    
    if (setting == programWatch_PropertyClass_Notifications_AlertAudible)
        result = NSLocalizedString(@"Sounds", nil);
    else if (setting == programWatch_PropertyClass_Notifications_AlertVibrate)
        result = NSLocalizedString(@"Vibration", nil);
    else if (setting == programWatch_PropertyClass_Notifications_AlertBoth)
        result = NSLocalizedString(@"Both", nil);
    else if (setting == programWatch_PropertyClass_Notifications_AlertNone)
        result = NSLocalizedString(@"Silent", nil);
    
    return result;
}

+ (NSString *) convertSortTypeSettingToString: (appSettings_PropertyClass_Workouts_SortTypeEnum) setting
{
    NSString * result = nil;
    
    if (setting == appSettings_PropertyClass_Workouts_SortType_BestLap)
        result = NSLocalizedString(@"Best Lap", nil);
    else if (setting == appSettings_PropertyClass_Workouts_SortType_AverageLap)
        result = NSLocalizedString(@"Average Lap", nil);
    else if (setting == appSettings_PropertyClass_Workouts_SortType_NumberOfLaps)
        result = NSLocalizedString(@"# of Laps", nil);
    else if (setting == appSettings_PropertyClass_Workouts_SortType_TotalWorkoutTime)
        result = NSLocalizedString(@"Total Time", nil);
    else if (setting == appSettings_PropertyClass_Workouts_SortType_WorkoutDate)
        result = NSLocalizedString(@"Workout Date", nil);
    else if (setting == appSettings_PropertyClass_Workouts_SortType_WorkoutType)
        result = NSLocalizedString(@"Chrono/Interval", nil);
    
    return result;
}

+ (NSString *) convertStoreHistorySettingToString: (appSettings_PropertyClass_Workouts_StoreHistoryEnum) setting
{
    NSString * result = nil;
    
    if (setting == appSettings_PropertyClass_Workouts_StoreHistory_All)
        result = NSLocalizedString(@"All", nil);
    else if (setting == appSettings_PropertyClass_Workouts_StoreHistory_OneMonth)
        result = NSLocalizedString(@"1 month", nil);
    else if (setting == appSettings_PropertyClass_Workouts_StoreHistory_SixMonths)
        result = NSLocalizedString(@"6 months", nil);
    else if (setting == appSettings_PropertyClass_Workouts_StoreHistory_OneYear)
        result = NSLocalizedString(@"1 year", nil);
    else if (setting == appSettings_PropertyClass_Workouts_StoreHistory_TwoYears)
        result = NSLocalizedString(@"2 years", nil);
    
    return result;
}

+ (NSString *) convertLapSplitDisplayFormatSettingToString: (appSettingsM053_PropertyClass_Workouts_LapSplitDisplayEnum) setting
{
    NSString * result = nil;
    
    if (setting == appSettingsM053_PropertyClass_Workouts_LapSplit)
        result = NSLocalizedString(@"Lap/Split", nil);
    else if (setting == appSettingsM053_PropertyClass_Workouts_SplitLap)
        result = NSLocalizedString(@"Split/Lap", nil);
    
    return result;
}

+ (NSString*) convertTimexModuleStringToProductName: (NSString *) module
{
    NSString * productName = nil;
    
    if ([module isEqualToString: M054_WATCH_MODEL])
            productName = @"Run x50+";
    else if ([module isEqualToString: M053_WATCH_MODEL])
            productName = @"Classic 50 Move+";
    else if ([module isEqualToString: M372_WATCH_MODEL])
        productName = @"Metropolitan+";
    else if ([module isEqualToString: M328_WATCH_MODEL])
        productName = @"Guess iQ+";
    else if ([module isEqualToString: M329_WATCH_MODEL])
        productName = @"iQ+ Travel";
    
    return productName;
}

+ (NSString *) convertActivityTrackerGoalLineOptionToString: (activityTracker_Chart_GoalLineOptions) setting forMetric: (activityTracking_CellsEnum) metricType
{
    NSString * result = nil;
    
    if (setting == activityTracker_Chart_GoalLineOptions_Goal)
    {
        double goal = 0;
        NSString * goalSubString = nil;
        switch (metricType)
        {
            case activityTracking_Cells_Steps:
            {
                //TestLog_SetTheCorrectGoal
                //NSString * key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM053_PropertyClass_Goals andIndex: appSettingsM053_PropertyClass_Goals_Steps];
                NSString * key = [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan ? [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372_PropertyClass_Goals andIndex: appSettingsM372_PropertyClass_Goals_Steps] : [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM053_PropertyClass_Goals andIndex: appSettingsM053_PropertyClass_Goals_Steps];

                goal = [[NSUserDefaults standardUserDefaults] integerForKey: key];
                goalSubString = [NSString stringWithFormat: @"%ld %@", (long) goal, NSLocalizedString(@"steps", nil)];
            }
                break;
            case activityTracking_Cells_Calories:
            {
                NSString * key = [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan ? [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372_PropertyClass_Goals andIndex: appSettingsM372_PropertyClass_Goals_Calories] : [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM053_PropertyClass_Goals andIndex: appSettingsM053_PropertyClass_Goals_Calories];
                goal = [[NSUserDefaults standardUserDefaults] integerForKey: key];
                goalSubString = [NSString stringWithFormat: @"%.1f %@", (CGFloat) goal / 10.0f, [iDevicesUtil isActivityTrackerUnitsOfMeasureImperial]?NSLocalizedString(@"Cal", nil):NSLocalizedString(@"kcal", nil)];
                
            }
                break;
            case activityTracking_Cells_Distance:
            {
                //TestLog_SetTheCorrectGoal
                //NSString * key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM053_PropertyClass_Goals andIndex: appSettingsM053_PropertyClass_Goals_Distance];
                NSString * key = [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan ? [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372_PropertyClass_Goals andIndex: appSettingsM372_PropertyClass_Goals_Distance] : [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM053_PropertyClass_Goals andIndex: appSettingsM053_PropertyClass_Goals_Distance];

                CGFloat currentMetric;
                if([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
                {
                    goal = [[NSUserDefaults standardUserDefaults] doubleForKey: key];
                    currentMetric = (CGFloat) goal;
                }
                else
                {
                    goal = [[NSUserDefaults standardUserDefaults] integerForKey: key];
                    currentMetric = (CGFloat) goal / 100.0f;
                }
                
                if ([iDevicesUtil isActivityTrackerUnitsOfMeasureImperial])
                {
                    CGFloat currentDistanceInMiles = [iDevicesUtil convertKilometersToMiles: currentMetric];
                    goalSubString = [NSString stringWithFormat: @"%.2f %@", currentDistanceInMiles, NSLocalizedString(@"miles", nil)];
                }
                else
                    goalSubString = [NSString stringWithFormat: @"%.2f %@", currentMetric, NSLocalizedString(@"km.", nil)];
            }
                break;
                //TestLog_SleepTrackerImplementation start
            case activityTracking_Cells_Sleep:
            {
                
                NSString * key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM053_PropertyClass_Goals andIndex: appSettingsM053_PropertyClass_Goals_Steps];
                goal = [[NSUserDefaults standardUserDefaults] integerForKey: key];
                goalSubString = [NSString stringWithFormat: @"%ld %@", (long) goal, NSLocalizedString(@"hrs", nil)];
            }
                break;
                //TestLog_SleepTrackerImplementation end
            default:
                break;
        }
        
        result = [NSString stringWithFormat: @"%@: %@", NSLocalizedString(@"Current Goal", nil), goalSubString];
    }
    else if (setting == activityTracker_Chart_GoalLineOptions_WeeklyAverage)
        result = NSLocalizedString(@"This Week's Daily Average", nil);
    else if (setting == activityTracker_Chart_GoalLineOptions_MonthlyAverage)
        result = NSLocalizedString(@"This Month's Daily Average", nil);
    else if (setting == activityTracker_Chart_GoalLineOptions_YearlyAverage)
        result = NSLocalizedString(@"This Year's Daily Average", nil);
    else if (setting == activityTracker_Chart_GoalLineOptions_AllTimeAverage)
        result = NSLocalizedString(@"All Time Daily Average", nil);
    
    return result;
}

+ (NSString*) convertWatchStyleToProductName: (timexDatalinkWatchStyle) module
{
    NSString * watchName = nil;
    switch (module)
    {
        case timexDatalinkWatchStyle_ActivityTracker:
            watchName = [iDevicesUtil convertTimexModuleStringToProductName: M053_WATCH_MODEL];
            break;
        case timexDatalinkWatchStyle_M054:
            watchName = [iDevicesUtil convertTimexModuleStringToProductName: M054_WATCH_MODEL];
            break;
        case timexDatalinkWatchStyle_Metropolitan:
            watchName = [iDevicesUtil convertTimexModuleStringToProductName: M372_WATCH_MODEL];
            break;
        default:
            break;
    }
    
    return watchName;
}

+ (NSString *) convertUploadSiteSettingToString: (TimexUploadServicesOptions) setting
{
    NSString * result = nil;
    
    if (setting == TimexUploadServicesOptions_TrainingPeaks)
    {
        result = @"TRAINING PEAKS";
    }
    else if (setting == TimexUploadServicesOptions_RunKeeper)
    {
        result = @"RUN KEEPER";
    }
    else if (setting == TimexUploadServicesOptions_MapMyFitness)
    {
        result = @"MAP MY FITNESS";
    }
    else if (setting == TimexUploadServicesOptions_DailyMile)
    {
        result = @"DAILY MILE";
    }
    else if (setting == TimexUploadServicesOptions_Strava)
    {
        result = @"STRAVA";
    }
    
    return result;
}

+ (NSURL *) getURLforUploadSiteSetting: (TimexUploadServicesOptions) setting
{
    NSString * result = nil;
    
    if (setting == TimexUploadServicesOptions_TrainingPeaks)
    {
        result = @"http://www.trainingpeaks.com";
    }
    else if (setting == TimexUploadServicesOptions_RunKeeper)
    {
        result = @"http://www.runkeeper.com";
    }
    else if (setting == TimexUploadServicesOptions_MapMyFitness)
    {
        result = @"http://www.mapmyfitness.com";
    }
    else if (setting == TimexUploadServicesOptions_DailyMile)
    {
        result = @"http://www.dailymile.com";
    }
    else if (setting == TimexUploadServicesOptions_Strava)
    {
        result = @"http://www.strava.com";
    }
    
    return (result == nil ? NULL : [NSURL URLWithString: result]);
}

+ (void) UpdateCustomAlarmTimeForEvent: (EKEvent *) wantsNewAlarm withAlarmIndex: (calendar_alarmTimeOptions) idx
{
    BOOL alreadyExists = FALSE;
    NSString * eventID = [wantsNewAlarm eventIdentifier];
    NSDate * eventDate = [wantsNewAlarm startDate];
    NSTimeInterval eventDateInterval = [eventDate timeIntervalSince1970];
    
    NSString * expression = [NSString stringWithFormat:@"SELECT EventKey, AlarmID FROM CalendarEventAlarms WHERE EventKey = '%@' AND EventDate = %f;", eventID, eventDateInterval];
    
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
    if (query)
    {
        if (query->getRowCount() > 0)
        {
            alreadyExists = TRUE;
        }
        
        delete query;
    }
    
    if (alreadyExists)
    {
        OTLog(@"Updating Profile Alarm");
        NSString * expression = [NSString stringWithFormat:@"UPDATE CalendarEventAlarms SET EventKey = '%@', EventDate = %f, AlarmID = %d WHERE EventKey = '%@' AND EventDate = %f;", eventID, eventDateInterval, idx, eventID, eventDateInterval];
        TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
        if (query)
        {
            delete query;
        }
    }
    else
    {
        NSString * expressionNew = [NSString stringWithFormat:@"INSERT INTO CalendarEventAlarms ('EventKey', 'EventDate', 'AlarmID') VALUES ('%@', %f, %d);", eventID, eventDateInterval, idx];
        TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expressionNew];
        if (query)
        {
            delete query;
        }
    }
}

+ (void) AddExcludedCalendarEvent: (EKEvent *) excludedEvent
{
    NSString * eventID = [excludedEvent eventIdentifier];
    NSDate * eventDate = [excludedEvent startDate];
    NSTimeInterval eventDateInterval = [eventDate timeIntervalSince1970];
    NSString * expressionNew = [NSString stringWithFormat:@"INSERT INTO ExcludedCalendarEvents ('EventKey', 'EventDate') VALUES ('%@', %f);", eventID, eventDateInterval];
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expressionNew];
    if (query)
    {
        delete query;
    }
}

+ (const char *)centralManagerStateToString: (int)state
{
    switch(state)
    {
        case CBCentralManagerStateUnknown:
            return "State unknown (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateResetting:
            return "State resetting (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateUnsupported:
            return "State BLE unsupported (CBCentralManagerStateResetting)";
        case CBCentralManagerStateUnauthorized:
            return "State unauthorized (CBCentralManagerStateUnauthorized)";
        case CBCentralManagerStatePoweredOff:
            return "State BLE powered off (CBCentralManagerStatePoweredOff)";
        case CBCentralManagerStatePoweredOn:
            return "State powered up and ready (CBCentralManagerStatePoweredOn)";
        default:
            return "State unknown";
    }
    return "Unknown state";
}

+ (const char *)UUIDToString:(CFUUIDRef)UUID
{
    if (!UUID) return "NULL";
    CFStringRef s = CFUUIDCreateString(NULL, UUID);
    return CFStringGetCStringPtr(s, 0);
}

+ (const char *)CBUUIDToString:(CBUUID *) UUID
{
    return [[UUID.data description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy];
}

+ (int)compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2
{
    char b1[16];
    char b2[16];
    [UUID1.data getBytes:b1];
    [UUID2.data getBytes:b2];
    if (memcmp(b1, b2, UUID1.data.length) == 0)return 1;
    else return 0;
}

+ (CBService *)findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p
{
    for(int i = 0; i < p.services.count; i++)
    {
        CBService *s = [p.services objectAtIndex:i];
        if ([self compareCBUUID:s.UUID UUID2:UUID]) return s;
    }
    return nil; //Service not found on this peripheral
}

+ (CBCharacteristic *)findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service
{
    for(int i=0; i < service.characteristics.count; i++)
    {
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        if ([iDevicesUtil compareCBUUID:c.UUID UUID2:UUID]) return c;
    }
    return nil; //Characteristic not found on this service
}

+(NSArray *) getDeviceFeatureDataForDevice:(NSString*) deviceTypeStr{
    
    NSArray* _deviceFeatureData;
    
    if ( _deviceFeatureData == nil )
    {
        NSDictionary* sourceData = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DeviceFeatures" ofType:@"plist"]];
        
        if ( sourceData )
        {
            _deviceFeatureData = [[NSArray alloc] initWithArray:[sourceData objectForKey:deviceTypeStr]];
        }
    }
    
    if ([self shouldIncludeDerivedData])
    {
        return _deviceFeatureData;
    }
    else
    {
        //removed derived data;
        NSMutableArray *modifiedDeviceFeatureData = [[NSMutableArray alloc] init]; //WithArray:_deviceFeatureData];
        //cycle through _deviceFeatureData, adding in ONLY NON-Derived Data
        //isDerivedFeatureType
        for(int i = 0; i< [_deviceFeatureData count]; i++)
        {
            if ([_deviceFeatureData objectAtIndex:i])
            {
                if (![iDevicesUtil isDerivedFeatureType:[_deviceFeatureData objectAtIndex:i]]){
                    [modifiedDeviceFeatureData addObject:[_deviceFeatureData objectAtIndex:i]];
                }
            }
        }
        return modifiedDeviceFeatureData;
    }
}

+(BOOL) shouldIncludeDerivedData
{
    return YES;
}

+(NSData *)convertOutgoingCommandsToNSData:(TDDeviceCommands) commandsSet
{
    const int buffersize = 3;
    
    uint8_t buffer[buffersize];
    
    buffer[0] = commandsSet.erasedLog;
    buffer[1] = commandsSet.blinkedLED;
    buffer[2] = commandsSet.restoredDefaults;
    
    NSData *sendData = [NSData dataWithBytes:&buffer length:buffersize];
    
    return sendData;
}
+(NSData *) convertOutgoingDateToData:(NSDate *) date
{
    uint8_t buffer[7];
    
    NSDateFormatter *formattingDate = [[NSDateFormatter alloc]init];
    
    [formattingDate setTimeZone:[NSTimeZone systemTimeZone]];
    
    [formattingDate stringFromDate:date];
    
    // Get the system calendar
    NSCalendar *sysCalendar = [NSCalendar currentCalendar];
    
    // Get conversion to months, days, hours, minutes
    unsigned int unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond ;
    
    NSDateComponents *conversionInfo = [sysCalendar components:unitFlags fromDate:date];
    
    uint16_t year = [conversionInfo year];
    uint8_t month = [conversionInfo month];
    uint8_t day = [conversionInfo day];
    uint8_t hour = [conversionInfo hour];
    uint8_t min = [conversionInfo minute];
    uint8_t sec = [conversionInfo second];
    
    
    memcpy(buffer, &year, 2);
    
    buffer[2] = month;
    buffer[3] = day;
    buffer[4] = hour;
    buffer[5] = min;
    buffer[6] = sec;
    
    return [NSData dataWithBytes:&buffer length:7];
}

+(BOOL) isDerivedFeatureType: (NSString *) fType
{
    BOOL isDerived = NO;
    NSDictionary *featureData = [self getFeatureData: fType];
    if (featureData)
        isDerived = [[featureData objectForKey:@"Is_Derived"] boolValue];
    
    return isDerived;
}

+(NSDictionary *) getFeatureData:(NSString*) featureTypeStr
{
    NSDictionary* sourceData = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FeaturesData" ofType:@"plist"]];
    NSDictionary* featureData;
    
    if ( sourceData )
    {
        featureData = [[NSDictionary alloc] initWithDictionary:[sourceData objectForKey:featureTypeStr]];
    }
    
    return featureData;
}

+(NSString*) generateGUID
{
    CFUUIDRef uuid = CFUUIDCreate(nil);
    
    CFStringRef uuidStr = CFUUIDCreateString(nil, uuid);
    
    NSString* string = (__bridge NSString*)uuidStr;
    
    CFRelease(uuid);
    CFRelease(uuidStr);
    
    return string;
}

+ (calendar_alarmTimeOptions) getEventAlarmTime: (EKEvent *) eventToProcess
{
    calendar_alarmTimeOptions       currentAlarmOption;
    
    NSString * eventID = [eventToProcess eventIdentifier];
    NSDate * eventDate = [eventToProcess startDate];
    NSTimeInterval eventDateInterval = [eventDate timeIntervalSince1970];
    NSString * expression = [NSString stringWithFormat:@"SELECT EventKey, EventDate, AlarmID FROM CalendarEventAlarms WHERE EventKey = '%@' AND EventDate = %f;", eventID, eventDateInterval];
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
    
    if (query && query->getRowCount() > 0)
    {
        currentAlarmOption = (calendar_alarmTimeOptions)query->getIntColumnForRow(0, @"AlarmID");
    }
    else
    {
        NSArray * alarms = eventToProcess.alarms;
        if (alarms.count == 0) //there are no alarm set for that appointment..
        {
            currentAlarmOption = calendar_alarmTimeOptions_15min;
        }
        else
        {
            NSTimeInterval shortest = DBL_MAX;
            for (int i = 0; i < alarms.count; i++)
            {
                EKAlarm * alarm = [alarms objectAtIndex: i];
                NSTimeInterval alarmInterval = 0;
                if (alarm.absoluteDate == NULL)
                {
                    //relative alarm
                    alarmInterval = fabs(alarm.relativeOffset);
                }
                else
                {
                    //absolute alarm
                    alarmInterval = fabs([eventDate timeIntervalSinceDate: alarm.absoluteDate]); //absolute value
                }
                if (alarmInterval < shortest)
                    shortest = alarmInterval;
            }
            
            bool perfectMatch = false;
            for (int k = 0; k < calendar_alarmTimeOptions_LAST; k++)
            {
                if (shortest == [self getSecondsValueForAlarmSetting: (calendar_alarmTimeOptions) k])
                {
                    perfectMatch = true;
                    currentAlarmOption = (calendar_alarmTimeOptions)k;
                    break;
                }
            }
            if (!perfectMatch)
            {
                for (int k = 0; k < calendar_alarmTimeOptions_LAST; k++)
                {
                    NSTimeInterval rangeLow = [self getSecondsValueForAlarmSetting: (calendar_alarmTimeOptions) k];
                    NSTimeInterval rangeHigh = (k == calendar_alarmTimeOptions_LAST - 1) ? DBL_MAX : [self getSecondsValueForAlarmSetting: (calendar_alarmTimeOptions) (k + 1)];
                    if (shortest > rangeLow && shortest < rangeHigh)
                    {
                        currentAlarmOption = (k < calendar_alarmTimeOptions_LAST - 1) ? (calendar_alarmTimeOptions) (k + 1) : (calendar_alarmTimeOptions) k;
                        break;
                    }
                }
            }
        }
    }
    
    if (query)
    {
        delete query;
    }
    
    return currentAlarmOption;
}

+ (NSTimeInterval) getEventAlarmTimeInSeconds: (EKEvent *) eventToProcess
{
    NSTimeInterval  seconds = 0.0;
    NSDate          * eventDate = [eventToProcess startDate];
    NSArray         * alarms = eventToProcess.alarms;
    
    if (alarms.count == 0) //there are no alarm set for that appointment..
    {
        seconds = DBL_MAX;
    }
    else
    {
        NSTimeInterval earliest = DBL_MAX;
        NSTimeInterval latest = DBL_MAX;
        
        for (int i = 0; i < alarms.count; i++)
        {
            EKAlarm * alarm = [alarms objectAtIndex: i];
            NSTimeInterval alarmInterval = 0;
            if (alarm.absoluteDate == NULL)
                alarmInterval = alarm.relativeOffset;                                   //relative alarm
            else
                alarmInterval = [eventDate timeIntervalSinceDate: alarm.absoluteDate];  //absolute alarm
            
            NSDate * dateForCurrentAlarm = [NSDate dateWithTimeInterval: alarmInterval sinceDate: eventDate];
            
            //we need to store the alarm which is the latest in time....
            if (latest == DBL_MAX)
                latest = alarmInterval;
            else
            {
                NSDate * currentLatest = [NSDate dateWithTimeInterval: latest sinceDate: eventDate];
                if ([dateForCurrentAlarm compare: currentLatest] == NSOrderedDescending)
                {
                    latest = alarmInterval;
                }
            }
            
            //in case of appointment having multiple alarms... decide which alarm to send
            if (alarms.count > 1)
            {
                //check if the alarm that we consider sending to the watch is in the past... if it is, no point sending it
                if ([dateForCurrentAlarm timeIntervalSinceNow] < 0.0)
                {
                    //this alarm is in the past already and will not be fired by the watch, so we can ignore it.
                    continue;
                }
            }
            
            if (earliest == DBL_MAX)
                earliest = alarmInterval;
            else
            {
                NSDate * currentEarliest = [NSDate dateWithTimeInterval: earliest sinceDate: eventDate];
                if ([currentEarliest compare: dateForCurrentAlarm] == NSOrderedDescending)
                {
                    //currentLongest is later than dateForCurrentAlarm
                    earliest = alarmInterval;
                }
            }
        }
        
        //per Timex request, if appointment has alarms, we never send 0xFF, even if all alarms are in the past
        if (earliest != DBL_MAX)
        {
            seconds = earliest;
        }
        else
        {
            seconds = latest;
        }
    }
    
    return seconds;
}

+ (NSTimeInterval) getSecondsValueForAlarmSetting: (calendar_alarmTimeOptions) setting
{
    NSTimeInterval value = DBL_MAX;
    switch (setting)
    {
        case calendar_alarmTimeOptions_Now:
            value = 0;
            break;
        case calendar_alarmTimeOptions_15min:
            value = 60 * 15;
            break;
        case calendar_alarmTimeOptions_30min:
            value = 60 * 30;
            break;
        case calendar_alarmTimeOptions_60min:
            value = 60 * 60;
            break;
        case calendar_alarmTimeOptions_120min:
            value = 60 * 120;
            break;
        default:
            break;
    }
    
    return value;
}

+ (programWatchM053_PropertyClass_Activity_SensorSensitivityEnum) getM053CurrentSensorSensitivity
{
    programWatchM053_PropertyClass_Activity_SensorSensitivityEnum returnValue;
    
    NSString * goalsSetting = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM053_PropertyClass_ActivityTracking andIndex: programWatchM053_PropertyClass_ActivityTracking_SensorSensitivity];
    returnValue = (programWatchM053_PropertyClass_Activity_SensorSensitivityEnum)[[NSUserDefaults standardUserDefaults] integerForKey: goalsSetting];
    
    return returnValue;
}

+ (programWatchM372_PropertyClass_Activity_SensorSensitivityEnum) getM372CurrentSensorSensitivity
{
    programWatchM372_PropertyClass_Activity_SensorSensitivityEnum returnValue;
    
    NSString * goalsSetting = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM372_PropertyClass_ActivityTracking andIndex: programWatchM372_PropertyClass_ActivityTracking_SensorSensitivity];
    returnValue = (programWatchM372_PropertyClass_Activity_SensorSensitivityEnum)[[NSUserDefaults standardUserDefaults] integerForKey: goalsSetting];
    
    return returnValue;
}
//TestLog_SleepTracker
+ (programWatchM372Sleep_PropertyClass_Activity_SensorSensitivityEnum) getM372CurrentSensorSensitivitySleep
{
    programWatchM372Sleep_PropertyClass_Activity_SensorSensitivityEnum returnValue;
    
    NSString * goalsSetting = [iDevicesUtil createKeyForWatchControlPropertyWithClass: appSettingsM372Sleeptracker_PropertyClass_Activity andIndex: appSettingsM372Sleeptracker_PropertyClass_Activity_Sensor_Sensitivity];
    returnValue = (programWatchM372Sleep_PropertyClass_Activity_SensorSensitivityEnum)[[NSUserDefaults standardUserDefaults] integerForKey: goalsSetting];
    return returnValue;
}
//TestLog_SleepTracker

+ (BOOL) areStepsEnabled
{
    BOOL returnValue = FALSE;
    
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_ActivityTracker)
    {
        NSString * goalsSetting = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM053_PropertyClass_ActivityTracking andIndex: programWatchM053_PropertyClass_ActivityTracking_GoalsStatus];
        NSInteger goalsValue = [[NSUserDefaults standardUserDefaults] integerForKey: goalsSetting];
        if (goalsValue == programWatchM053_PropertyClass_GoalsStatus_Steps)
            returnValue = TRUE;
    }
    else
        returnValue = TRUE;
    
    return returnValue;
}
+ (BOOL) isDistanceEnabled
{
    BOOL returnValue = FALSE;
    
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_ActivityTracker)
    {
        NSString * goalsSetting = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM053_PropertyClass_ActivityTracking andIndex: programWatchM053_PropertyClass_ActivityTracking_GoalsStatus];
        NSInteger goalsValue = [[NSUserDefaults standardUserDefaults] integerForKey: goalsSetting];
        if (goalsValue == programWatchM053_PropertyClass_GoalsStatus_Distance)
            returnValue = TRUE;
    }
    else
        returnValue = TRUE;
    
    return returnValue;
}
+ (BOOL) areCaloriesEnabled
{
    BOOL returnValue = FALSE;
    
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_ActivityTracker)
    {
        NSString * goalsSetting = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM053_PropertyClass_ActivityTracking andIndex: programWatchM053_PropertyClass_ActivityTracking_GoalsStatus];
        NSInteger goalsValue = [[NSUserDefaults standardUserDefaults] integerForKey: goalsSetting];
        if (goalsValue == programWatchM053_PropertyClass_GoalsStatus_Calories)
            returnValue = TRUE;
    }
    else
        returnValue = TRUE;
    
    return returnValue;
}

+ (BOOL) isSensorEnabled
{
    BOOL returnValue = FALSE;
    
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_ActivityTracker)
    {
        NSString * goalsSetting = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM053_PropertyClass_ActivityTracking andIndex: programWatchM053_PropertyClass_ActivityTracking_SensorStatus];
        returnValue = [[NSUserDefaults standardUserDefaults] boolForKey: goalsSetting];
    }
    else
        returnValue = TRUE;
    
    return returnValue;
}
+ (NSDate *) dayBeforeOfToday
{    
    NSDate *now = [NSDate date];
    int daysToAdd = -1;
    
    // set up date components
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:daysToAdd];
    
    // create a calendar
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    
    NSDate *yesterday = [gregorian dateByAddingComponents:components toDate:now options:0];
    
    return  yesterday;
}
+ (NSDate *) todayDateAtMidnight
{
    NSDate* result = nil;
    
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    NSDateComponents *comps = [gregorian components: NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate: [NSDate date]];
    [comps setHour: 0];
    [comps setMinute: 0];
    [comps setSecond: 0];
    
    result = [gregorian dateFromComponents: comps];
    return result;
}

+ (NSInteger) calculateNumberOfDaysBetweenDate: (NSDate *) startDate andDate: (NSDate *) endDate
{
    NSInteger counter = 0;
    NSCalendar * myCalendar = [NSCalendar currentCalendar];
    
    NSDateComponents * additionComponentsDay = [[NSDateComponents alloc] init];
    [additionComponentsDay setDay: 1];
    NSDate * oneDayFromStart = [myCalendar dateByAddingComponents: additionComponentsDay toDate: startDate options: 0];
    NSDate * oneDayFromEnd = [myCalendar dateByAddingComponents: additionComponentsDay toDate: endDate options: 0];
    while ([oneDayFromStart compare: oneDayFromEnd] != NSOrderedDescending)
    {
        counter++;
        oneDayFromStart = [myCalendar dateByAddingComponents: additionComponentsDay toDate: oneDayFromStart options: 0];
    }
    
    return counter;
}
+ (NSArray *) getStepsDataSinceDate: (NSTimeInterval) since toDate: (NSTimeInterval) to
{
    NSDate * startingDate = [NSDate dateWithTimeIntervalSince1970: since];
    NSDate * endingDate = [NSDate dateWithTimeIntervalSince1970: to];

    NSInteger numberOfDays = [iDevicesUtil calculateNumberOfDaysBetweenDate: startingDate andDate: endingDate];
    
    NSMutableArray * collectionOfData = [[NSMutableArray alloc] initWithCapacity: numberOfDays];
    for (int i = 0; i < numberOfDays; i++)
    {
        [collectionOfData addObject: [NSNumber numberWithInteger: 0]]; //initialize to 0
    }
    NSString * expression = [NSString stringWithFormat: @"SELECT * FROM ActivityData WHERE WorkoutID IS NULL AND LapID IS NULL AND ActivityDate >= %f AND ActivityDate <= %f;", since, to];
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
    if (query)
    {
        NSInteger rowCount = query->getRowCount();
        if (rowCount > 0)
        {
            for (int i = 0; i < rowCount; i++ )
            {
                NSNumber * data = [NSNumber numberWithInt: query->getIntColumnForRow(i, @"ActivitySteps")];
                NSTimeInterval date = query->getDoubleColumnForRow(i, @"ActivityDate");
                NSDate * activityDate = [NSDate dateWithTimeIntervalSince1970: date];
                
                NSInteger numberOfDaysSinceRangeStart = [iDevicesUtil calculateNumberOfDaysBetweenDate: startingDate andDate: activityDate];
                if (numberOfDaysSinceRangeStart != 0) //just the safety....
                    [collectionOfData replaceObjectAtIndex: numberOfDaysSinceRangeStart - 1 withObject: data];
            }
        }
        
        delete query;
    }
    
    return collectionOfData;
}
+ (NSInteger) getStepsSinceDate: (NSTimeInterval) since toDate: (NSTimeInterval) to
{
    NSInteger response = 0;
    NSString * expression = [NSString stringWithFormat: @"SELECT * FROM ActivityData WHERE WorkoutID IS NULL AND LapID IS NULL AND ActivityDate >= %f AND ActivityDate <= %f;", since, to];
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
    if (query)
    {
        NSInteger rowCount = query->getRowCount();
        if (rowCount > 0)
        {
            NSMutableArray * steps = [[NSMutableArray alloc] initWithCapacity: rowCount];
            for (int i = 0; i < rowCount; i++ )
            {
                NSNumber * data = [NSNumber numberWithInt: query->getIntColumnForRow(i, @"ActivitySteps")];
                [steps addObject: data];
            }
            
            NSNumber * total = [steps valueForKeyPath:@"@sum.self"];
            response = [total integerValue];
        }
        
        delete query;
    }
    
    return response;
}
+ (NSArray *) getCaloriesDataSinceDate: (NSTimeInterval) since toDate: (NSTimeInterval) to
{
    NSDate * startingDate = [NSDate dateWithTimeIntervalSince1970: since];
    NSDate * endingDate = [NSDate dateWithTimeIntervalSince1970: to];
    
    NSInteger numberOfDays = [iDevicesUtil calculateNumberOfDaysBetweenDate: startingDate andDate: endingDate];
    
    NSMutableArray * collectionOfData = [[NSMutableArray alloc] initWithCapacity: numberOfDays];
    for (int i = 0; i < numberOfDays; i++)
    {
        [collectionOfData addObject: [NSNumber numberWithInteger: 0]]; //initialize to 0
    }
    NSString * expression = [NSString stringWithFormat: @"SELECT * FROM ActivityData WHERE WorkoutID IS NULL AND LapID IS NULL AND ActivityDate >= %f AND ActivityDate <= %f;", since, to];
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
    if (query)
    {
        NSInteger rowCount = query->getRowCount();
        if (rowCount > 0)
        {
            for (int i = 0; i < rowCount; i++ )
            {
                NSNumber * data = [NSNumber numberWithInt: query->getIntColumnForRow(i, @"ActivityCalories")];
                NSTimeInterval date = query->getDoubleColumnForRow(i, @"ActivityDate");
                NSDate * activityDate = [NSDate dateWithTimeIntervalSince1970: date];
                
                NSInteger numberOfDaysSinceRangeStart = [iDevicesUtil calculateNumberOfDaysBetweenDate: startingDate andDate: activityDate];
                if (numberOfDaysSinceRangeStart != 0) //just the safety....
                    [collectionOfData replaceObjectAtIndex: numberOfDaysSinceRangeStart - 1 withObject: data];
            }
        }
        
        delete query;
    }
    
    return collectionOfData;
}
+ (NSInteger) getCaloriesSinceDate: (NSTimeInterval) since toDate: (NSTimeInterval) to
{
    NSInteger response = 0;
    NSString * expression = [NSString stringWithFormat: @"SELECT * FROM ActivityData WHERE WorkoutID IS NULL AND LapID IS NULL AND ActivityDate >= %f AND ActivityDate <= %f;", since, to];
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
    if (query)
    {
        NSInteger rowCount = query->getRowCount();
        if (rowCount > 0)
        {
            NSMutableArray * calories = [[NSMutableArray alloc] initWithCapacity: rowCount];
            for (int i = 0; i < rowCount; i++ )
            {
                NSNumber * data = [NSNumber numberWithInt: query->getIntColumnForRow(i, @"ActivityCalories")];
                [calories addObject: data];
            }
            
            NSNumber * total = [calories valueForKeyPath:@"@sum.self"];
            response = [total integerValue];
        }
        
        delete query;
    }
    
    return response;
}
+ (NSArray *) getDistanceDataSinceDate: (NSTimeInterval) since toDate: (NSTimeInterval) to
{
    NSDate * startingDate = [NSDate dateWithTimeIntervalSince1970: since];
    NSDate * endingDate = [NSDate dateWithTimeIntervalSince1970: to];
    
    NSInteger numberOfDays = [iDevicesUtil calculateNumberOfDaysBetweenDate: startingDate andDate: endingDate];
    
    NSMutableArray * collectionOfData = [[NSMutableArray alloc] initWithCapacity: numberOfDays];
    for (int i = 0; i < numberOfDays; i++)
    {
        [collectionOfData addObject: [NSNumber numberWithInteger: 0]]; //initialize to 0
    }
    NSString * expression = [NSString stringWithFormat: @"SELECT * FROM ActivityData WHERE WorkoutID IS NULL AND LapID IS NULL AND ActivityDate >= %f AND ActivityDate <= %f;", since, to];
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
    if (query)
    {
        NSInteger rowCount = query->getRowCount();
        if (rowCount > 0)
        {
            for (int i = 0; i < rowCount; i++ )
            {
                NSNumber * data = [NSNumber numberWithInt: query->getIntColumnForRow(i, @"ActivityDistance")];
                NSTimeInterval date = query->getDoubleColumnForRow(i, @"ActivityDate");
                NSDate * activityDate = [NSDate dateWithTimeIntervalSince1970: date];
                
                NSInteger numberOfDaysSinceRangeStart = [iDevicesUtil calculateNumberOfDaysBetweenDate: startingDate andDate: activityDate];
                if (numberOfDaysSinceRangeStart != 0) //just the safety....
                    [collectionOfData replaceObjectAtIndex: numberOfDaysSinceRangeStart - 1 withObject: data];
            }
        }
        
        delete query;
    }
    
    return collectionOfData;
}
+ (NSInteger) getDistanceSinceDate: (NSTimeInterval) since toDate: (NSTimeInterval) to
{
    NSInteger response = 0;
    NSString * expression = [NSString stringWithFormat: @"SELECT * FROM ActivityData WHERE WorkoutID IS NULL AND LapID IS NULL AND ActivityDate >= %f AND ActivityDate <= %f;", since, to];
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
    if (query)
    {
        NSInteger rowCount = query->getRowCount();
        if (rowCount > 0)
        {
            NSMutableArray * dist = [[NSMutableArray alloc] initWithCapacity: rowCount];
            for (int i = 0; i < rowCount; i++ )
            {
                NSNumber * data = [NSNumber numberWithInt: query->getIntColumnForRow(i, @"ActivityDistance")];
                [dist addObject: data];
            }
            
            NSNumber * total = [dist valueForKeyPath:@"@sum.self"];
            response = [total integerValue];
        }
        
        delete query;
    }
    
    return response;
}

+ (NSInteger) getDistanceForWorkout: (TDWorkoutData *) workout
{
    NSInteger response = 0;
    NSString * expression = [NSString stringWithFormat: @"SELECT * FROM ActivityData WHERE WorkoutID = %ld AND LapID IS NULL;", (long)workout.mKey];
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
    if (query)
    {
        NSInteger rowCount = query->getRowCount();
        if (rowCount > 0)
        {
            response = query->getIntColumnForRow(0, @"ActivityDistance");
        }
        
        delete query;
    }
    
    return response;
}

+ (NSInteger) getAverageStepsSince: (NSTimeInterval) since toDate: (NSTimeInterval) to
{
    NSInteger response = 0;
    
    NSString * expression = [NSString stringWithFormat: @"SELECT * FROM ActivityData WHERE WorkoutID IS NULL AND LapID IS NULL AND ActivityDate >= %f AND ActivityDate <= %f;", since, to];
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
    if (query)
    {
        NSInteger rowCount = query->getRowCount();
        if (rowCount > 0)
        {
            NSMutableArray * steps = [[NSMutableArray alloc] initWithCapacity: rowCount];
            for (int i = 0; i < rowCount; i++ )
            {
                //CGFloat date = query->getIntColumnForRow(i, @"ActivityDate");
                //NSDate * actiDate = [NSDate dateWithTimeIntervalSince1970: date];
                
                NSNumber * data = [NSNumber numberWithInt: query->getIntColumnForRow(i, @"ActivitySteps")];
                [steps addObject: data];
            }
            
            NSNumber * average = [steps valueForKeyPath:@"@avg.self"];
            CGFloat averageFloat = [average floatValue];
            response = (NSInteger) averageFloat;
        }
        
        delete query;
    }
    
    return response;
}
+ (NSInteger) getStepsCountForDay
{
    //NSTimeInterval todaySince1970 = [[iDevicesUtil todayDateAtMidnight] timeIntervalSince1970];
    NSTimeInterval yesterdayTest = [[iDevicesUtil dayBeforeOfToday]timeIntervalSince1970];
    return [iDevicesUtil getStepsSinceDate: yesterdayTest toDate: yesterdayTest];
}

+ (NSInteger) getTodaysStepsCount
{
    NSTimeInterval todaySince1970 = [[iDevicesUtil todayDateAtMidnight] timeIntervalSince1970];
    return [iDevicesUtil getStepsSinceDate: todaySince1970 toDate: todaySince1970];
}
+ (NSInteger) getAverageCaloriesSince: (NSTimeInterval) since toDate: (NSTimeInterval) to
{
    NSInteger response = 0;
    
    NSString * expression = [NSString stringWithFormat: @"SELECT * FROM ActivityData WHERE WorkoutID IS NULL AND LapID IS NULL AND ActivityDate >= %f AND ActivityDate <= %f;", since, to];
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
    if (query)
    {
        NSInteger rowCount = query->getRowCount();
        if (rowCount > 0)
        {
            NSMutableArray * calories = [[NSMutableArray alloc] initWithCapacity: rowCount];
            for (int i = 0; i < rowCount; i++ )
            {
                [calories addObject: [NSNumber numberWithInt: query->getIntColumnForRow(i, @"ActivityCalories")]];
            }
            
            NSNumber * average = [calories valueForKeyPath:@"@avg.self"];
            CGFloat averageFloat = [average floatValue];
            response = (NSInteger) averageFloat;
        }
        
        delete query;
    }
    
    return response;
}
+ (NSInteger) getTodaysCaloriesCount
{
    NSTimeInterval todaySince1970 = [[iDevicesUtil todayDateAtMidnight] timeIntervalSince1970];
    return [iDevicesUtil getCaloriesSinceDate: todaySince1970 toDate: todaySince1970];
}
+ (NSInteger) getAverageDistanceSince: (NSTimeInterval) since toDate: (NSTimeInterval) to
{
    NSInteger response = 0;
    
    NSString * expression = [NSString stringWithFormat: @"SELECT * FROM ActivityData WHERE WorkoutID IS NULL AND LapID IS NULL AND ActivityDate >= %f AND ActivityDate <= %f;", since, to];
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
    if (query)
    {
        NSInteger rowCount = query->getRowCount();
        if (rowCount > 0)
        {
            NSMutableArray * distances = [[NSMutableArray alloc] initWithCapacity: rowCount];
            for (int i = 0; i < rowCount; i++ )
            {
                [distances addObject: [NSNumber numberWithInt: query->getIntColumnForRow(i, @"ActivityDistance")]];
            }
            
            NSNumber * average = [distances valueForKeyPath:@"@avg.self"];
            CGFloat averageFloat = [average floatValue];
            response = (NSInteger) averageFloat;
        }
        
        delete query;
    }
    
    return response;
}
+ (NSInteger) getTodaysDistance
{
    NSTimeInterval todaySince1970 = [[iDevicesUtil todayDateAtMidnight] timeIntervalSince1970];
    return [iDevicesUtil getDistanceSinceDate: todaySince1970 toDate: todaySince1970];
}
+ (NSInteger) getStepsPercentage: (NSInteger) steps forRangeFrom: (NSTimeInterval) rangeStart to: (NSTimeInterval) rangeEnd
{
    NSString * key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM053_PropertyClass_Goals andIndex: appSettingsM053_PropertyClass_Goals_Steps];
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
    {
        key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372_PropertyClass_Goals andIndex: appSettingsM372_PropertyClass_Goals_Steps];
    }
    NSInteger settingStepsGoal = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    CGFloat percentage = 0.0;
    
    NSInteger numberOfDaysWithData = [iDevicesUtil getNumberOfActivityRecordsSinceDate: rangeStart toDate: rangeEnd];
    NSInteger goalForRange = numberOfDaysWithData != 0 ? numberOfDaysWithData * settingStepsGoal : settingStepsGoal;
    
    percentage = goalForRange != 0 ? (CGFloat) steps / (CGFloat) goalForRange : 100.0f;
    
    return (NSInteger)(percentage * 100.0f);
}
+ (NSInteger) getCaloriesPercentage: (NSInteger) calories forRangeFrom: (NSTimeInterval) rangeStart to: (NSTimeInterval) rangeEnd
{
    NSString * key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM053_PropertyClass_Goals andIndex: appSettingsM053_PropertyClass_Goals_Calories];
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
    {
        key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372_PropertyClass_Goals andIndex: appSettingsM372_PropertyClass_Goals_Calories];
    }
    NSInteger settingCaloriesGoal = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    CGFloat percentage = 0.0;
    
    NSInteger numberOfDaysWithData = [iDevicesUtil getNumberOfActivityRecordsSinceDate: rangeStart toDate: rangeEnd];
    NSInteger goalForRange = numberOfDaysWithData != 0 ? numberOfDaysWithData * settingCaloriesGoal : settingCaloriesGoal;
    
    percentage = goalForRange != 0 ? (CGFloat) calories / (CGFloat) goalForRange : 100.0f;
    
    return (NSInteger)(percentage * 100.0f);
}
+ (NSInteger) getDistancePercentage: (NSInteger) distance forRangeFrom: (NSTimeInterval) rangeStart to: (NSTimeInterval) rangeEnd
{
    NSString * key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM053_PropertyClass_Goals andIndex: appSettingsM053_PropertyClass_Goals_Distance];
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
    {
        key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372_PropertyClass_Goals andIndex: appSettingsM372_PropertyClass_Goals_Distance];
    }
    double settingDistancesGoal = [[NSUserDefaults standardUserDefaults] doubleForKey: key];
    CGFloat percentage = 0.0;
    
    NSInteger numberOfDaysWithData = [iDevicesUtil getNumberOfActivityRecordsSinceDate: rangeStart toDate: rangeEnd];
    NSInteger goalForRange = numberOfDaysWithData != 0 ? numberOfDaysWithData * settingDistancesGoal : settingDistancesGoal;
    
    percentage = goalForRange != 0 ? (CGFloat) distance / (CGFloat) goalForRange : 100.0f;
    
    return (NSInteger)(percentage * 100.0f);
}

+ (NSInteger) getNumberOfActivityRecordsSinceDate: (NSTimeInterval) since toDate: (NSTimeInterval) to
{
    NSInteger response = 0;
    NSString * expression = [NSString stringWithFormat: @"SELECT * FROM ActivityData WHERE WorkoutID IS NULL AND LapID IS NULL AND ActivityDate >= %f AND ActivityDate <= %f;", since, to];
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
    if (query)
    {
        response = query->getRowCount();
        
        delete query;
    }
    
    return response;
}

+ (BOOL) isOtherTimeSetToTimeZone
{
    BOOL returnValue = FALSE;
    
    NSString * keyTimeSetting = [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_ActivityTracker ? [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM053_PropertyClass_TimeOfDay andIndex: programWatchM053_PropertyClass_TimeOfDay_AwayTimeFollowPhone] : [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatch_PropertyClass_TimeOfDay andIndex: programWatch_PropertyClass_TimeOfDay_AwayTimeFollowPhone];
    NSInteger timeSetting = [[NSUserDefaults standardUserDefaults] integerForKey: keyTimeSetting];
    
    if (timeSetting == programWatch_PropertyClass_TimeOfDay_FollowPhoneTimeFollowTimeZone)
        returnValue = TRUE;
    
    return returnValue;
}

+ (BOOL) isAlarm1Enabled
{
    BOOL returnValue = FALSE;
    
    NSString * alarmSetting = [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_ActivityTracker ? [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM053_PropertyClass_Alarm andIndex: programWatchM053_PropertyClass_Alarm_A1_Status] : [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatch_PropertyClass_Alarm andIndex: programWatch_PropertyClass_Alarm_A1_Status];
    returnValue = [[NSUserDefaults standardUserDefaults] boolForKey: alarmSetting];
    
    return returnValue;
}
+ (BOOL) isAlarm2Enabled
{
    BOOL returnValue = FALSE;
    
    NSString * alarmSetting = [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_ActivityTracker ? [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM053_PropertyClass_Alarm andIndex: programWatchM053_PropertyClass_Alarm_A2_Status] : [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatch_PropertyClass_Alarm andIndex: programWatch_PropertyClass_Alarm_A2_Status];
    returnValue = [[NSUserDefaults standardUserDefaults] boolForKey: alarmSetting];
    
    return returnValue;
}
+ (BOOL) isAlarm3Enabled
{
    BOOL returnValue = FALSE;
    
    NSString * alarmSetting = [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_ActivityTracker ? [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM053_PropertyClass_Alarm andIndex: programWatchM053_PropertyClass_Alarm_A3_Status] : [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatch_PropertyClass_Alarm andIndex: programWatch_PropertyClass_Alarm_A3_Status];
    returnValue = [[NSUserDefaults standardUserDefaults] boolForKey: alarmSetting];
    
    return returnValue;
}
+ (BOOL) isInterval1Enabled
{
    BOOL returnValue = FALSE;
    
    NSString * alarmSetting = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatch_PropertyClass_IntervalTimer andIndex: programWatch_PropertyClass_IntervalTimer_IT1_OnOff];
    returnValue = [[NSUserDefaults standardUserDefaults] boolForKey: alarmSetting];
    
    return returnValue;
}
+ (BOOL) isInterval2Enabled
{
    BOOL returnValue = FALSE;
    
    NSString * alarmSetting = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatch_PropertyClass_IntervalTimer andIndex: programWatch_PropertyClass_IntervalTimer_IT2_OnOff];
    returnValue = [[NSUserDefaults standardUserDefaults] boolForKey: alarmSetting];
    
    return returnValue;
}

+ (BOOL) isNotificationsEnabled
{
    BOOL returnValue = FALSE;
    
    NSString * alarmSetting = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatch_PropertyClass_Notifications andIndex: programWatch_PropertyClass_Notifications_All];
    returnValue = [[NSUserDefaults standardUserDefaults] boolForKey: alarmSetting];
    
    return returnValue;
}

+ (BOOL) isDNDEnabled
{
    BOOL returnValue = FALSE;
    
    NSString * alarmSetting = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatch_PropertyClass_DoNotDisturb andIndex: programWatch_PropertyClass_DND_DNDStatus];
    returnValue = [[NSUserDefaults standardUserDefaults] boolForKey: alarmSetting];
    
    return returnValue;
}

+ (void) generateDummyActivityData: (NSInteger) howManyDays
{
    //set goals:
    NSString * key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM053_PropertyClass_Goals andIndex: appSettingsM053_PropertyClass_Goals_Steps];
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
    {
        key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372_PropertyClass_Goals andIndex: appSettingsM053_PropertyClass_Goals_Steps];
    }
    [[NSUserDefaults standardUserDefaults] setInteger: 6000 forKey: key];
    
    key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM053_PropertyClass_Goals andIndex: appSettingsM053_PropertyClass_Goals_Calories];
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
    {
        key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372_PropertyClass_Goals andIndex: appSettingsM372_PropertyClass_Goals_Calories];
    }
    [[NSUserDefaults standardUserDefaults] setInteger: 3000 forKey: key];
    
    key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM053_PropertyClass_Goals andIndex: appSettingsM053_PropertyClass_Goals_Distance];
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
    {
        key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372_PropertyClass_Goals andIndex: appSettingsM053_PropertyClass_Goals_Distance];
    }
    [[NSUserDefaults standardUserDefaults] setInteger: 9990 forKey: key];
    
    ///////
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
    {
        key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372_PropertyClass_Goals andIndex: appSettingsM372_PropertyClass_Goals_Sleep];
        
        [[NSUserDefaults standardUserDefaults] setInteger: 80 forKey: key];
    }
    ///////
    
    for (int i = 0; i < howManyDays; i++)
    {
        NSTimeInterval rollBack = -1 * 86400 * i;
        NSDate * dateOfActivity = [NSDate dateWithTimeIntervalSinceNow: rollBack];
        
        NSCalendar *gregorian = [NSCalendar currentCalendar];
        NSDateComponents *comps = [gregorian components: NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate: dateOfActivity];
        [comps setHour: 0];
        [comps setMinute: 0];
        [comps setSecond: 0];
        
        dateOfActivity = [gregorian dateFromComponents: comps];
        
        NSTimeInterval since1970 = [dateOfActivity timeIntervalSince1970];
        NSInteger totalSteps = arc4random() % 6000;
        NSInteger totalCalories = arc4random() % 3000;
        NSInteger totalDistance = arc4random() % 9990;
        NSString * expressionNewActivity = [NSString stringWithFormat: @"INSERT INTO ActivityData ('ActivityDate', 'ActivitySteps', 'ActivityDistance', 'ActivityCalories', 'WorkoutID', 'LapID') VALUES (%f, %ld,'%ld', %ld, NULL, NULL);", since1970, (long)totalSteps, (long)totalDistance, (long)totalCalories];
        
        TimexDatalink::IDBQuery * queryNewActivity = [[TimexWatchDB sharedInstance] createQuery : expressionNewActivity];
        if (queryNewActivity)
        {
            delete queryNewActivity;
        }
    }
}

+ (void) generateDummyWorkouts: (NSInteger) howMany spanInDays: (NSInteger) howManyDays maximumNumberOfLaps: (NSInteger) lapsNumber
{
    for (int i = 0; i < howMany; i++)
    {
        TDWorkoutData * newData = [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_ActivityTracker ? [[TDWorkoutDataActivityTracker alloc] init] : [[TDWorkoutData alloc] init];
        int dateIntervalRandom = arc4random() % howManyDays;
        double secondsPerDay = 86400;
        double randomDateInPastYear = secondsPerDay * dateIntervalRandom * -1;
        NSDate * newDate = [NSDate dateWithTimeIntervalSinceNow: randomDateInPastYear];
        
        [newData setWorkoutDate: newDate];
        
        NSInteger totalSteps = 0;
        NSInteger totalDistance = 0;
        NSInteger totalCalories = 0;
        
        if (i % 2 == 0)
        {
            [newData setWorkoutType: TDWorkoutData_WorkoutTypeChrono];
            
            int numberOfLapsRandom = (arc4random() % lapsNumber) + 1; //1-based, not zero-based
            
            [newData setRecordedNumberOfLaps: numberOfLapsRandom];
            [newData setNumberOfScheduledRepeats: 0];
            
            for (int j = 0; j < numberOfLapsRandom; j++)
            {
                int numberOfMinutesRandom = arc4random() % 60;
                int numberOfSecondsRandom = arc4random() % 60;
                int numberOfHudredthOfSecondRandom = (arc4random() % 100) + 1; //1-based... the lap has to last at least a few hundredth of a second ;)
                
                NSNumber * lapTime =  [[NSNumber alloc] initWithDouble: (numberOfMinutesRandom * 60 * 1000) + (numberOfSecondsRandom * 1000) + (numberOfHudredthOfSecondRandom * 10)];
                
                if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_ActivityTracker)
                {
                    NSInteger steps = arc4random() % 1000;
                    NSInteger calories = steps;
                    NSInteger distance = steps / 2;
                    totalSteps += steps;
                    totalDistance += distance;
                    totalCalories += calories;
                    
                    [(TDWorkoutDataActivityTracker *)newData addLapData: lapTime withType: programWatch_PropertyClass_IntervalTimer_LabelRun withSteps: steps andDistance: calories andCalories: distance];
                }
                else
                {
                    [newData addLapData: lapTime withType: programWatch_PropertyClass_IntervalTimer_LabelRun];
                }
            }
        }
        else
        {
            [newData setWorkoutType: TDWorkoutData_WorkoutTypeTimer];
            
            int numberOfLapsRandom = (arc4random() % lapsNumber) + 1; //1-based, not zero-based
            if (numberOfLapsRandom % 2 == 1)
                numberOfLapsRandom++;
            
            [newData setRecordedNumberOfLaps: 0];
            [newData setNumberOfScheduledRepeats: numberOfLapsRandom/2];
            
            int numberOfMinutesRandom1 = arc4random() % 60;
            int numberOfSecondsRandom1 = arc4random() % 60;
            int numberOfHudredthOfSecondRandom1 = (arc4random() % 100) + 1; //1-based... the lap has to last at least a few hundredth of a second ;)
            
            int numberOfMinutesRandom2 = arc4random() % 60;
            int numberOfSecondsRandom2 = arc4random() % 60;
            int numberOfHudredthOfSecondRandom2 = (arc4random() % 100) + 1; //1-based... the lap has to last at least a few hundredth of a second ;)
            
            programWatch_PropertyClass_IntervalTimer_LabelEnum type1 = (programWatch_PropertyClass_IntervalTimer_LabelEnum)(arc4random() % programWatch_PropertyClass_IntervalTimer_LabelLAST);
            programWatch_PropertyClass_IntervalTimer_LabelEnum type2 = (programWatch_PropertyClass_IntervalTimer_LabelEnum)(arc4random() % programWatch_PropertyClass_IntervalTimer_LabelLAST);
            
            for (int j = 0; j < numberOfLapsRandom; j++)
            {
                NSNumber * lapTime = (j % 2 == 0) ? [[NSNumber alloc] initWithDouble: (numberOfMinutesRandom1 * 60 * 1000) + (numberOfSecondsRandom1 * 1000) + (numberOfHudredthOfSecondRandom1 * 10)] : [[NSNumber alloc] initWithDouble: (numberOfMinutesRandom2 * 60 * 1000) + (numberOfSecondsRandom2 * 1000) + (numberOfHudredthOfSecondRandom2 * 10)];
                
                if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_ActivityTracker)
                {
                    NSInteger steps = arc4random() % 1000;
                    NSInteger calories = steps;
                    NSInteger distance = steps / 2;
                    totalSteps += steps;
                    totalDistance += distance;
                    totalCalories += calories;
                    
                    [(TDWorkoutDataActivityTracker *)newData addLapData: lapTime withType: programWatch_PropertyClass_IntervalTimer_LabelRun withSteps: steps andDistance: calories andCalories: distance];
                }
                else
                {
                    [newData addLapData: lapTime withType: (j % 2 == 0) ? type1 : type2];
                }
            }
        }
        
        NSNumber * totalTime = [newData getWorkoutDurationThroughData];
        [newData setWorkoutDuration: totalTime];
        
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_ActivityTracker)
        {
            [(TDWorkoutDataActivityTracker *)newData setTotalSteps: totalSteps];
            [(TDWorkoutDataActivityTracker *)newData setTotalDistance: totalDistance];
            [(TDWorkoutDataActivityTracker *)newData setTotalCalories: totalCalories];
        }
        
        [[[TDWatchProfile sharedInstance] workoutManager] addWorkout: newData resortWorkouts: FALSE]; //will be resorted at the end, for speed
    }
    
    [[[TDWatchProfile sharedInstance] workoutManager] resortWorkoutsByCurrentSortType];
}

+ (NSData *) longToByteArray: (long) i
{
    Byte result[8];
    
    result[0] = (Byte) (i >> 56);
    result[1] = (Byte) (i >> 48);
    result[2] = (Byte) (i >> 40);
    result[3] = (Byte) (i >> 32);
    result[4] = (Byte) (i >> 24);
    result[5] = (Byte) (i >> 16);
    result[6] = (Byte) (i >> 8);
    result[7] = (Byte) (i /*>> 0*/);
    
    return [NSData dataWithBytes: result length: 8];
}

+ (NSData *) intToByteArray: (int) i
{
    Byte result[4];
    
    result[0] = (Byte) (i >> 24);
    result[1] = (Byte) (i >> 16);
    result[2] = (Byte) (i >> 8);
    result[3] = (Byte) (i /*>> 0*/);
    
    return [NSData dataWithBytes: result length: 4];
}


 + (int) calculateTimexCRC32: (Byte *) inBytes withLength: (int) inLen
 {
     const int crcTable[] =  // Nibble lookup table for 0x04C11DB7 polynomial
     {
     0x00000000,0x04C11DB7,0x09823B6E,0x0D4326D9,0x130476DC,0x17C56B6B,0x1A864DB2,0x1E475005,
     0x2608EDB8,0x22C9F00F,0x2F8AD6D6,0x2B4BCB61,0x350C9B64,0x31CD86D3,0x3C8EA00A,0x384FBDBD
     };
     int crc = 0xFFFFFFFF;
     int len = inLen / 4;
     int * currentIntPtr = (int *)inBytes;
     
     while ( len-- != 0 )
     {
         int value = *currentIntPtr;
         crc = crc ^ value; // Apply all 32-bits
         currentIntPtr += 1;
         // Process 32-bits, 4 at a time, or 8 rounds
         crc = (crc << 4) ^ crcTable[ (int)(crc >> 28) & 0x0F ];
         crc = (crc << 4) ^ crcTable[ (int)(crc >> 28) & 0x0F ];
         crc = (crc << 4) ^ crcTable[ (int)(crc >> 28) & 0x0F ];
         crc = (crc << 4) ^ crcTable[ (int)(crc >> 28) & 0x0F ];
         crc = (crc << 4) ^ crcTable[ (int)(crc >> 28) & 0x0F ];
         crc = (crc << 4) ^ crcTable[ (int)(crc >> 28) & 0x0F ];
         crc = (crc << 4) ^ crcTable[ (int)(crc >> 28) & 0x0F ];
         crc = (crc << 4) ^ crcTable[ (int)(crc >> 28) & 0x0F ];
     }
     
     int lCRC = CFSwapInt32(crc);
     
     return lCRC;
 }

 + (int) calculateTimexM053Checksum: (Byte *) inBytes withLength: (int) inLen
{
    int checksum = 0;
    Byte temp;
    for (int count = 0; count < inLen; count++)
    {
        temp = (Byte)(inBytes[count] & 0xFF);
        // Add the data bytes to the checksum
        checksum += temp;
    }
    
    // Calculate final checksum value
    checksum = ((~checksum) + 1);
    
    return checksum;
}

+ (UInt32) calculateChecksum: (Byte *) bytes withLength: (int) length {
    UInt32 checksum = 0;
    UInt8 temp = 0;
    for (int index = 0; index < length; index ++) {
        temp = bytes[index];//UInt8(bytes[index] & 0xFF)
        checksum += UInt32(temp);
    }
    checksum = (~(checksum)+1);
    return checksum;
}

+ (NSData *) shortToByteArray: (short) i
{
    Byte result[2];
    
    result[0] = (Byte) (i >> 8);
    result[1] = (Byte) (i);
    
    return [NSData dataWithBytes: result length: 2];
}

+ (short) byteArrayToShort: (Byte *) b
{
    return  (b[0] & 0xFF) |
    (b[1] & 0xFF) << 8;
}

+ (int) byteArrayToInt: (Byte *) b
{
    return  (b[0] & 0xFF) |
    (b[1] & 0xFF) << 8 |
    (b[2] & 0xFF) << 16 |
    (b[3] & 0xFF) << 24;
}

+ (int) byteArrayToIntRevesre: (Byte *) b
{
    return  (b[3] & 0xFF) |
    (b[2] & 0xFF) << 8 |
    (b[1] & 0xFF) << 16 |
    (b[0] & 0xFF) << 24;
}

+ (long) byteArrayToLong: (Byte *) b
{
    return  (b[0] & 0xFFL) |
    (b[1] & 0xFFL) << 8 |
    (b[2] & 0xFFL) << 16 |
    (b[3] & 0xFFL) << 24 |
    (b[4] & 0xFFL) << 32 |
    (b[5] & 0xFFL) << 40 |
    (b[6] & 0xFFL) << 48 |
    (b[7] & 0xFFL) << 56;
}

+(void) dumpData:(NSData *)data
{
    unsigned char* bytes = (unsigned char*) [data bytes];
    OTLog(@"===================");
    for(int i = 0; i < [data length]; i++)
    {
        NSString * op = [NSString stringWithFormat:@"%d: %X",i , bytes[i], nil];
        OTLog([NSString stringWithFormat:@"Data: %@", op]);
    }
    OTLog(@"%d",[data length]);
    OTLog(@"%d",bytes);
    OTLog(@"===================");
}

+ (BOOL) IsValidEmail:(NSString *)checkString
{
    BOOL stricterFilter = YES; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSString *laxString = @".+@([A-Za-z0-9]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}

/*
 Connectivity testing code pulled from Apple's Reachability Example: http://developer.apple.com/library/ios/#samplecode/Reachability
 */
+(BOOL) hasInternetConnectivity
{
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);
    if(reachability != NULL)
    {
        //NetworkStatus retVal = NotReachable;
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(reachability, &flags))
        {
            if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
            {
                // if target host is not reachable
                return NO;
            }
            
            if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
            {
                // if target host is reachable and no connection is required
                //  then we'll assume (for now) that your on Wi-Fi
                return YES;
            }
            
            
            if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
            {
                // ... and the connection is on-demand (or on-traffic) if the
                //     calling application is using the CFSocketStream or higher APIs
                
                if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
                {
                    // ... and no [user] intervention is needed
                    return YES;
                }
            }
            
            if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
            {
                // ... but WWAN connections are OK if the calling application
                //     is using the CFNetwork (CFSocketStream?) APIs.
                return YES;
            }
        }
    }
    
    return NO;
}

+ (BOOL) isSystemTimeFormat24Hr {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateStyle:NSDateFormatterNoStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *dateString = [formatter stringFromDate:[NSDate date]];
    NSRange amRange = [dateString rangeOfString:[formatter AMSymbol]];
    NSRange pmRange = [dateString rangeOfString:[formatter PMSymbol]];
    BOOL is24h = (amRange.location == NSNotFound && pmRange.location == NSNotFound);
    return is24h;
}
+(BOOL) isCurrentTimeFormat24HR
{
    BOOL is24HR = FALSE;
    
    NSString * timeFormatSettingKey = nil;
    
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_ActivityTracker)
    {
        timeFormatSettingKey = [self createKeyForWatchControlPropertyWithClass: programWatchM053_PropertyClass_TimeOfDay andIndex: programWatchM053_PropertyClass_TimeOfDay_HomeTimeTimeFormat];
    }
    else if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
    {
        is24HR = FALSE;
    }
    else if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_M054)
    {
        timeFormatSettingKey = [self createKeyForWatchControlPropertyWithClass: programWatch_PropertyClass_TimeOfDay andIndex: programWatch_PropertyClass_TimeOfDay_HomeTimeTimeFormat];
    }
    
    NSInteger timeFormatSetting = [[NSUserDefaults standardUserDefaults] integerForKey: timeFormatSettingKey];
    
    if (programWatch_PropertyClass_TimeOfDay_TZTimeFormat24HR == timeFormatSetting)
    {
        is24HR = TRUE;
    }
    
    return is24HR;
}

+ (BOOL) isActivityTrackerUnitsOfMeasureImperial
{
    BOOL isImperial = FALSE;
    
    NSString * unitsKey = nil;
    
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_ActivityTracker || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ)
    {
        unitsKey = [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_ActivityTracker ? [self createKeyForWatchControlPropertyWithClass: programWatchM053_PropertyClass_General andIndex: programWatchM053_PropertyClass_General_UnitOfMeasure] : [self createKeyForWatchControlPropertyWithClass: programWatchM372_PropertyClass_General andIndex: programWatchM372_PropertyClass_General_UnitOfMeasure];
    
        if ([[NSUserDefaults standardUserDefaults] objectForKey: unitsKey] != nil) {
            NSInteger unitsSetting = [[NSUserDefaults standardUserDefaults] integerForKey: unitsKey];
            if (programWatchActivityTracker_PropertyClass_General_Units_Imperial == unitsSetting) {
                isImperial = TRUE;
            }
        } else {
            // Setting the units by default. These have to be set based on locale.
            NSLocale *locale = [NSLocale currentLocale];
            BOOL isMetric = [[locale objectForKey:NSLocaleUsesMetricSystem] boolValue];
            
            if (isMetric == YES){
                [[NSUserDefaults standardUserDefaults] setInteger: programWatchActivityTracker_PropertyClass_General_Units_Metric forKey: unitsKey];
                isImperial = FALSE;
            }
            else{
                [[NSUserDefaults standardUserDefaults] setInteger: programWatchActivityTracker_PropertyClass_General_Units_Imperial forKey: unitsKey];
                isImperial = TRUE;
                
            }
            
        }
    }
    
    return isImperial;
}



//Base on the following from M049/M053 Classic 50 Move+ documentation

/*
Unit Conversion Factors
The watch uses both metric and imperial unit systems. To convert one unit to the other, the following factors must
be used.
1 meter = 39.370 inches
1 kilometre = 0.621 miles
1 kilogram = 2.205 pounds
*/

+ (float) convertCentimetersToInches: (float) centimeters
{
    return centimeters * 0.39370;
}
+ (float) convertInchesToCentimeters: (float) inches
{
    return roundf(inches * 2.54);
}
+ (float) convertKilogramsToPounds: (float) kilos
{
    return kilos * 2.2046;
}
+ (float) convertPoundsToKilograms: (float) pounds
{
    return roundf(pounds * 4.5351473922902f)/10;
}
+ (double) convertKilometersToMiles: (double) kilos
{
    return kilos / 1.6093442;
}
+ (double) convertMilesToKilometers: (double) miles
{
    return miles * 1.609344;
}


+ (NSString *) getPlatform
{
    NSString * platformStr = nil;
    
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char * machine = (char *)malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    platformStr = [NSString stringWithUTF8String:machine];
    free(machine);

    return platformStr;
}

+ (void) logFlurryEvent:(NSString *)event withParameters:(NSDictionary*)params isTimedEvent: (BOOL) isTimed
{
    if (!params)
    {
        params = [NSDictionary dictionary];
    }
    NSMutableDictionary* newParams = [params mutableCopy];
    
    UIDevice* device = [UIDevice currentDevice];
    
    [newParams setValue: [iDevicesUtil getPlatform] forKey:@"hardware"];
    
    [newParams setValue:[NSString stringWithFormat:@"%@ %@", device.systemName, device.systemVersion] forKey:@"os"];
    
    if( newParams.count > 10 )
    {
        OTLog(@"Attempting to log Flurry Event %@ with more than 10 parameters!", event);
    }
    
    [Flurry logEvent:event withParameters:newParams timed:isTimed];
}

+ (void) endTimedFlurryEvent:(NSString *)event withParameters:(NSDictionary*)params
{
    if (!params)
    {
        params = [NSDictionary dictionary];
    }
    NSMutableDictionary* newParams = [params mutableCopy];
    
    UIDevice* device = [UIDevice currentDevice];
    
    [newParams setValue: [iDevicesUtil getPlatform] forKey:@"hardware"];
    
    [newParams setValue:[NSString stringWithFormat:@"%@ %@", device.systemName, device.systemVersion] forKey:@"os"];
    
    [Flurry endTimedEvent:event withParameters:newParams];
    
}

+ (TDRootViewController *) launchAppWebViewerWithURL: (NSURL *) url forViewController: (UIViewController *) vc isEula:(BOOL)eula
{
    TDWebViewer * webView = [[TDWebViewer alloc] initWithNibName: @"TDWebViewer" bundle: nil andURLtoVisit: url scaleToFitFlag: TRUE fromVC:vc isEula:eula];
//    [webView setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
//    [webView setModalPresentationStyle:UIModalPresentationFormSheet];
    
    if (vc != nil)
    {
        [[vc navigationController] pushViewController: webView animated: YES];
    }
    
    return webView;
}

+(NSDateFormatter *) getDateFormatter: (BOOL) twoLines
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [formatter setLocale: enUSPOSIXLocale];
    
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_ActivityTracker)
    {
        NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM053_PropertyClass_TimeOfDay andIndex: programWatchM053_PropertyClass_TimeOfDay_HomeTimeDateFormat];
        if ([[NSUserDefaults standardUserDefaults] objectForKey: key] != nil)
        {
            NSInteger setting = [[NSUserDefaults standardUserDefaults] integerForKey: key];
            NSString * keyTime = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM053_PropertyClass_TimeOfDay andIndex: programWatchM053_PropertyClass_TimeOfDay_HomeTimeTimeFormat];
            if ([[NSUserDefaults standardUserDefaults] objectForKey: keyTime] != nil)
            {
                NSInteger settingTime = [[NSUserDefaults standardUserDefaults] integerForKey: keyTime];
                if (settingTime == programWatch_PropertyClass_TimeOfDay_TZTimeFormat12HR)
                {
                    if (setting == programWatchM053_PropertyClass_TimeOfDay_TZDateFormatMMDD)
                        [formatter setDateFormat: twoLines ? @"M/dd/yy\nh:mm a" : @"M/dd/yy h:mm a"];
                    else if (setting == programWatchM053_PropertyClass_TimeOfDay_TZDateFormatDDMM)
                        [formatter setDateFormat: twoLines ? @"dd.M.yy\nh:mm a" : @"dd.M.yy h:mm a"];
                }
                else
                {
                    if (setting == programWatchM053_PropertyClass_TimeOfDay_TZDateFormatMMDD)
                        [formatter setDateFormat: twoLines ? @"M/dd/yy\nH:mm" : @"M/dd/yy H:mm"];
                    else if (setting == programWatchM053_PropertyClass_TimeOfDay_TZDateFormatDDMM)
                        [formatter setDateFormat: twoLines ? @"dd.M.yy\nH:mm" : @"dd.M.yy H:mm"];
                }
            }
            else
            {
                if (setting == programWatchM053_PropertyClass_TimeOfDay_TZDateFormatMMDD)
                    [formatter setDateFormat: twoLines ? @"M/dd/yy\nh:mm a" : @"M/dd/yy h:mm a"];
                else if (setting == programWatchM053_PropertyClass_TimeOfDay_TZDateFormatDDMM)
                    [formatter setDateFormat: twoLines ? @"dd.M.yy\nh:mm a" : @"dd.M.yy h:mm a"];
            }
        }
        else
            [formatter setDateFormat:  twoLines ? @"M/dd/yy\nh:mm a" : @"M/dd/yy h:mm a"];
    }
    else if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_M054)
    {
        NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatch_PropertyClass_TimeOfDay andIndex: programWatch_PropertyClass_TimeOfDay_HomeTimeDateFormat];
        if ([[NSUserDefaults standardUserDefaults] objectForKey: key] != nil)
        {
            NSInteger setting = [[NSUserDefaults standardUserDefaults] integerForKey: key];
            NSString * keyTime = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatch_PropertyClass_TimeOfDay andIndex: programWatch_PropertyClass_TimeOfDay_HomeTimeTimeFormat];
            if ([[NSUserDefaults standardUserDefaults] objectForKey: keyTime] != nil)
            {
                NSInteger settingTime = [[NSUserDefaults standardUserDefaults] integerForKey: keyTime];
                if (settingTime == programWatch_PropertyClass_TimeOfDay_TZTimeFormat12HR)
                {
                    if (setting == programWatch_PropertyClass_TimeOfDay_TZDateFormatMMMDD)
                        [formatter setDateFormat: twoLines ? @"MMM dd\nh:mm a" : @"MMM dd h:mm a"];
                    else if (setting == programWatch_PropertyClass_TimeOfDay_TZDateFormatMMDDYY)
                        [formatter setDateFormat: twoLines ? @"M/dd/yy\nh:mm a" : @"M/dd/yy h:mm a"];
                    else if (setting == programWatch_PropertyClass_TimeOfDay_TZDateFormatDDMMYY)
                        [formatter setDateFormat: twoLines ? @"dd.M.yy\nh:mm a" : @"dd.M.yy h:mm a"];
                    else if (setting == programWatch_PropertyClass_TimeOfDay_TZDateFormatYYYYMMDD)
                        [formatter setDateFormat: twoLines ? @"yyyy-M-dd\nh:mm a" : @"yyyy-M-dd h:mm a"];
                }
                else
                {
                    if (setting == programWatch_PropertyClass_TimeOfDay_TZDateFormatMMMDD)
                        [formatter setDateFormat: twoLines ? @"MMM dd\nH:mm" : @"MMM dd H:mm"];
                    else if (setting == programWatch_PropertyClass_TimeOfDay_TZDateFormatMMDDYY)
                        [formatter setDateFormat: twoLines ? @"M/dd/yy\nH:mm" : @"M/dd/yy H:mm"];
                    else if (setting == programWatch_PropertyClass_TimeOfDay_TZDateFormatDDMMYY)
                        [formatter setDateFormat: twoLines ? @"dd.M.yy\nH:mm" : @"dd.M.yy H:mm"];
                    else if (setting == programWatch_PropertyClass_TimeOfDay_TZDateFormatYYYYMMDD)
                        [formatter setDateFormat: twoLines ? @"yyyy-M-dd\nH:mm" : @"yyyy-M-dd H:mm"];
                }
            }
            else
            {
                if (setting == programWatch_PropertyClass_TimeOfDay_TZDateFormatMMMDD)
                    [formatter setDateFormat: twoLines ? @"MMM dd\nh:mm a" : @"MMM dd h:mm a"];
                else if (setting == programWatch_PropertyClass_TimeOfDay_TZDateFormatMMDDYY)
                    [formatter setDateFormat: twoLines ? @"M/dd/yy\nh:mm a" : @"M/dd/yy h:mm a"];
                else if (setting == programWatch_PropertyClass_TimeOfDay_TZDateFormatDDMMYY)
                    [formatter setDateFormat: twoLines ? @"dd.M.yy\nh:mm a" : @"dd.M.yy h:mm a"];
                else if (setting == programWatch_PropertyClass_TimeOfDay_TZDateFormatYYYYMMDD)
                    [formatter setDateFormat: twoLines ? @"yyyy-M-dd\nh:mm a" : @"yyyy-M-dd h:mm a"];
            }
        }
        else
            [formatter setDateFormat:  twoLines ? @"M/dd/yy\nh:mm a" : @"M/dd/yy h:mm a"];
    }
    
    return formatter;
}

+ (UIColor *) getM053ActivityColorBasedOnPercentage: (NSInteger) percentage
{
    UIColor * color = nil;
    
    if (percentage <= 33)
        color = UIColorFromRGB(ACTIVITY_TRACKER_COLOR_RED);
    else if (percentage <= 66)
        color = UIColorFromRGB(ACTIVITY_TRACKER_COLOR_ORANGE);
    else if (percentage <= 99)
        color = UIColorFromRGB(ACTIVITY_TRACKER_COLOR_YELLOW);
    else
        color = UIColorFromRGB(ACTIVITY_TRACKER_COLOR_GREEN);
    
    return color;
}

+ (NSString *) getDefaultSocialMediaPostingString: (TDWorkoutData *) workoutToShare
{
    NSString *stringFromDate = [[[workoutToShare getDefaultWorkoutName_Formatted] componentsSeparatedByString: @"\n"] objectAtIndex: 0];
    NSString *intervalString = [iDevicesUtil stringFromTimeInterval: [[workoutToShare getSplitTimeForIndex: [workoutToShare getNumberOfLaps] - 1] doubleValue]];
    NSString * stringToPost = [NSString stringWithFormat: NSLocalizedString(@"On %@ I ran %d laps with a time of %@ with the help of my Timex Watch!", nil), stringFromDate, [workoutToShare getNumberOfLaps], intervalString];
    
    return stringToPost;
}

+ (UIImage *)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0, 0, 1, 1);
    
    // Create a 1 by 1 pixel context
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);   // Fill it with your color
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIColor *) getTimexRedColor
{
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan && [iDevicesUtil checkForActiveProfilePresence])
    {
        return UIColorFromRGB(COLOR_DEFAULT_TIMEX_ACCENT);
    }
    else
    {
        return UIColorFromRGB(COLOR_DEFAULT_TIMEX_ACCENT);
    }
}
+ (NSString *)getSettingType:(enum SettingType)type {
    switch (type) {
        case 1:
            return @"Name";
            break;
        case 2:
            return @"Gender";
            break;
        case 3:
            return @"Birthday";
            break;
        case 4:
            return @"Height";
            break;
        case 5:
            return @"Weight";
            break;
        case 6:
            return @"Units";
            break;
        case 7:
            return @"Goals";
            break;
        case 8:
            return @"Sensor sensitivity";
            break;
        case 9:
            return @"Distance adjustment";
            break;
        case 10:
            return @"Bed time";
            break;
        case 11:
            return @"Wake Time";
            break;
        case 12:
            return @"Track sleep";
            break;
        case 13:
            return @"Auto sync time";
            break;
        default:
            break;
    }
    return nil;
}

+ (NSString *)getGenderInStringFormat:(enum General_Gender)gender {
    switch (gender) {
        case General_Gender_Female:
            return @"Female";
            break;
        case General_Gender_Male:
            return @"Male";
            break;
        default:
            break;
    }
}

+ (NSString *)getUnitsInStringFormat:(enum General_Units)units {
    switch (units) {
        case General_Units_Imperial:
            return @"Imperial";
            break;
        case General_Units_Metric:
            return @"Metric";
            break;
        default:
            break;
    }
}

+ (NSString *)getSensorSensitivityStringFormat:(enum SensorType)goalType {
    switch (goalType) {
        case Low:
            return @"Low";
            break;
        case Medium:
            return @"Medium";
            break;
        case High:
            return @"High";
            break;
        default:
            break;
    }
}

// Given an epoch string returns an array of three variables.
// 1. Deep sleep
// 2. Light sleep
// 3. Awake
+(NSArray *)convertEpochStringToSegments:(NSString*)epochString{
//    NSMutableArray *returnArray = [[NSMutableArray alloc]initWithCapacity:3];
    NSString *lightSleep = [NSString stringWithFormat:@"%.2f", [[epochString componentsSeparatedByString:@"B"]count]*2/60.0];
    NSString *deepSleep = [NSString stringWithFormat:@"%.2f", [[epochString componentsSeparatedByString:@"A"]count]*2/60.0];
    NSString *awake = [NSString stringWithFormat:@"%.2f", [[epochString componentsSeparatedByString:@"C"]count]*2/60.0];
    
    return @[deepSleep,lightSleep,awake];// [NSArray arrayWithArray:returnArray];
}


+ (NSString *)convertInchToFeet:(float)inch {
    
    float inches = roundf(inch);
    NSInteger inchesRemainder = (NSInteger)inches % 12;
    NSInteger whole = (NSInteger)inches - inchesRemainder;
    NSInteger feet = whole / 12;
    //    NSString *value = [NSString stringWithFormat: @"%ld'%ld\"", (long)feet, (long)inchesRemainder];
    
    NSMutableString *ftStr = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"%ld ft",(long)feet]];
    
    if (inchesRemainder > 0) {
        [ftStr appendString:[NSString stringWithFormat:@" %ld in",(long)inchesRemainder]];
    }
    return ftStr;
}

+ (NSString *)convertCMToMeters:(NSInteger)cms {
    
    NSInteger meters = (NSInteger)cms / 100;
    NSInteger cm = cms - (meters * 100);
    
    NSMutableString *ftStr = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"%ld m",(long)meters]];
    
    if (cm > 0) {
        [ftStr appendString:[NSString stringWithFormat:@" %ld cm",(long)cm]];
    }
    return ftStr;
}

+ (NSDate *) onlyDateFormat:(NSDate *)date {
    NSDate* result = nil;
    
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    NSDateComponents *comps = [gregorian components: NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate: date];
    [comps setHour: 0];
    [comps setMinute: 0];
    [comps setSecond: 0];
    
    result = [gregorian dateFromComponents: comps];
    return result;
}

+ (NSString *)convertMinutesToStringHHMMFormat:(NSTimeInterval)totalTimeIntr {
    NSInteger minutes = (int)totalTimeIntr % 60;
    NSInteger hours = (int)totalTimeIntr / 60;
    
    if (hours > 9) {
        return [NSString stringWithFormat:@"%.2ld:%.2ld", (long)hours, (long)minutes];
    } else {
        return [NSString stringWithFormat:@"%.1ld:%.2ld", (long)hours, (long)minutes];
    }
}

+ (NSString *)convertMinutesToStringHHDecimalFormat:(NSTimeInterval)totalTimeIntr
{
    return [NSString stringWithFormat:@"%.02f", totalTimeIntr/60];
}

+ (NSTimeInterval)getTimeIntervalInDateFormatOnly:(NSDate *)date {
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    NSDateComponents *comps = [gregorian components: NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate: date];
    [comps setHour: 0];
    [comps setMinute: 0];
    [comps setSecond: 0];
    
    date = [gregorian dateFromComponents: comps];
    
    NSTimeInterval since1970 = [date timeIntervalSince1970];
    return since1970;
}
+(int)getCurrentLocaleUnitSystem {
    BOOL isMetric = [[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue];
    if (isMetric) {
        return General_Units_Metric;
        //Distance : KM, Height : Centimeters/meters, Weight:Kg
    } else {
        return General_Units_Imperial;
        //Distance : Miles, Height : Inches, Weight:lbs
    }
}

+ (NSDate *) getDateAtFirstMinute:(NSDate *)dateselected
{
    NSDate* result = nil;
    
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    NSDateComponents *comps = [gregorian components: NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate: dateselected];
    [comps setHour: 0];
    [comps setMinute: 0];
    [comps setSecond: 0];
    
    result = [gregorian dateFromComponents: comps];
    return result;
}
+ (NSDate *) getDateAtLastMinute:(NSDate *)dateselected
{
    NSDate* result = nil;
    
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    NSDateComponents *comps = [gregorian components: NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate: dateselected];
    [comps setHour: 23];
    [comps setMinute: 59];
    [comps setSecond: 59];
    
    result = [gregorian dateFromComponents: comps];
    return result;
}
+ (BOOL)isMetricSystem {
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel) {
        if ([TDM328WatchSettingsUserDefaults units] == 1 || [TDM328WatchSettingsUserDefaults units] == 0) {
            return ([TDM328WatchSettingsUserDefaults units] == M328_METRIC)?YES:NO;
        } else {
            NSLocale *locale = [NSLocale currentLocale];
            BOOL isMetric = [[locale objectForKey:NSLocaleUsesMetricSystem] boolValue];
            return isMetric;
        }
    } else {
        return ![iDevicesUtil isActivityTrackerUnitsOfMeasureImperial];
    }
}

+(NSDate *)getPreviousDate:(NSDate *)date
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.day = -1;
    components.hour = 0;
    components.minute = 0;
    components.second = 0;
    NSDate *newDate = [calendar dateByAddingComponents:components toDate:date options:0];
    return newDate;
}
+ (void)displayEULADetailsFromViewController:(UIViewController *)vc {
    [vc.navigationController setNavigationBarHidden:NO animated:YES];
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex: 0];
    NSString * languageSubstring = [[language substringToIndex: 2] lowercaseString];
    if ([languageSubstring isEqualToString:@"fr"]) { // French
        [iDevicesUtil launchAppWebViewerWithURL: [NSURL URLWithString:TIMEX_EULA_URL_FR] forViewController: vc isEula:YES];
    } else if ([languageSubstring isEqualToString:@"es"]) { // Spanish
        [iDevicesUtil launchAppWebViewerWithURL: [NSURL URLWithString:TIMEX_EULA_URL_SP] forViewController: vc isEula:YES];
    } else if ([languageSubstring isEqualToString:@"pt"]) { // Portuguese
        [iDevicesUtil launchAppWebViewerWithURL: [NSURL URLWithString:TIMEX_EULA_URL_PO] forViewController: vc isEula:YES];
    } else if ([languageSubstring isEqualToString:@"it"]) { // Italian
        [iDevicesUtil launchAppWebViewerWithURL: [NSURL URLWithString:TIMEX_EULA_URL_IT] forViewController: vc isEula:YES];
    } else if ([languageSubstring isEqualToString:@"nl"]) { // Dutch
        [iDevicesUtil launchAppWebViewerWithURL: [NSURL URLWithString:TIMEX_EULA_URL_DU] forViewController: vc isEula:YES];
    } else if ([languageSubstring isEqualToString:@"de"]) { // German
        [iDevicesUtil launchAppWebViewerWithURL: [NSURL URLWithString:TIMEX_EULA_URL_GE] forViewController: vc isEula:YES];
    } else { // English
        [iDevicesUtil launchAppWebViewerWithURL: [NSURL URLWithString:TIMEX_EULA_URL_EN] forViewController: vc isEula:YES];
    }
}


+ (NSString *)getGoalTypeStringFormat:(GoalType)goalType {
    
    switch (goalType) {
        case Normal:
            return GOAL_TYPE_ACTIVE;
            break;
        case Pretty:
            return GOAL_TYPE_PRETTY_ACTIVE;
            break;
        case Very:
            return GOAL_TYPE_VERY_ACTIVE;
            break;
        case Custom:
            return GOAL_TYPE_CUSTOM;
            break;
        default:
            break;
    }
}

+(void)setNavigationTitle:(NSString *)title forViewController:(UIViewController *)viewController
{
    NSDictionary * navBarTitleTextAttributes =  @{NSFontAttributeName : [UIFont fontWithName:[iDevicesUtil getAppWideBoldFontName] size:APP_HEADER_FONT_SIZE] };
    viewController.navigationController.navigationBar.titleTextAttributes = navBarTitleTextAttributes;
    viewController.navigationItem.title = title;
    
}

+ (BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate
{
    if ([date compare:beginDate] == NSOrderedAscending)
        return NO;
    
    if ([date compare:endDate] == NSOrderedDescending)
        return NO;
    
    return YES;
}

+ (NSString *)getFirstLetterofTheDay:(NSDate *)date {
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    NSDateComponents *comps = [gregorian components:NSCalendarUnitWeekday fromDate:date];
    NSInteger weekday = [comps weekday];
    
    NSArray *weeks = @[NSLocalizedString(@"SUN", nil), NSLocalizedString(@"MON", nil), NSLocalizedString(@"TUE", nil), NSLocalizedString(@"WED", nil), NSLocalizedString(@"THU", nil), NSLocalizedString(@"FRI", nil), NSLocalizedString(@"SAT", nil)];
    
    NSString *firstLetter = [weeks[weekday - 1] substringToIndex:1];
    
    return firstLetter;
}

+ (NSInteger)getDayCountBetweenDates:(NSDate *)startDate enddate:(NSDate *)endDate {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay
                                                                   fromDate:startDate
                                                                     toDate:endDate
                                                                    options:0];
    return components.day + 1;
    
}

+ (NSInteger)getWeekCountBetweenDates:(NSDate *)startDate enddate:(NSDate *)endDate
{
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekOfYear
                                                                   fromDate:startDate
                                                                     toDate:endDate
                                                                    options:0];
    return components.weekOfYear + 1;
    
}

+ (NSInteger)getMonthCountBetweenDates:(NSDate *)startDate enddate:(NSDate *)endDate
{
    NSInteger month = [[[NSCalendar currentCalendar] components: NSCalendarUnitMonth
                                                       fromDate: startDate
                                                         toDate: endDate
                                                        options: 0] month];
    
    return month + 1;
    
}
+ (NSInteger)getYearCountBetweenDates:(NSDate *)startDate enddate:(NSDate *)endDate
{
    NSInteger year = [[[NSCalendar currentCalendar] components: NSCalendarUnitYear
                                                      fromDate: startDate
                                                        toDate: endDate
                                                       options: 0] year];
    
    return year + 1;
    
}

+ (NSComparisonResult)compareDateOnly:(NSDate *)firstDate AndEndDate:(NSDate *)secondDate {
    if (firstDate != nil && secondDate != nil) {
        NSUInteger dateFlags = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay;
        NSCalendar *gregorianCalendar = [NSCalendar currentCalendar];
        NSDateComponents *selfComponents = [gregorianCalendar components:dateFlags fromDate:firstDate];
        NSDate *selfDateOnly = [gregorianCalendar dateFromComponents:selfComponents];
        
        NSDateComponents *otherCompents = [gregorianCalendar components:dateFlags fromDate:secondDate];
        NSDate *otherDateOnly = [gregorianCalendar dateFromComponents:otherCompents];
        return [selfDateOnly compare:otherDateOnly];
    }
    return NO;
}

+ (NSDate *)getHourDate:(NSDate *)selectedDate withSelectedTime:(NSString *)selectedTime {
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    dayComponent.hour = selectedTime.integerValue;
    return [theCalendar dateByAddingComponents:dayComponent toDate:selectedDate options:0];
}

+ (NSNumber *)getHourFromDate:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour) fromDate:date];
    return [NSNumber numberWithInt:(int)components.hour];
}

+ (NSString *)getTimeFromHrValue:(int)hour formatInNewLine:(BOOL)formatInNewLine {
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    if ([iDevicesUtil isSystemTimeFormat24Hr]) {
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [timeFormat setLocale:locale];
        if (formatInNewLine) {
            [timeFormat setDateFormat:@"HH"];
            return [timeFormat stringFromDate:[timeFormat dateFromString:[NSString stringWithFormat:@"%d", hour]]];
        } else {
            [timeFormat setDateFormat:@"HH:mm"];
            return [timeFormat stringFromDate:[timeFormat dateFromString:[NSString stringWithFormat:@"%d:%d", hour, 0]]];
        }
    } else {
        if (formatInNewLine) {
            [timeFormat setDateFormat:@"h\na"];
            if (hour >= 12)
                return [[timeFormat stringFromDate:[timeFormat dateFromString:[NSString stringWithFormat:@"%d\npm", hour - 12]]] lowercaseString];
            else
                return [[timeFormat stringFromDate:[timeFormat dateFromString:[NSString stringWithFormat:@"%d\nam", hour]]] lowercaseString];

        } else {
            [timeFormat setDateFormat:@"h:mm a"];
            if (hour >= 12)
                return [timeFormat stringFromDate:[timeFormat dateFromString:[NSString stringWithFormat:@"%d:%d pm", hour - 12, 0]]];
            else
                return [timeFormat stringFromDate:[timeFormat dateFromString:[NSString stringWithFormat:@"%d:%d am", hour, 0]]];

        }
    }
}

+(NSString *)getWatchID {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:kCONNECTED_DEVICE_UUID_PREF_NAME] != nil) {
        return [userDefaults objectForKey: kCONNECTED_DEVICE_UUID_PREF_NAME];
    } else {
        return nil;
    }
}
@end
