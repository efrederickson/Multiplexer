#import <UIKit/UIKit.h>
#import <substrate.h>
#import <SpringBoard/SBApplication.h>
#include <mach/mach.h>
#include <libkern/OSCacheControl.h>
#include <stdbool.h>
#include <dlfcn.h>
#include <sys/sysctl.h>
#import <notify.h>

#import "headers.h"
#import "RAWidgetSectionManager.h"
#import "RASettings.h"
#import "RASwipeOverManager.h"

#define SPRINGBOARD ([NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"])

%hook SBUIController
- (_Bool)clickedMenuButton
{
	if ([RASwipeOverManager.sharedInstance isUsingSwipeOver])
	{
		[RASwipeOverManager.sharedInstance stopUsingSwipeOver];
		return YES;
	}
    if ([RASettings.sharedInstance homeButtonClosesReachability] && [[%c(SBWorkspace) sharedInstance] isUsingReachApp] && ((SBReachabilityManager*)[%c(SBReachabilityManager) sharedInstance]).reachabilityModeActive)
    {
        [[%c(SBReachabilityManager) sharedInstance] _handleReachabilityDeactivated];
        return YES;
    }
    return %orig;
}
%end

void reloadSettings(CFNotificationCenterRef center,
                    void *observer,
                    CFStringRef name,
                    const void *object,
                    CFDictionaryRef userInfo)
{
    [RASettings.sharedInstance reloadSettings];
}

%ctor
{
    if (SPRINGBOARD)
    {
        %init;
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &reloadSettings, CFSTR("com.efrederickson.reachapp.settings/reloadSettings"), NULL, 0);
        reloadSettings(NULL, NULL, NULL, NULL, NULL);
    }
}