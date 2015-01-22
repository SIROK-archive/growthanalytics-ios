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

static NSString *const kGAGeneralTag = @"General";

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

- (void)track:(NSString *)eventId {
    [self track:eventId properties:nil option:GATrackOptionDefault];
}

- (void)track:(NSString *)eventId properties:(NSDictionary *)properties {
    [self track:eventId properties:properties option:GATrackOptionDefault];
}

- (void)track:(NSString *)eventId option:(GATrackOption)option {
    [self track:eventId properties:nil option:option];
}

- (void)track:(NSString *)eventId properties:(NSDictionary *)properties option:(GATrackOption)option {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        [logger info:@"Track event... (eventId: %@, properties: %@)", eventId, properties];
        
        int counter = 0;
        GAClientEvent *existingClientEvent = [GAClientEvent load:eventId];
        
        if (existingClientEvent) {
            if (option == GATrackOptionOnce) {
                [logger info:@"Event already sent with once option. (eventId: %@)", eventId];
                return;
            }
            counter = [[existingClientEvent.properties objectForKey:@"counter"] intValue];
        }
        
        if (option == GATrackOptionCounter) {
            [properties setValue:[NSString stringWithFormat:@"%d", counter] forKey:@"counter"];
        }
        
        GAClientEvent *clientEvent = [GAClientEvent createWithClientId:[[[GrowthbeatCore sharedInstance] waitClient] id] eventId:eventId properties:properties];
        if(clientEvent) {
            [GAClientEvent save:clientEvent];
            [logger info:@"Tracking event success. (id: %@)", clientEvent.id];
        }
    
    });

}

- (void)tag:(NSString *)tagId {
    [self tag:tagId value:nil];
}

- (void)tag:(NSString *)tagId value:(NSString *)value {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        [logger info:@"Set tag... (tagId: %@, value: %@)", tagId, value];
        
        GAClientTag *existingClientTag = [GAClientTag load:tagId];
        if(existingClientTag) {
            if(value == existingClientTag.value || (value && [value isEqualToString:existingClientTag.value])) {
                [logger info:@"Tag exists with the same value. (tagId: %@, value: %@)", tagId, value];
                return;
            }
            [logger info:@"Tag exists with the other value. (tagId: %@, value: %@)", tagId, value];
        }
        
        GAClientTag *clientTag = [GAClientTag createWithClientId:[[[GrowthbeatCore sharedInstance] waitClient] id] tagId:tagId value:value];
        if(clientTag) {
            [GAClientTag save:clientTag];
            [logger info:@"Setting tag success."];
        }
        
    });
    
}

- (void)open {
    [self track:[self generateEventId:@"Open"]];
    [self track:[self generateEventId:@"Install"] option:GATrackOptionOnce];
}

- (void)close {
    GAClientEvent *openEvent = [GAClientEvent load:[NSString stringWithFormat:@"%@:Open", kGAGeneralTag]];
    if(!openEvent)
        return;
    NSTimeInterval interval = -1 * [[openEvent created] timeIntervalSinceNow];
    [self track:[self generateEventId:@"Close"] properties:@{
        @"time": [NSString stringWithFormat:@"%d", (int)interval]
    }];
}

- (void)purchase:(int)price setCategory:(NSString *)category setProduct:(NSString *)product {
    [self track:[self generateEventId:@"Purchase"] properties:@{
        @"price": [NSString stringWithFormat:@"%d", price],
        @"category": category,
        @"product": product
    }];
}

- (void)setUserId:(NSString *)userId {
    [self tag:[self generateTagId:@"UserId"] value:userId];
}

- (void)setName:(NSString *)name {
    [self tag:[self generateTagId:@"Name"] value:name];
}

- (void)setAge:(int)age {
    [self tag:[self generateTagId:@"Age"] value:[NSString stringWithFormat:@"%d", age]];
}

- (void)setGender:(GAGender)gender {
    switch (gender) {
        case GAGenderMale:
            [self tag:[self generateTagId:@"Gender"] value:@"male"];
            break;
        case GAGenderFemale:
            [self tag:[self generateTagId:@"Gender"] value:@"female"];
            break;
        default:
            break;
    }
}

- (void)setLevel:(int)level {
    [self tag:[self generateTagId:@"Level"] value:[NSString stringWithFormat:@"%d", level]];
}

- (void)setDevelopment:(BOOL)development {
    [self tag:[self generateTagId:@"Development"] value:development?@"true":@"false"];
}

- (void)setDeviceModel {
    [self tag:[self generateTagId:@"DeviceModel"] value:[GBDeviceUtils model]];
}

- (void)setOS {
    [self tag:[self generateTagId:@"OS"] value:[GBDeviceUtils os]];
}

- (void)setLanguage {
    [self tag:[self generateTagId:@"Language"] value:[GBDeviceUtils language]];
}

- (void)setTimeZone {
    [self tag:[self generateTagId:@"TimeZone"] value:[GBDeviceUtils timeZone]];
}

- (void)setTimeZoneOffset {
    [self tag:[self generateTagId:@"TimeZoneOffset"] value:[GBDeviceUtils timeZoneOffset]];
}

- (void)setAppVersion {
    [self tag:[self generateTagId:@"AppVersion"] value:[GBDeviceUtils version]];
}

- (void)setRandom {
    [self tag:[self generateTagId:@"Random"] value:[NSString stringWithFormat:@"%lf", (double)rand() / RAND_MAX]];
}

- (void)setAdvertisingId:(NSString *)idfa {
    [self tag:[self generateTagId:@"AdvertisingID"] value:idfa];
}

- (void)setBasicTags {
    [self setDeviceModel];
    [self setOS];
    [self setLanguage];
    [self setTimeZone];
    [self setTimeZoneOffset];
    [self setAppVersion];
}

- (NSString *)generateEventId:(NSString *)name {
    return [NSString stringWithFormat:@"Event:%@:Default:%@", applicationId, name];
}

- (NSString *)generateTagId:(NSString *)name {
    return [NSString stringWithFormat:@"Tag:%@:Default:%@", applicationId, name];
}

@end
