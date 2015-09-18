#import <UIKit/UIKit.h>

%hook UIApplication
-(BOOL) openURL:(NSURL*)url
{
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.elijahandandrew.multiplexer.tutorial.open_settings"), nil, nil, YES);
	return YES;
}
%end

void open_settings(CFNotificationCenterRef a, void *b, CFStringRef c, const void *d, CFDictionaryRef e)
{
	[UIApplication.sharedApplication openURL:[NSURL URLWithString:@"prefs:root=Multiplexer"]];
}

%ctor
{
	if ([NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"])
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, open_settings, CFSTR("com.elijahandandrew.multiplexer.tutorial.open_settings"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    else
    	%init;
}