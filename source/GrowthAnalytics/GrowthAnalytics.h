//
//  GrowthAnalytics.h
//  GrowthAnalytics
//
//  Created by Kataoka Naoyuki on 2014/11/06.
//  Copyright (c) 2014年 SIROK, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GrowthbeatCore.h"
#import "GAEventHandler.h"
#import "GAClientEvent.h"
#import "GAClientTag.h"

typedef NS_ENUM (NSInteger, GATrackOption) {
    GATrackOptionDefault = 0,
    GATrackOptionOnce,
    GATrackOptionCounter
};

typedef NS_ENUM (NSInteger, GAGender) {
    GAGenderNone = 0,
    GAGenderMale,
    GAGenderFemale
};

@interface GrowthAnalytics : NSObject

+ (instancetype)sharedInstance;

- (void)initializeWithApplicationId:(NSString *)applicationId credentialId:(NSString *)credentialId;

- (void)track:(NSString *)namespace eventId:(NSString *)eventId;
- (void)track:(NSString *)namespace eventId:(NSString *)eventId properties:(NSDictionary *)properties;
- (void)track:(NSString *)namespace eventId:(NSString *)eventId option:(GATrackOption)option;
- (void)track:(NSString *)namespace eventId:(NSString *)eventId properties:(NSDictionary *)properties option:(GATrackOption)option complete:(void(^)(GAClientEvent * clientEvent))complete;

- (void)track:(NSString *)lastId;
- (void)track:(NSString *)lastId properties:(NSDictionary *)properties;
- (void)track:(NSString *)lastId option:(GATrackOption)option;
- (void)track:(NSString *)lastId properties:(NSDictionary *)properties option:(GATrackOption)option;

- (void)addEventHandler:(GAEventHandler *)eventHandler;

- (void)tag:(NSString *)namespace tagId:(NSString *)tagId value:(NSString *)value;
- (void)tag:(NSString *)namespace tagId:(NSString *)tagId value:(NSString *)value complete:(void(^)(GAClientTag * clientTag))complete;

- (void)tag:(NSString *)lastId;
- (void)tag:(NSString *)lastId value:(NSString *)value;

- (void)open;
- (void)close;
- (void)purchase:(int)price setCategory:(NSString *)category setProduct:(NSString *)product;

- (void)setUserId:(NSString *)userId;
- (void)setName:(NSString *)name;
- (void)setAge:(int)age;
- (void)setGender:(GAGender)gender;
- (void)setLevel:(int)level;
- (void)setDevelopment:(BOOL)development;
- (void)setDeviceModel;
- (void)setOS;
- (void)setLanguage;
- (void)setTimeZone;
- (void)setTimeZoneOffset;
- (void)setAppVersion;
- (void)setRandom;
- (void)setAdvertisingId;
- (void)setBasicTags;

- (GBLogger *)logger;
- (GBHttpClient *)httpClient;
- (GBPreference *)preference;

@end
