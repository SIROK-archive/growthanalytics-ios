//
//  GAClientEventService.m
//  GrowthAnalytics
//
//  Created by Kataoka Naoyuki on 2014/11/06.
//  Copyright (c) 2014年 SIROK, Inc. All rights reserved.
//

#import "GAClientEventService.h"


static GAClientEventService *sharedInstance = nil;

@implementation GAClientEventService

+ (GAClientEventService *) sharedInstance {
    
    @synchronized(self) {
        if (!sharedInstance) {
            sharedInstance = [[self alloc] init];
        }
        return sharedInstance;
    }
    
}

- (void)createWithClientId:(NSString *)clientId eventId:(NSString *)eventId properties:(NSDictionary *)properties success:(void(^) (GAClientEvent * clientEvent)) success fail:(void(^) (NSInteger status, NSError * error))fail {
    
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
    
    [self httpRequest:httpRequest success:^(GBHttpResponse *httpResponse) {
        GAClientEvent *event = [GAClientEvent domainWithDictionary:httpResponse.body];
        if (success) {
            success(event);
        }
    } fail:^(GBHttpResponse *httpResponse) {
        if (fail) {
            fail(httpResponse.httpUrlResponse.statusCode, httpResponse.error);
        }
    }];
    
}

@end
