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

- (void)trackEvent:(NSString *)eventId {
    [self trackEvent:eventId properties:[NSDictionary alloc] option:GATrackEventOptionDefault];
}

- (void)trackEventOnce:(NSString *)eventId {
    [self trackEvent:eventId properties:[NSDictionary alloc] option:GATrackEventOptionOnce];
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

- (void)setUserId:(NSString *)userId {
    [self setTag:[NSString stringWithFormat:@"%@:UserId", kGAGeneralTag] value:userId];
}

- (void)setAdvertisingId:(NSString *)idfa {
    [self setTag:[NSString stringWithFormat:@"%@:AdvertisingId", kGAGeneralTag] value:idfa];
}

//- (void)setAge:(NSInteger) age {
//    [self setTag:[NSString stringWithFormat:@"%@:age", kGAGeneralTag] value:[[NSString alloc] initWithFormat:@"%d", age]];
//}

- (void)setGender:(NSString *)gender {
    [self setTag:[NSString stringWithFormat:@"%@:Gender", kGAGeneralTag] value:gender];
}

- (void)setLebel:(NSString *)level {
    [self setTag:[NSString stringWithFormat:@"%@:Level", kGAGeneralTag] value:level];
}

- (void)setName:(NSString *)name {
    [self setTag:[NSString stringWithFormat:@"%@:Name", kGAGeneralTag] value:name];
}

- (void)setLanguage:(NSString *)language {
    [self setTag:[NSString stringWithFormat:@"%@:Language", kGAGeneralTag] value:language];
}

- (void)setLocale:(NSString *)locale {
    [self setTag:[NSString stringWithFormat:@"%@:Locale", kGAGeneralTag] value:locale];
}

- (void)setOS:(NSString *)os {
    [self setTag:[NSString stringWithFormat:@"%@:OS", kGAGeneralTag] value:os];
}

- (void)setTimeZone:(NSString *)timezone {
    [self setTag:[NSString stringWithFormat:@"%@:TimeZone", kGAGeneralTag] value:timezone];
}

- (void)setAppVersion:(NSString *)appVersion {
    [self setTag:[NSString stringWithFormat:@"%@:AppVersion", kGAGeneralTag] value:appVersion];
}

- (void)setDevelopment {
    [self setTag:[NSString stringWithFormat:@"%@:Development", kGAGeneralTag] value:nil];
}

- (void)open {
    NSDictionary *properties = [[NSDictionary alloc] init];
    [properties setValue:nil forKey:@"referrer"];
    [self trackEvent:[NSString stringWithFormat:@"%@:Open", kGAGeneralTag] properties:properties option:GATrackEventOptionDefault];
}

- (void)close {
    [self trackEvent:[NSString stringWithFormat:@"%@:Close", kGAGeneralTag] properties:nil option:GATrackEventOptionDefault];
    GAClientEvent *event = [GAClientEvent loadClientEvent:[NSString stringWithFormat:@"%@:Open", kGAGeneralTag]];
    if(event) {
        NSTimeInterval interval = [[event created] timeIntervalSinceNow];
        NSDictionary *properties = [[NSDictionary alloc] init];
        [properties setValue:[[NSString alloc] initWithFormat:@"%f", interval] forKey:@"Time"];
    }
}

- (void)purchase:(NSInteger)price setCategory:(NSString *)category setProduct:(NSString *)product {
    NSDictionary *properties = [[NSDictionary alloc] init];
    [properties setValue:[[NSString alloc] initWithFormat:@"%ld", price] forKey:@"price"];
    [properties setValue:@"Caegory" forKey:category];
    [properties setValue:@"Product" forKey:product];
    [self trackEvent:[NSString stringWithFormat:@"%@:Purchase", kGAGeneralTag] properties:properties option:GATrackEventOptionDefault];
}


- (void) setDeviceTags {
    
    if ([GBDeviceUtils model]) {
        [self setTag:@"Device" value:[GBDeviceUtils model]];
    }
    if ([GBDeviceUtils os]) {
        [self setTag:@"OS" value:[GBDeviceUtils os]];
    }
    if ([GBDeviceUtils language]) {
        [self setTag:@"Language" value:[GBDeviceUtils language]];
    }
    if ([GBDeviceUtils timeZone]) {
        [self setTag:@"Time Zone" value:[GBDeviceUtils timeZone]];
    }
    if ([GBDeviceUtils version]) {
        [self setTag:@"Version" value:[GBDeviceUtils version]];
    }
    if ([GBDeviceUtils build]) {
        [self setTag:@"Build" value:[GBDeviceUtils build]];
    }
    
}

@end
