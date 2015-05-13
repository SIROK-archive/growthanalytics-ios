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
#import <AdSupport/AdSupport.h>

#define ARC4RANDOM_MAX (0x100000000)

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

    BOOL initialized;
    NSDate *openTime;
    NSMutableArray *eventHandlers;

}

@property (nonatomic, strong) GBLogger *logger;
@property (nonatomic, strong) GBHttpClient *httpClient;
@property (nonatomic, strong) GBPreference *preference;

@property (nonatomic, strong) NSString *applicationId;
@property (nonatomic, strong) NSString *credentialId;

@property (nonatomic, assign) BOOL initialized;
@property (nonatomic, strong) NSDate *openTime;
@property (nonatomic, strong) NSMutableArray *eventHandlers;

@end

@implementation GrowthAnalytics

@synthesize logger;
@synthesize httpClient;

@synthesize preference;
@synthesize applicationId;
@synthesize credentialId;

@synthesize initialized;
@synthesize openTime;
@synthesize eventHandlers;

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
        self.initialized = NO;
        self.eventHandlers = [NSMutableArray array];
    }
    return self;
}

- (void) initializeWithApplicationId:(NSString *)newApplicationId credentialId:(NSString *)newCredentialId {

    if (initialized) {
        return;
    }
    initialized = YES;

    self.applicationId = newApplicationId;
    self.credentialId = newCredentialId;

    [[GrowthbeatCore sharedInstance] initializeWithApplicationId:applicationId credentialId:credentialId];

    [self setBasicTags];

}

- (void) track:(NSString *)namespace eventId:(NSString *)eventId {
    [self track:namespace eventId:eventId properties:nil option:GATrackOptionDefault complete:nil];
}

- (void) track:(NSString *)namespace eventId:(NSString *)eventId properties:(NSDictionary *)properties {
    [self track:namespace eventId:eventId properties:properties option:GATrackOptionDefault complete:nil];
}

- (void) track:(NSString *)namespace eventId:(NSString *)eventId option:(GATrackOption)option {
    [self track:namespace eventId:eventId properties:nil option:option complete:nil];
}

- (void) track:(NSString *)namespace eventId:(NSString *)eventId properties:(NSDictionary *)properties option:(GATrackOption)option complete:(void (^)(GAClientEvent *clientEvent))complete {

    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

        NSString *fullEventId = [self generateEventId:namespace name:eventId];
        [logger info:@"Track event... (eventId: %@)", fullEventId];

        NSMutableDictionary *processedProperties = [NSMutableDictionary dictionaryWithDictionary:properties];

        GAClientEvent *existingClientEvent = [GAClientEvent load:fullEventId];

        if (option == GATrackOptionOnce) {
            if (existingClientEvent) {
                [logger info:@"Event already sent with once option. (eventId: %@)", fullEventId];
                return;
            }
        }

        if (option == GATrackOptionCounter) {
            int counter = 0;
            if (existingClientEvent && existingClientEvent.properties) {
                counter = [[existingClientEvent.properties objectForKey:@"counter"] intValue];
            }
            [processedProperties setValue:[NSString stringWithFormat:@"%d", (counter + 1)] forKey:@"counter"];
        }

        GAClientEvent *clientEvent = [GAClientEvent createWithClientId:[[[GrowthbeatCore sharedInstance] waitClient] id] eventId:fullEventId properties:processedProperties credentialId:credentialId];
        if (clientEvent) {
            [GAClientEvent save:clientEvent];
            [logger info:@"Tracking event success. (id: %@, eventId: %@, properties: %@)", clientEvent.id, fullEventId, processedProperties];
        }

        for (GAEventHandler *eventHandler in [eventHandlers objectEnumerator]) {
            if (eventHandler.callback) {
                eventHandler.callback(eventId, processedProperties);
            }
        }

        if (complete) {
            complete(clientEvent);
        }

    });

}

- (void)track:(NSString *)lastId {
    [self track:@"Custom" eventId:lastId];
}
- (void)track:(NSString *)lastId properties:(NSDictionary *)properties {
    [self track:@"Custom" eventId:lastId properties:properties];
}
- (void)track:(NSString *)lastId option:(GATrackOption)option {
    [self track:@"Custom" eventId:lastId option:option];
}
- (void)track:(NSString *)lastId properties:(NSDictionary *)properties option:(GATrackOption)option {
    [self track:@"Custom" eventId:lastId properties:properties option:option complete:nil];
}

- (void) addEventHandler:(GAEventHandler *)eventHandler {
    [eventHandlers addObject:eventHandler];
}

- (void) tag:(NSString *)namespace tagId:(NSString *)tagId value:(NSString *)value {
    [self tag:namespace tagId:tagId value:value complete:nil];
}

- (void) tag:(NSString *)namespace tagId:(NSString *)tagId value:(NSString *)value complete:(void (^)(GAClientTag *clientTag))complete {

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

        NSString *fullTagId = [self generateTagId:namespace name:tagId];
        
        [logger info:@"Set tag... (tagId: %@, value: %@)", fullTagId, value];

        GAClientTag *existingClientTag = [GAClientTag load:fullTagId];
        if (existingClientTag) {
            if (value == existingClientTag.value || (value && [value isEqualToString:existingClientTag.value])) {
                [logger info:@"Tag exists with the same value. (tagId: %@, value: %@)", fullTagId, value];
                return;
            }
            [logger info:@"Tag exists with the other value. (tagId: %@, value: %@)", fullTagId, value];
        }

        GAClientTag *clientTag = [GAClientTag createWithClientId:[[[GrowthbeatCore sharedInstance] waitClient] id] tagId:fullTagId value:value credentialId:credentialId];
        if (clientTag) {
            [GAClientTag save:clientTag];
            [logger info:@"Setting tag success. (tagId: %@)", fullTagId];
        }

        if (complete) {
            complete(clientTag);
        }

    });

}

- (void) tag:(NSString *)lastId {
    [self tag:@"Custom" tagId:lastId value:nil];
}
- (void) tag:(NSString *)lastId value:(NSString *)value {
    [self tag:@"Custom" tagId:lastId value:value];
}

- (void) open {
    openTime = [NSDate date];
    [self track:@"Default" eventId:@"Open" option:GATrackOptionCounter];
    [self track:@"Default" eventId:@"Install" option:GATrackOptionOnce];
}

- (void) close {

    if (!openTime) {
        return;
    }

    NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:openTime];
    openTime = nil;

    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    [properties setObject:[NSString stringWithFormat:@"%d", (int)time] forKey:@"time"];

    UIBackgroundTaskIdentifier __block backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self track:@"Default" eventId:@"Close" properties:properties option:GATrackOptionDefault complete:^(GAClientEvent *clientEvent) {
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }];
    });

}

- (void) purchase:(int)price setCategory:(NSString *)category setProduct:(NSString *)product {

    NSMutableDictionary *properties = [NSMutableDictionary dictionary];

    [properties setObject:[NSString stringWithFormat:@"%d", price] forKey:@"price"];
    if (category) {
        [properties setObject:category forKey:@"category"];
    }
    if (product) {
        [properties setObject:product forKey:@"product"];
    }

    [self track:@"Default" eventId:@"Purchase" properties:properties];

}

- (void) setUserId:(NSString *)userId {
    [self tag:@"Default" tagId:@"UserId" value:userId];
}

- (void) setName:(NSString *)name {
    [self tag:@"Default" tagId:@"Name" value:name];
}

- (void) setAge:(int)age {
    [self tag:@"Default" tagId:@"Age" value:[NSString stringWithFormat:@"%d", age]];
}

- (void) setGender:(GAGender)gender {
    switch (gender) {
        case GAGenderMale:
            [self tag:@"Default" tagId:@"Gender" value:@"male"];
            break;
        case GAGenderFemale:
            [self tag:@"Default" tagId:@"Gender" value:@"female"];
            break;
        default:
            break;
    }
}

- (void) setLevel:(int)level {
    [self tag:@"Default" tagId:@"Level" value:[NSString stringWithFormat:@"%d", level]];
}

- (void) setDevelopment:(BOOL)development {
    [self tag:@"Default" tagId:@"Development" value:development ? @"true" : @"false"];
}

- (void) setDeviceModel {
    [self tag:@"Default" tagId:@"DeviceModel" value:[GBDeviceUtils model]];
}

- (void) setOS {
    [self tag:@"Default" tagId:@"OS" value:[GBDeviceUtils os]];
}

- (void) setLanguage {
    [self tag:@"Default" tagId:@"Language" value:[GBDeviceUtils language]];
}

- (void) setTimeZone {
    [self tag:@"Default" tagId:@"TimeZone" value:[GBDeviceUtils timeZone]];
}

- (void) setTimeZoneOffset {
    [self tag:@"Default" tagId:@"TimeZoneOffset" value:[NSString stringWithFormat:@"%ld", (long)[GBDeviceUtils timeZoneOffset]]];
}

- (void) setAppVersion {
    [self tag:@"Default" tagId:@"AppVersion" value:[GBDeviceUtils version]];
}

- (void) setRandom {
    double random = (double)arc4random() / ARC4RANDOM_MAX;

    [self tag:@"Default" tagId:@"Random" value:[NSString stringWithFormat:@"%lf", random]];
}

- (void) setAdvertisingId {
    ASIdentifierManager *identifierManager = [ASIdentifierManager sharedManager];
    if ([identifierManager isAdvertisingTrackingEnabled]) {
        [self tag:@"Default" tagId:@"AdvertisingID" value:identifierManager.advertisingIdentifier.UUIDString];
    }
}

- (void) setBasicTags {
    [self setDeviceModel];
    [self setOS];
    [self setLanguage];
    [self setTimeZone];
    [self setTimeZoneOffset];
    [self setAppVersion];
    [self setAdvertisingId];
}

- (NSString *) generateEventId:(NSString *)namespace name:(NSString *)name {
    return [NSString stringWithFormat:@"Event:%@:%@:%@", applicationId, namespace, name];
}

- (NSString *) generateTagId:(NSString *)namespace name:(NSString *)name {
    return [NSString stringWithFormat:@"Tag:%@:%@:%@", applicationId, namespace, name];
}

@end
