//
//  GAClientEvent.m
//  GrowthAnalytics
//
//  Created by Kataoka Naoyuki on 2014/11/06.
//  Copyright (c) 2014年 SIROK, Inc. All rights reserved.
//

#import "GAClientEvent.h"
#import "GBUtils.h"
#import "GBHttpClient.h"
#import "GrowthAnalytics.h"

@implementation GAClientEvent

@synthesize id;
@synthesize clientId;
@synthesize eventId;
@synthesize properties;
@synthesize created;

+ (GAClientEvent *)createWithClientId:(NSString *)clientId eventId:(NSString *)eventId properties:(NSDictionary *)properties {
    
    NSString *path = @"/1/client_events";
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    
    if (clientId) {
        [body setObject:clientId forKey:@"clientId"];
    }
    if (eventId) {
        [body setObject:eventId forKey:@"eventId"];
    }
    if (properties) {
        for(id key in [properties keyEnumerator]) {
            [body setObject:[properties objectForKey:key] forKey:[NSString stringWithFormat:@"properties[%@]", key]];
        }
    }
    
    GBHttpRequest *httpRequest = [GBHttpRequest instanceWithMethod:GBRequestMethodPost path:path query:nil body:body];
    GBHttpResponse *httpResponse = [[[GrowthAnalytics sharedInstance] httpClient] httpRequest:httpRequest];
    if(!httpResponse.success){
        [[[GrowthAnalytics sharedInstance] logger] error:@"Filed to create client event. %@", httpResponse.error];
        return nil;
    }
    
    return [GAClientEvent domainWithDictionary:httpResponse.body];

}

+ (void) save:(GAClientEvent *)clientEvent {
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:clientEvent];
    [[[GrowthAnalytics sharedInstance] preference] setObject:data forKey:[clientEvent eventId]];
    
}

+ (GAClientEvent *) loadClientEvent:(NSString *)eventId {
    
    NSData *data = [[[GrowthAnalytics sharedInstance] preference] objectForKey:eventId];
    if (!data) {
        return nil;
    }
    
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
}

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
