//
//  GATrackEventOption.h
//  GrowthAnalytics
//
//  Created by A13048 on 2014/11/19.
//  Copyright (c) 2014年 SIROK, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS (NSInteger, EGPOption) {
    GATrackEventOptionDefault = 0,
    GATrackEventOptionOnce = 1 << 0,
    GATrackEventOptionMarkFirstTime = 1 << 1,
    GATrackEventOptionMarkFirstTimeAndOnce = GATrackEventOptionOnce | GATrackEventOptionMarkFirstTime,
};
