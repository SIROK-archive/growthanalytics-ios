//
//  AppDelegate.m
//  GrowthAnalyticsSample
//
//  Created by Kataoka Naoyuki on 2014/11/06.
//  Copyright (c) 2014年 SIROK, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import <AdSupport/AdSupport.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [[GrowthAnalytics sharedInstance] initializeWithApplicationId:@"OyTg8vZd4KTNQDJ5" credentialId:@"3EKydeJ0imxJ5WqS22FJfdVamFLgu7XA"];
    
    [[GrowthAnalytics sharedInstance] addEventHandler:[[GAEventHandler alloc] initWithCallback:^(NSString *eventId, NSDictionary *properties) {
        NSLog(@"EventHandler called. (eventId: %@, properties: %@)", eventId, properties);
    }]];

    ASIdentifierManager *identifierManager = [ASIdentifierManager sharedManager];
    if ([identifierManager isAdvertisingTrackingEnabled]) {
        [[GrowthAnalytics sharedInstance] setAdvertisingId:identifierManager.advertisingIdentifier.UUIDString];
    }

    return YES;
}

- (void) applicationDidBecomeActive:(UIApplication *)application {
    [[GrowthAnalytics sharedInstance] open];
}

- (void) applicationWillResignActive:(UIApplication *)application {
    [[GrowthAnalytics sharedInstance] close];
}

@end
