//
//  GAService.m
//  GrowthAnalytics
//
//  Created by Kataoka Naoyuki on 2014/11/06.
//  Copyright (c) 2014年 SIROK, Inc. All rights reserved.
//

#import "GAService.h"
#import "GrowthAnalytics.h"

@implementation GAService

- (void) httpRequest:(GBHttpRequest *)httpRequest success:(void (^)(GBHttpResponse *httpResponse))success fail:(void (^)(GBHttpResponse *httpResponse))fail {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        GBHttpResponse *httpResponse = [[[GrowthAnalytics sharedInstance] httpClient] httpRequest:httpRequest];
        if(httpResponse.success) {
            success(httpResponse);
        } else {
            fail(httpResponse);
        }
    });
    
}

@end
