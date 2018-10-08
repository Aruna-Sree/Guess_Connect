//
//  NSDate+JSON.h
//  RunKeeper-iOS
//
//  Created by Reid van Melle on 11-09-15.
//  Copyright 2011 Brierwood Design Co-operative. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDate (JSON)

- (id)proxyForJson;
- (id)proxyForJsonInISO8601;
- (id)proxyForJsonInISO8601_DateOnly;
- (id)proxyForJsonInISO8601_TimeOnly;
- (id)proxyForJsonInISO8601GMT; // Gets time in GMT time zone // UTC

+ (NSDate*)dateFromJSONDate:(NSString*)string;

@end
