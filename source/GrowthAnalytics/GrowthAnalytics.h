//
//  GrowthAnalytics.h
//  GrowthAnalytics
//
//  Created by Kataoka Naoyuki on 2014/11/06.
//  Copyright (c) 2014年 SIROK, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GrowthbeatCore.h"
#import "GATrackOption.h"

@interface GrowthAnalytics : NSObject

/**
 * Get shared instance of GrowthAnalytics
 *
 */
+ (GrowthAnalytics *) sharedInstance;

/**
 * Initialize GrowthAnalytics instance
 *
 * @param applicationId Application ID
 * @param credentialId Credential ID for the application
 */
- (void)initializeWithApplicationId:(NSString *)applicationId credentialId:(NSString *)credentialId;

/**
 * Track event
 *
 * @param eventId Event ID
 * @param properties properties for the tracking
 */
- (void)track:(NSString *)eventId;
- (void)track:(NSString *)eventId properties:(NSDictionary *)properties;
- (void)track:(NSString *)eventId option:(GATrackOption)option;
- (void)track:(NSString *)eventId properties:(NSDictionary *)properties option:(GATrackOption)option;

/**
 * Set tag
 *
 * @param tagId Tag ID
 * @param value value for the tag
 */
- (void)tag:(NSString *)tagId value:(NSString *)value;

- (void)setUserId:(NSString *)userId;
- (void)setAdvertisingId:(NSString *)idfa;
- (void)setGender:(NSString *)gender;
- (void)setLebel:(NSString *)level;
- (void)setName:(NSString *)name;
- (void)setLanguage:(NSString *)language;
- (void)setLocale:(NSString *)locale;
- (void)setOS:(NSString *)os;
- (void)setTimeZone:(NSString *)timezone;
- (void)setAppVersion:(NSString *)appVersion;
- (void)setDevelopment;

- (void)open;
- (void)close;
- (void)purchase:(NSInteger)price setCategory:(NSString *)category setProduct:(NSString *)product;

- (void) setDeviceTags;

- (GBLogger *)logger;
- (GBHttpClient *)httpClient;
- (GBPreference *)preference;

@end
