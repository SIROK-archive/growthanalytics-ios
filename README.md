# Growth Analytics SDK for iOS

[Growth Analytics](https://analytics.growthbeat.com/) is analytics service for mobile apps.

## Usage 

1. Install [Growthbeat Core SDK](https://github.com/SIROK/growthbeat-core-ios).

1. Add GrowthbeatAnalytics.framework into your project. 

1. Import the framework header.

	```objc
	#import <GrowthbeatAnalytics/GrowthbeatAnalytics.h>
	```

1. Write initialization code

	```objc
	[[GrowthbeatAnalytics sharedInstance] initializeWithApplicationId:@"APPLICATION_ID" credentialId:@"CREDENTIAL_ID"];
	```

1. Write following code in AppDelegate's applicationDidBecomeActive:

	```objc
	[[GrowthAnalytics sharedInstance] open];
	[[GrowthAnalytics sharedInstance] setBasicTags];
	```

1. Write following code in AppDelegate's applicationWillResignActive:

	```objc
	[[GrowthAnalytics sharedInstance] close];
	```

1. You can track custom event with following code.

	```objc
	[[GrowthAnalytics sharedInstance] track:@"EVENT_NAME" properties:ADDITIONAL_PROPERTIES];
	```

1. You can set custom tag with following code.

	```objc
	[[GrowthAnalytics sharedInstance] tag:@"TAG_NAME" value:@"TAG_VALUE"];
	```
	
## Growthbeat Full SDK

You can use Growthbeat SDK instead of this SDK. Growthbeat is growth hack tool for mobile apps. You can use full functions include Growth Push when you use the following SDK.

* [Growthbeat SDK for iOS](https://github.com/SIROK/growthbeat-ios/)
* [Growthbeat SDK for Android](https://github.com/SIROK/growthbeat-android/)

# Building framework

1. Set build target to GrowthAnalyticsFramework and iOS Device.
1. Run.

## License

Apache License, Version 2.0
