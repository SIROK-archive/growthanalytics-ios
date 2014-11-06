//
//  GADomain.m
//  GrowthAnalytics
//
//  Created by Kataoka Naoyuki on 2014/11/06.
//  Copyright (c) 2014年 SIROK, Inc. All rights reserved.
//

#import "GADomain.h"

@implementation GADomain

+ (id) domainWithDictionary:(NSDictionary *)dictionary {
    
    if (!dictionary) {
        return nil;
    }
    
    return [[self alloc] initWithDictionary:dictionary];
    
}

- (id) initWithDictionary:(NSDictionary *)dictionary {
    return [self init];
}

@end
