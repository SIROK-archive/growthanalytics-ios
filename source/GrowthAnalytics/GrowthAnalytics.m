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
        
        GAClientEvent *clientEvent = [GAClientEvent createWithClientId:[[[GrowthbeatCore sharedInstance] client] id] eventId:eventId properties:properties];
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
        
        GAClientTag *clientTag = [GAClientTag createWithClientId:[[[GrowthbeatCore sharedInstance] client] id] tagId:tagId value:value];
        if(clientTag) {
            [GAClientTag save:clientTag];
            [logger info:@"Setting tag success."];
        }
        
    });
    
}

- (void)open {
    NSDictionary *properties = [[NSDictionary alloc] init];
    [properties setValue:nil forKey:@"referrer"];
    [self track:[NSString stringWithFormat:@"%@:Open", kGAGeneralTag] properties:properties option:GATrackOptionDefault];
}

- (void)close {
    GAClientEvent *event = [GAClientEvent load:[NSString stringWithFormat:@"%@:Open", kGAGeneralTag]];
    NSDictionary *properties = nil;
    if(event) {
        NSTimeInterval interval = [[event created] timeIntervalSinceNow];
        properties = [[NSDictionary alloc] init];
        [properties setValue:[[NSString alloc] initWithFormat:@"%f", interval] forKey:@"Time"];
    }
    [self track:[NSString stringWithFormat:@"%@:Close", kGAGeneralTag] properties:properties option:GATrackOptionDefault];
}

- (void)purchase:(int)price setCategory:(NSString *)category setProduct:(NSString *)product {
    NSDictionary *properties = [[NSDictionary alloc] init];
    [properties setValue:[[NSString alloc] initWithFormat:@"%d", price] forKey:@"price"];
    [properties setValue:@"Caegory" forKey:category];
    [properties setValue:@"Product" forKey:product];
    [self track:[NSString stringWithFormat:@"%@:Purchase", kGAGeneralTag] properties:properties option:GATrackOptionDefault];
}

- (void)setUserId:(NSString *)userId {
    [self tag:[self generateTagId:@"UserId"] value:userId];
}

- (void)setAdvertisingId:(NSString *)idfa {
    [self tag:[self generateTagId:@"AdvertisingID"] value:idfa];
}

- (void)setAge:(int)age {
    [self tag:[self generateTagId:@"Age"] value:[NSString stringWithFormat:@"%d", age]];
}

- (void)setGender:(NSString *)gender {
    [self tag:[self generateTagId:@"Gender"] value:gender];
}

- (void)setLebel:(NSString *)level {
    [self tag:[self generateTagId:@"Level"] value:level];
}

- (void)setName:(NSString *)name {
    [self tag:[self generateTagId:@"Name"] value:name];
}

- (void)setLanguage:(NSString *)language {
    [self tag:[self generateTagId:@"Language"] value:language];
}

- (void)setOS:(NSString *)os {
    [self tag:[self generateTagId:@"OS"] value:os];
}

- (void)setTimeZone:(NSString *)timezone {
    [self tag:[self generateTagId:@"TimeZone"] value:timezone];
}

- (void)setTimeZoneOffset:(NSString *)timezoneOffset {
    [self tag:[self generateTagId:@"TimeZoneOffset"] value:timezoneOffset];
}

- (void)setAppVersion:(NSString *)appVersion {
    [self tag:[self generateTagId:@"AppVersion"] value:appVersion];
}

- (void)setDevelopment {
    [self tag:[self generateTagId:@"Development"] value:nil];
}

- (void)setRandom {
    [self tag:[self generateTagId:@"Random"] value:nil];
}

- (void) setDeviceTags {
    
    if ([GBDeviceUtils model]) {
        [self tag:@"Device" value:[GBDeviceUtils model]];
    }
    if ([GBDeviceUtils os]) {
        [self tag:@"OS" value:[GBDeviceUtils os]];
    }
    if ([GBDeviceUtils language]) {
        [self tag:@"Language" value:[GBDeviceUtils language]];
    }
    if ([GBDeviceUtils timeZone]) {
        [self tag:@"Time Zone" value:[GBDeviceUtils timeZone]];
    }
    if ([GBDeviceUtils version]) {
        [self tag:@"Version" value:[GBDeviceUtils version]];
    }
    if ([GBDeviceUtils build]) {
        [self tag:@"Build" value:[GBDeviceUtils build]];
    }
    
}

- (NSString *)generateEventId:(NSString *)name {
    return [NSString stringWithFormat:@"Event:%@:Default:%@", applicationId, name];
}

- (NSString *)generateTagId:(NSString *)name {
    return [NSString stringWithFormat:@"Tag:%@:Default:%@", applicationId, name];
}

@end
