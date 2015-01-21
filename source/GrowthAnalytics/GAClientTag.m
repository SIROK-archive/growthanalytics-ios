//
//  GAClientTag.m
//  GrowthAnalytics
//
//  Created by Kataoka Naoyuki on 2014/11/06.
//  Copyright (c) 2014年 SIROK, Inc. All rights reserved.
//

#import "GAClientTag.h"
#import "GBUtils.h"
#import "GBHttpClient.h"
#import "GrowthAnalytics.h"

@implementation GAClientTag

@synthesize clientId;
@synthesize tagId;
@synthesize value;
@synthesize created;

static NSString *const kGAPreferenceTagsKey = @"tags";

+ (GAClientTag *)createWithClientId:(NSString *)clientId tagId:(NSString *)tagId value:(NSString *)value {
    
    NSString *path = @"/1/client_tags";
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
    GBHttpResponse *httpResponse = [[[GrowthAnalytics sharedInstance] httpClient] httpRequest:httpRequest];
    if(!httpResponse.success){
        [[[GrowthAnalytics sharedInstance] logger] error:@"Filed to create client tag. %@", httpResponse.error];
        return nil;
    }
    
    return [GAClientTag domainWithDictionary:httpResponse.body];
}

+ (void) save:(GAClientTag *)clientTag {

    NSMutableDictionary *tags = [self loadClientTags];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:clientTag];

    [tags setObject:data forKey:[clientTag tagId]];
    
    [[[GrowthAnalytics sharedInstance] preference] setObject:tags forKey:kGAPreferenceTagsKey];
}

+ (GAClientTag *) load:(NSString *)tagId {
    
    NSMutableDictionary *tags = [self loadClientTags];
    NSData *data = [tags objectForKey:tagId];
    if (!data) {
        return nil;
    }
    
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
}

+ (NSMutableDictionary *) loadClientTags {
    
    NSDictionary *loadedTags = [[[GrowthAnalytics sharedInstance] preference] objectForKey:kGAPreferenceTagsKey];
    if (loadedTags && [loadedTags isKindOfClass:[NSDictionary class]]) {
        return [NSMutableDictionary dictionaryWithDictionary:loadedTags];
    }
    
    return [NSMutableDictionary dictionary];
    
}

- (id) initWithDictionary:(NSDictionary *)dictionary {
    
    self = [super init];
    if (self) {
        if ([dictionary objectForKey:@"clientId"] && [dictionary objectForKey:@"clientId"] != [NSNull null]) {
            self.clientId = [dictionary objectForKey:@"clientId"];
        }
        if ([dictionary objectForKey:@"tagId"] && [dictionary objectForKey:@"tagId"] != [NSNull null]) {
            self.tagId = [dictionary objectForKey:@"tagId"];
        }
        if ([dictionary objectForKey:@"value"] && [dictionary objectForKey:@"value"] != [NSNull null]) {
            self.value = [dictionary objectForKey:@"value"];
        }
        if ([dictionary objectForKey:@"created"] && [dictionary objectForKey:@"created"] != [NSNull null]) {
            self.created = [GBDateUtils dateWithDateTimeString:[dictionary objectForKey:@"created"]];
        }
    }
    return self;
    
}

#pragma mark --
#pragma mark NSCoding

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        if ([aDecoder containsValueForKey:@"clientId"]) {
            self.clientId = [aDecoder decodeObjectForKey:@"clientId"];
        }
        if ([aDecoder containsValueForKey:@"tagId"]) {
            self.tagId = [aDecoder decodeObjectForKey:@"tagId"];
        }
        if ([aDecoder containsValueForKey:@"value"]) {
            self.value = [aDecoder decodeObjectForKey:@"value"];
        }
        if ([aDecoder containsValueForKey:@"created"]) {
            self.created = [aDecoder decodeObjectForKey:@"created"];
        }
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:clientId forKey:@"clientId"];
    [aCoder encodeObject:tagId forKey:@"tagId"];
    [aCoder encodeObject:value forKey:@"value"];
    [aCoder encodeObject:created forKey:@"created"];
}

@end
