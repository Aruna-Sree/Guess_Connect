//
//  TDStoredWatchUserDefaults.m
//  timex
//
//  Created by Nick Graff on 3/24/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import "TDStoredWatchUserDefaults.h"
#import "TDDefines.h"
#import "TDDevice.h"
#import "TDHomeViewController.h"
#import "TDAppDelegate.h"
#import "TDWatchProfile.h"
#import "TimexWatchDB.h"
#import "OTLogUtil.h"

@implementation TDStoredWatchUserDefaults

+(void)setStoredPeripherals:(NSArray*)value{
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:@"Stored watches"];
}
+(NSArray*)storedPeripherals{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"Stored watches"];
}
+(void)deleteStoredPeripherals{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:@"Stored watches"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Stored watches"];
}

+(void)changeHomeScreen:(PeripheralDevice*)device{
    switch (device.type) {
        case TDDeviceType_IQMove:
        {
            [(TDAppDelegate *)[[UIApplication sharedApplication] delegate] setNavigationBarSettingsForM328:[UIApplication sharedApplication].keyWindow.rootViewController.navigationController.navigationController];
            [[TDWatchProfile sharedInstance] setWatchStyle: timexDatalinkWatchStyle_IQ];
            [[TimexWatchDB sharedInstance] augmentExistingDatabaseForM053];
            OTLog([NSString stringWithFormat:@"You select: %u",timexDatalinkWatchStyle_IQ]);
            TDHomeViewController *mainControllerIQMove = [[TDHomeViewController alloc]initWithNibName:@"TDHomeViewController" bundle:nil doFirmwareCheck:TRUE initialSync:YES];
            [self AssignNewControllerToCenterController:mainControllerIQMove];
        }
            break;
        case TDDeviceType_IQTravel:
        {
            [(TDAppDelegate *)[[UIApplication sharedApplication] delegate] setNavigationBarSettingsForM328:[UIApplication sharedApplication].keyWindow.rootViewController.navigationController.navigationController];
            [[TDWatchProfile sharedInstance] setWatchStyle: timexDatalinkWatchStyle_IQTravel];
            [[TimexWatchDB sharedInstance] augmentExistingDatabaseForM053];
            OTLog([NSString stringWithFormat:@"You select: %u",timexDatalinkWatchStyle_IQTravel]);
            TDHomeViewController *mainControllerIQMove = [[TDHomeViewController alloc]initWithNibName:@"TDTravelHomeViewController" bundle:nil doFirmwareCheck:TRUE initialSync:YES];
            [self AssignNewControllerToCenterController:mainControllerIQMove];
        }
            break;
        
        default:
            break;
    }
    [[TDWatchProfile sharedInstance] commitChangesToDatabase];
}
+ (void) AssignNewControllerToCenterController: (TDRootViewController *) newController
{
    UINavigationController *navigationController = [UIApplication sharedApplication].keyWindow.rootViewController.navigationController;
    [[UIApplication sharedApplication].keyWindow.rootViewController.navigationController setNavigationBarHidden:NO animated:NO];
    NSArray *controllers = [NSArray arrayWithObject: newController];
    navigationController.viewControllers = controllers;
}

@end
