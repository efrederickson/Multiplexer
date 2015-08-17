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

    if (RAMissionControlManager.sharedInstance.isShowingMissionControl)
    {
        [RAMissionControlManager.sharedInstance hideMissionControl:YES];
        return YES;
    }

    return %orig;
}

- (_Bool)handleMenuDoubleTap
{
    if ([RASwipeOverManager.sharedInstance isUsingSwipeOver])
    {
        [RASwipeOverManager.sharedInstance stopUsingSwipeOver];
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
    [RADesktopManager.sharedInstance currentDesktop]; // load desktop (and previous windows!)
}
%end

%hook SBApplicationController
%new -(SBApplication*) RA_applicationWithBundleIdentifier:(NSString*)bundleIdentifier
{
    if ([self respondsToSelector:@selector(applicationWithBundleIdentifier:)])
        return [self applicationWithBundleIdentifier:bundleIdentifier];
    else if ([self respondsToSelector:@selector(applicationWithDisplayIdentifier:)])
        return [self applicationWithDisplayIdentifier:bundleIdentifier];

    [RACompatibilitySystem showWarning:@"Unable to find valid -[SBApplicationController applicationWithBundleIdentifier:] replacement"];
    return nil;
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

/*
%hook SpringBoard
-(void)noteInterfaceOrientationChanged:(int)arg1 duration:(float)arg2
{
    if ([RASwipeOverManager.sharedInstance isUsingSwipeOver])
        [RASwipeOverManager.sharedInstance stopUsingSwipeOver];

    %orig;
}
%end
*/

%ctor
{
    if (SPRINGBOARD)
    {
        %init;
        LOAD_ASPHALEIA;
    }
}
