//
//  GAClientEvent.m
//  GrowthAnalytics
//
//  Created by Kataoka Naoyuki on 2014/11/06.
//  Copyright (c) 2014年 SIROK, Inc. All rights reserved.
//

#import "GAClientEvent.h"
#import "GBUtils.h"

@implementation GAClientEvent

@synthesize id;
@synthesize clientId;
@synthesize eventId;
@synthesize properties;
@synthesize created;

- (id) initWithDictionary:(NSDictionary *)dictionary {
    
    self = [super init];
    if (self) {
        if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]) {
            self.id = [dictionary objectForKey:@"id"];
        }
        if ([dictionary objectForKey:@"clientId"] && [dictionary objectForKey:@"clientId"] != [NSNull null]) {
            self.clientId = [dictionary objectForKey:@"clientId"];
        }
        if ([dictionary objectForKey:@"eventId"] && [dictionary objectForKey:@"eventId"] != [NSNull null]) {
            self.eventId = [dictionary objectForKey:@"eventId"];
        }
        if ([dictionary objectForKey:@"properties"] && [dictionary objectForKey:@"properties"] != [NSNull null]) {
            self.properties = [NSDictionary dictionaryWithDictionary:[dictionary objectForKey:@"properties"]];
        }
        if ([dictionary objectForKey:@"created"] && [dictionary objectForKey:@"created"] != [NSNull null]) {
            self.created = [GBDateUtils dateWithDateTimeString:[dictionary objectForKey:@"created"]];
        }
    }
    return self;
    
}

@end
