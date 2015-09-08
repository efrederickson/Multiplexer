#import <UIKit/UIKit.h>
#import <substrate.h>
#import <SpringBoard/SBApplication.h>
#include <mach/mach.h>
#include <libkern/OSCacheControl.h>
#include <stdbool.h>
#include <dlfcn.h>
#include <sys/sysctl.h>
#import <notify.h>
#import "RACompatibilitySystem.h"
#import "headers.h"
#import "RAWidgetSectionManager.h"
#import "RASettings.h"
#import "RASwipeOverManager.h"
#import "RAMissionControlManager.h"
#import "RADesktopManager.h"
#import "RADesktopWindow.h"
#import "Asphaleia2.h"
#import "RASnapshotProvider.h"

#define SPRINGBOARD ([NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"])

%hook SBUIController
- (_Bool)clickedMenuButton
{
	if ([[%c(RASwipeOverManager) sharedInstance] isUsingSwipeOver])
	{
		[[%c(RASwipeOverManager) sharedInstance] stopUsingSwipeOver];
		return YES;
	}

    if ([RASettings.sharedInstance homeButtonClosesReachability] && [[%c(SBWorkspace) sharedInstance] isUsingReachApp] && ((SBReachabilityManager*)[%c(SBReachabilityManager) sharedInstance]).reachabilityModeActive)
    {
        [[%c(SBReachabilityManager) sharedInstance] _handleReachabilityDeactivated];
        return YES;
    }

    if ([[%c(RAMissionControlManager) sharedInstance] isShowingMissionControl])
    {
        [[%c(RAMissionControlManager) sharedInstance] hideMissionControl:YES];
        return YES;
    }

    return %orig;
}

- (_Bool)handleMenuDoubleTap
{
    if ([[%c(RASwipeOverManager) sharedInstance] isUsingSwipeOver])
    {
        [[%c(RASwipeOverManager) sharedInstance] stopUsingSwipeOver];
    }

    //if (RAMissionControlManager.sharedInstance.isShowingMissionControl)
    //{
    //    [RAMissionControlManager.sharedInstance hideMissionControl:YES];
    //}

    return %orig;
}
%end

%hook SpringBoard
-(void) _performDeferredLaunchWork
{
    %orig;
    [RADesktopManager sharedInstance]; // load desktop (and previous windows!)

    // No applications show in the mission control until they have been launched by the user.
    // This prevents always-running apps like Mail or Pebble from perpetually showing in Mission Control.
    [[%c(RAMissionControlManager) sharedInstance] setInhibitedApplications:[[[%c(SBIconViewMap) homescreenMap] iconModel] visibleIconIdentifiers]];
}
%end

%hook SBApplicationController
%new -(SBApplication*) RA_applicationWithBundleIdentifier:(__unsafe_unretained NSString*)bundleIdentifier
{
    if ([self respondsToSelector:@selector(applicationWithBundleIdentifier:)])
        return [self applicationWithBundleIdentifier:bundleIdentifier];
    else if ([self respondsToSelector:@selector(applicationWithDisplayIdentifier:)])
        return [self applicationWithDisplayIdentifier:bundleIdentifier];

    [RACompatibilitySystem showWarning:@"Unable to find valid -[SBApplicationController applicationWithBundleIdentifier:] replacement"];
    return nil;
}
%end

%hook SBToAppsWorkspaceTransaction
- (void)_willBegin
{
    @autoreleasepool {
        NSArray *apps = [MSHookIvar<NSArray*>(self, "_toApplications") copy];
        for (SBApplication *app in apps)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [RADesktopManager.sharedInstance removeAppWithIdentifier:app.bundleIdentifier animated:NO forceImmediateUnload:YES];
            });
        }
    }
    %orig;
}

-(void)_didComplete
{
    %orig;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        [RAHostedAppView iPad_iOS83_fixHosting];
}
%end

/*
%hook SBRootFolderView
- (_Bool)_hasMinusPages 
{
    return RADesktopManager.sharedInstance.currentDesktop.hostedWindows.count > 0 ? YES : %orig; 
}
- (unsigned long long)_minusPageCount 
{
    return RADesktopManager.sharedInstance.currentDesktop.hostedWindows.count > 0 ? 1 : %orig; 
}
%end
*/

%hook SpringBoard
-(void)noteInterfaceOrientationChanged:(int)arg1 duration:(float)arg2
{
    %orig;
    [RASnapshotProvider.sharedInstance forceReloadEverything];
}
%end

%hook SBApplication
- (void)didActivateWithTransactionID:(unsigned long long)arg1
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[%c(RAMissionControlManager) sharedInstance] uninhibitApplication:self.bundleIdentifier];
        [RASnapshotProvider.sharedInstance forceReloadOfSnapshotForIdentifier:self.bundleIdentifier];
    });
        
    %orig;
}
%end

%hook SBLockStateAggregator
-(void) _updateLockState
{
    %orig;
    
    if ([self hasAnyLockState])
    {
        if ([[%c(RASwipeOverManager) sharedInstance] isUsingSwipeOver])
            [[%c(RASwipeOverManager) sharedInstance] stopUsingSwipeOver];
    }
}
%end

void respring_notification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    [[UIApplication sharedApplication] _relaunchSpringBoardNow];
}

void reset_settings_notification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    [RASettings.sharedInstance resetSettings];
}

%ctor
{
    if (SPRINGBOARD)
    {
        %init;
        LOAD_ASPHALEIA;

        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, respring_notification, CFSTR("com.efrederickson.reachapp.respring"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, reset_settings_notification, CFSTR("com.efrederickson.reachapp.resetSettings"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    }
}
