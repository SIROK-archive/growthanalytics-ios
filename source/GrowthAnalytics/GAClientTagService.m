//
//  GAClientTagService.m
//  GrowthAnalytics
//
//  Created by Kataoka Naoyuki on 2014/11/06.
//  Copyright (c) 2014年 SIROK, Inc. All rights reserved.
//

#import "GAClientTagService.h"

static GAClientTagService *sharedInstance = nil;

@implementation GAClientTagService

+ (GAClientTagService *)sharedInstance {
    
    @synchronized(self) {
        if (!sharedInstance) {
            sharedInstance = [[self alloc] init];
        }
        return sharedInstance;
    }
    
}

- (void)createWithClientId:(NSString *)clientId tagId:(NSString *)tagId value:(NSString *)value success:(void(^) (GAClientTag * clientTag)) success fail:(void(^) (NSInteger status, NSError * error))fail {
    
    NSString *path = @"/1/client_events";
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    
    if (clientId) {
        [body setObject:clientId forKey:@"clientId"];
    }
    if (tagId) {
        [body setObject:tagId forKey:@"tagId"];
    }
    if (value) {
        [body setObject:value forKey:@"value"];
    }
    
    GBHttpRequest *httpRequest = [GBHttpRequest instanceWithMethod:GBRequestMethodPost path:path query:nil body:body];
    
    [self httpRequest:httpRequest success:^(GBHttpResponse *httpResponse) {
        GAClientTag *cientTag = [GAClientTag domainWithDictionary:httpResponse.body];
        if (success) {
            success(cientTag);
        }
    } fail:^(GBHttpResponse *httpResponse) {
        if (fail) {
            fail(httpResponse.httpUrlResponse.statusCode, httpResponse.error);
        }
    }];
    
}

@end
