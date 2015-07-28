#import "headers.h"
#import "RAKeyboardWindow.h"

extern BOOL overrideDisableForStatusBar;
RAKeyboardWindow *keyboardWindow;
NSString *bundleIdentifierThatWantsKeyboard;

void handleKeyboardNeeds(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	NSDictionary *d = (__bridge NSDictionary*)userInfo;
	BOOL wantsKeyboard = [d[@"wantsKeyboard"] boolValue];
	NSString *bundleIdentifier = d[@"bundleIdentifier"];

	if (bundleIdentifierThatWantsKeyboard && [bundleIdentifierThatWantsKeyboard isEqual:bundleIdentifier] == NO)
	{
		NSLog(@"[ReachApp] invalid bundleIdentifier '%@' for keyboard needs update, expected '%@'; and it wanted state '%@'", bundleIdentifier, bundleIdentifierThatWantsKeyboard, wantsKeyboard ? @"YES" : @"NO");
		return;
	}

	if (wantsKeyboard)
	{
		//NSLog(@"[ReachApp] showing keyboard");
		keyboardWindow = [[RAKeyboardWindow alloc] init];
		overrideDisableForStatusBar = YES;
    	[keyboardWindow setupForKeyboardAndShow];
    	overrideDisableForStatusBar = NO;
    	bundleIdentifierThatWantsKeyboard = bundleIdentifier;
	}
	else
	{
		//NSLog(@"[ReachApp] resigning keyboard");
		[keyboardWindow resignKeyboard];
		keyboardWindow = nil;
		bundleIdentifierThatWantsKeyboard = nil;
	}
}

%ctor
{
	if ([NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"])
	{
		CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, handleKeyboardNeeds, CFSTR("com.efrederickson.reachapp.updateKeyboardWindow"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	}
}