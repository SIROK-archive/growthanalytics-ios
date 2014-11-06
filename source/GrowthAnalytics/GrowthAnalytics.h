//
//  GrowthAnalytics.h
//  GrowthAnalytics
//
//  Created by Kataoka Naoyuki on 2014/11/06.
//  Copyright (c) 2014年 SIROK, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GrowthbeatCore.h"

//! Project version number for GrowthAnalytics.
FOUNDATION_EXPORT double GrowthAnalyticsVersionNumber;

//! Project version string for GrowthAnalytics.
FOUNDATION_EXPORT const unsigned char GrowthAnalyticsVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <GrowthAnalytics/PublicHeader.h>


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
- (void)trackEvent:(NSString *)eventId properties:(NSDictionary *)properties;

/**
 * Set tag
 *
 * @param tagId Tag ID
 * @param value value for the tag
 */
- (void)setTag:(NSString *)tagId value:(NSString *)value;

@end

