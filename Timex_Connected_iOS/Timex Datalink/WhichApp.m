//
//  WhichApp.m
//  Timex Connected
//
//  Created by Mark Daigle on 6/5/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "WhichApp.h"
#import "TDDefines.h"

@implementation WhichApp

BOOL isiPad;

+ (BOOL) iPad
{
	return IDIOM == IPAD;
}

+ (BOOL) iPhone
{
	return !(IDIOM == IPAD);
}


@end
