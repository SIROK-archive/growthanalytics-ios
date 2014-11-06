//
//  GrowthAnalytics.m
//  GrowthAnalytics
//
//  Created by Kataoka Naoyuki on 2014/11/06.
//  Copyright (c) 2014年 SIROK, Inc. All rights reserved.
//

#import "GrowthAnalytics.h"
#import "GAClientEventService.h"
#import "GAClientTagService.h"

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
    
    [logger info:@"Track event... (eventId: %@, properties: %@)", eventId, properties];
    
    [[GAClientEventService sharedInstance] createWithClientId:[[[GrowthbeatCore sharedInstance] client] id] eventId:eventId properties:properties success:^(GAClientEvent *clientEvent) {
        [logger info:@"Tracking event success. (clientEventId: %@)", clientEvent.id];
    } fail:^(NSInteger status, NSError *error) {
        [logger info:@"Tracking event fail. %@", error];
    }];
    
}

- (void)setTag:(NSString *)tagId value:(NSString *)value {
    
    [logger info:@"Set tag... (tagId: %@, value: %@)", tagId, value];
    
    [[GAClientTagService sharedInstance] createWithClientId:[[[GrowthbeatCore sharedInstance] client] id] tagId:tagId value:value success:^(GAClientTag *clientTag) {
        [logger info:@"Setting tag success. (clientTagId: %@)", clientTag.id];
    } fail:^(NSInteger status, NSError *error) {
        [logger info:@"Setting tag fail. %@", error];
    }];
    
}

@end
