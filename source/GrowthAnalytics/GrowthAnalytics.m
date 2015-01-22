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

- (void)setUserId:(NSString *)userId {
    [self tag:[NSString stringWithFormat:@"%@:UserId", kGAGeneralTag] value:userId];
}

- (void)setAdvertisingId:(NSString *)idfa {
    [self tag:[NSString stringWithFormat:@"%@:AdvertisingId", kGAGeneralTag] value:idfa];
}

//- (void)setAge:(NSInteger) age {
//    [self tag:[NSString stringWithFormat:@"%@:age", kGAGeneralTag] value:[[NSString alloc] initWithFormat:@"%d", age]];
//}

- (void)setGender:(NSString *)gender {
    [self tag:[NSString stringWithFormat:@"%@:Gender", kGAGeneralTag] value:gender];
}

- (void)setLebel:(NSString *)level {
    [self tag:[NSString stringWithFormat:@"%@:Level", kGAGeneralTag] value:level];
}

- (void)setName:(NSString *)name {
    [self tag:[NSString stringWithFormat:@"%@:Name", kGAGeneralTag] value:name];
}

- (void)setLanguage:(NSString *)language {
    [self tag:[NSString stringWithFormat:@"%@:Language", kGAGeneralTag] value:language];
}

- (void)setLocale:(NSString *)locale {
    [self tag:[NSString stringWithFormat:@"%@:Locale", kGAGeneralTag] value:locale];
}

- (void)setOS:(NSString *)os {
    [self tag:[NSString stringWithFormat:@"%@:OS", kGAGeneralTag] value:os];
}

- (void)setTimeZone:(NSString *)timezone {
    [self tag:[NSString stringWithFormat:@"%@:TimeZone", kGAGeneralTag] value:timezone];
}

- (void)setAppVersion:(NSString *)appVersion {
    [self tag:[NSString stringWithFormat:@"%@:AppVersion", kGAGeneralTag] value:appVersion];
}

- (void)setDevelopment {
    [self tag:[NSString stringWithFormat:@"%@:Development", kGAGeneralTag] value:nil];
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

- (void)purchase:(NSInteger)price setCategory:(NSString *)category setProduct:(NSString *)product {
    NSDictionary *properties = [[NSDictionary alloc] init];
    [properties setValue:[[NSString alloc] initWithFormat:@"%ld", price] forKey:@"price"];
    [properties setValue:@"Caegory" forKey:category];
    [properties setValue:@"Product" forKey:product];
    [self track:[NSString stringWithFormat:@"%@:Purchase", kGAGeneralTag] properties:properties option:GATrackOptionDefault];
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

@end
