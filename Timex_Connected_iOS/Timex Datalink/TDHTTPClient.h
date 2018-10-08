//
//  TDHTTPClient.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 3/11/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "AFNetworking.h"

@protocol TDHTTPClientDelegate;

@interface TDHTTPClient : AFHTTPClient

    @property (nonatomic, strong) NSDictionary * parameters;
    @property (nonatomic, weak) id<TDHTTPClientDelegate> delegate;
    +(id) sharedInstance;
    - (void) startPost;
@end

@protocol TDHTTPClientDelegate

- (void)postSuccessful: (AFHTTPRequestOperation *)operation;
- (void)postFailed: (AFHTTPRequestOperation *)operation;

@end
