//
//  TDHTTPClient.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 3/11/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "TDHTTPClient.h"
#import "OTLogUtil.h"
static TDHTTPClient * instance = nil;

@implementation TDHTTPClient

@synthesize parameters, delegate;

+(id) sharedInstance
{
	if (!instance)
	{
		instance = [[[self class] alloc] initWithBaseURL: [NSURL URLWithString: @"http://www.timex.com"]];
	}
	
	return instance;
}

- (void) startPost
{    
    [self postPath: [self.baseURL absoluteString] parameters: parameters success: ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         OTLog(@"Success: %@", operation.responseString);
         [delegate postSuccessful: operation];
     }
     failure: ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         OTLog(@"Error: %@",  operation.responseString);
         [delegate postFailed: operation];
     }];
}

@end
