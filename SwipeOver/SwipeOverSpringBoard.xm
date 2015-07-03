#import "RASwipeOverManager.h"

void resizeEdgeView(CFNotificationCenterRef center,
                    void *observer,
                    CFStringRef name,
                    const void *object,
                    CFDictionaryRef userInfo)
{
	if (![RASwipeOverManager.sharedInstance isUsingSwipeOver])
		[RASwipeOverManager.sharedInstance startUsingSwipeOver];

	NSDictionary *d = (__bridge NSDictionary*)userInfo;
	[RASwipeOverManager.sharedInstance sizeViewForTranslation:CGPointFromString(d[@"point"]) state:[d[@"state"] intValue]];
}

%ctor
{
	if ([NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"])
	{
		CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, resizeEdgeView, CFSTR("com.efrederickson.reachapp.resize.edgeswipeview"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	}
}