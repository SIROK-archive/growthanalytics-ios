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
static NSString *const kGBLoggerDefaultTag = @"GrowthAnalytics";
static NSString *const kGBHttpClientDefaultBaseUrl = @"https://api.analytics.growthbeat.com/";
static NSString *const kGBPreferenceDefaultFileName = @"growthanalytics-preferences";

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
        self.logger = [[GBLogger alloc] initWithTag:kGBLoggerDefaultTag];
        self.httpClient = [[GBHttpClient alloc] initWithBaseUrl:[NSURL URLWithString:kGBHttpClientDefaultBaseUrl]];
        self.preference = [[GBPreference alloc] initWithFileName:kGBPreferenceDefaultFileName];
    }
    return self;
}

- (void)initializeWithApplicationId:(NSString *)newApplicationId credentialId:(NSString *)newCredentialId {
    
    self.applicationId = newApplicationId;
    self.credentialId = newCredentialId;
    
    [[GrowthbeatCore sharedInstance] initializeWithApplicationId:applicationId credentialId:credentialId];
    
}

- (void)trackEvent:(NSString *)eventId properties:(NSDictionary *)properties option:(GATrackEventOption)option {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        [logger info:@"Track event... (eventId: %@, properties: %@)", eventId, properties];
        if ((option & GATrackEventOptionOnce) && [GAClientEvent loadClientEvent:eventId]) {
            [logger info:@"Already exists Track event. (eventId: %@, properties: %@)", eventId, properties];
            return;
        }
        
        if ((option & GATrackEventOptionMarkFirstTime) && ![GAClientEvent loadClientEvent:eventId]) {
            [properties setValue:@"first_time" forKey:@""];
        }
        
        GAClientEvent *clientEvent = [GAClientEvent createWithClientId:[[[GrowthbeatCore sharedInstance] client] id] eventId:eventId properties:properties];
        if(clientEvent) {
            [logger info:@"Tracking event success. (clientEventId: %@)", clientEvent.id];
            if ((option & GATrackEventOptionOnce) && (option & GATrackEventOptionMarkFirstTime) && ![GAClientEvent loadClientEvent:eventId]) {
                [GAClientEvent save:clientEvent];
            }
        }
    
    });

}

- (void)setTag:(NSString *)tagId value:(NSString *)value {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        [logger info:@"Set tag... (tagId: %@, value: %@)", tagId, value];
        GAClientTag *referencedClientTag = [GAClientTag loadClientTag:tagId];
        NSComparisonResult result = [[referencedClientTag value] compare:value];
        switch (result) {
            case NSOrderedSame:
                [logger info:@"Already set tag. (tagId: %@, value: %@)", tagId, value];
                return;
                
            default:
                break;
        }
        
        GAClientTag *clientTag = [GAClientTag createWithClientId:[[[GrowthbeatCore sharedInstance] client] id] tagId:tagId value:value];
        if(clientTag) {
            [logger info:@"Setting tag success. (clientTagId: %@)", clientTag.id];
            [GAClientTag save:clientTag];
        }
        
    });
    
}

@end
