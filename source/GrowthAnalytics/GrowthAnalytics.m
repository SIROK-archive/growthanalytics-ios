//
//  GrowthAnalytics.m
//  GrowthAnalytics
//
//  Created by Kataoka Naoyuki on 2014/11/06.
//  Copyright (c) 2014年 SIROK, Inc. All rights reserved.
//

#import "GrowthAnalytics.h"
#import "GAClientEvent.h"
#import "GAClientTag.h"

static GrowthAnalytics *sharedInstance = nil;
static NSString *const kGPBaseUrl = @"https://api.analytics.growthbeat.com/";
static NSString *const kGPPreferenceDefaultFileName = @"growthanalytics-preferences";

@interface GrowthAnalytics () {
    
    GBLogger *logger;
    GBHttpClient *httpClient;
    GBPreference *preference;
    NSString *applicationId;
    NSString *credentialId;
    
}

@property (nonatomic, strong) GBLogger *logger;
@property (nonatomic, strong) GBHttpClient *httpClient;
@property (nonatomic, strong) GBPreference *preference;
@property (nonatomic, strong) NSString *applicationId;
@property (nonatomic, strong) NSString *credentialId;

@end

@implementation GrowthAnalytics

@synthesize logger;
@synthesize httpClient;
@synthesize preference;
@synthesize applicationId;
@synthesize credentialId;

+ (GrowthAnalytics *) sharedInstance {
    @synchronized(self) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 5.0f) {
            return nil;
        }
        if (!sharedInstance) {
            sharedInstance = [[self alloc] init];
        }
        return sharedInstance;
    }
}

- (id) init {
    self = [super init];
    if (self) {
        self.logger = [[GBLogger alloc] initWithTag:@"Growth Analytics"];
        self.httpClient = [[GBHttpClient alloc] initWithBaseUrl:[NSURL URLWithString:kGPBaseUrl]];
        self.preference = [[GBPreference alloc] initWithFileName:kGPPreferenceDefaultFileName];
    }
    return self;
}

- (void)initializeWithApplicationId:(NSString *)newApplicationId credentialId:(NSString *)newCredentialId {
    
    self.applicationId = newApplicationId;
    self.credentialId = newCredentialId;
    
    [GrowthbeatCore initializeWithApplicationId:applicationId credentialId:credentialId];
    
}

- (void)trackEvent:(NSString *)eventId properties:(NSDictionary *)properties {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        [logger info:@"Track event... (eventId: %@, properties: %@)", eventId, properties];
        
        GAClientEvent *clientEvent = [GAClientEvent createWithClientId:[[[GrowthbeatCore sharedInstance] client] id] eventId:eventId properties:properties];
        if(clientEvent) {
            [logger info:@"Tracking event success. (clientEventId: %@)", clientEvent.id];
        }
    
    });

}

- (void)setTag:(NSString *)tagId value:(NSString *)value {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        [logger info:@"Set tag... (tagId: %@, value: %@)", tagId, value];
        
        GAClientTag *clientTag = [GAClientTag createWithClientId:[[[GrowthbeatCore sharedInstance] client] id] tagId:tagId value:value];
        if(clientTag) {
            [logger info:@"Setting tag success. (clientTagId: %@)", clientTag.id];
        }
        
    });
    
}

@end
