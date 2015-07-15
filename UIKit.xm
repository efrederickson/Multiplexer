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

#define SPRINGBOARD ([NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"])

BOOL overrideDisplay = NO;
CGFloat overrideHeight = -1;
CGFloat overrideWidth = -1;
BOOL overrideViewControllerDismissal = NO;
UIInterfaceOrientation forcedOrientation;
UIInterfaceOrientation prevousOrientation;
BOOL forcingRotation = NO;
BOOL setPreviousOrientation = NO;
BOOL isTopApp = NO;
NSInteger wasStatusBarHidden = -1;

NSMutableDictionary *oldFrames = [NSMutableDictionary new];

%hook UIWindow
-(void) setFrame:(CGRect) frame
{
    if (overrideDisplay && (overrideWidth != -1 || overrideHeight != -1))
    {
        if ([oldFrames objectForKey:@(self.hash)] == nil)
            [oldFrames setObject:[NSValue valueWithCGRect:frame] forKey:@(self.hash)];

        frame.origin.x = 0;
        frame.origin.y = 0;
        if (overrideWidth != -1)
            frame.size.width = overrideWidth;
        if (overrideHeight != -1)
            frame.size.height = overrideHeight;
    }

    %orig(frame);
}

- (void)_rotateWindowToOrientation:(int)arg1 updateStatusBar:(BOOL)arg2 duration:(double)arg3 skipCallbacks:(BOOL)arg4
{
    if (overrideDisplay && forcingRotation == NO)
        return;
    %orig;
}

- (BOOL)_shouldAutorotateToInterfaceOrientation:(int)arg1 checkForDismissal:(BOOL)arg2 isRotationDisabled:(BOOL*)arg3
{
    if (overrideDisplay && forcingRotation == NO)
        return NO;
    return %orig;
}

- (void)_setWindowInterfaceOrientation:(int)arg1
{
    if (overrideDisplay) 
        return;
    %orig(overrideDisplay ? forcedOrientation : arg1);
}

- (void)makeKeyAndVisible
{
    overrideViewControllerDismissal = YES;
    %orig;
    overrideViewControllerDismissal = NO;
}
%end

%hook UIApplication

- (void)_setStatusBarHidden:(BOOL)arg1 animationParameters:(id)arg2 changeApplicationFlag:(BOOL)arg3
{
	if ([RASettings.sharedInstance unifyStatusBar])
	    arg1 = ((forcingRotation&&NO) || overrideDisplay) ? (isTopApp ? NO : YES) : arg1;
    %orig(arg1, arg2, YES);
}

/*
- (void)_notifySpringBoardOfStatusBarOrientationChangeAndFenceWithAnimationDuration:(double)arg1
{
    if (overrideViewControllerDismissal)
        return;
    %orig;
}
*/

- (void)_deactivateReachability
{
    if (overrideViewControllerDismissal)
        return;
    %orig;
}

%new - (void)RA_forceRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation isReverting:(BOOL)reverting
{
    //NSLog(@"ReachApp: RA_forceRotationToInterfaceOrientation %@", @(orientation));
    forcingRotation = YES;

    if (!reverting)
    {
        if (setPreviousOrientation == NO)
        {
            setPreviousOrientation = YES;
            prevousOrientation = UIApplication.sharedApplication.statusBarOrientation;
            wasStatusBarHidden = UIApplication.sharedApplication.statusBarHidden;
        }
        forcedOrientation = orientation;
    }

    for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
        [window _setRotatableViewOrientation:orientation updateStatusBar:YES duration:0.25 force:YES];
    }

    forcingRotation = NO;
}
%end

%hook UIViewController
- (void)_presentViewController:(__unsafe_unretained id)viewController withAnimationController:(__unsafe_unretained id)animationController completion:(__unsafe_unretained id)completion
{
    overrideViewControllerDismissal = YES;
    %orig;
    overrideViewControllerDismissal = NO;
}

- (void)dismissViewControllerWithTransition:(__unsafe_unretained id)transition completion:(__unsafe_unretained id)completion
{
    overrideViewControllerDismissal = YES;
    %orig;
    overrideViewControllerDismissal = NO;
}
%end

%hook UINavigationController
- (void)pushViewController:(__unsafe_unretained id)viewController transition:(__unsafe_unretained id)transition forceImmediate:(BOOL)immediate
{
    overrideViewControllerDismissal = YES;
    %orig;
    overrideViewControllerDismissal = NO;
}

- (id)_popViewControllerWithTransition:(__unsafe_unretained id)transition allowPoppingLast:(BOOL)last
{
    overrideViewControllerDismissal = YES;
    id r = %orig;
    overrideViewControllerDismissal = NO;
    return r;
}

- (void)_popViewControllerAndUpdateInterfaceOrientationAnimated:(BOOL)animated
{
    overrideViewControllerDismissal = YES;
    %orig;
    overrideViewControllerDismissal = NO;
}
%end

%hook UIInputWindowController 
- (void)moveFromPlacement:(__unsafe_unretained id)arg1 toPlacement:(__unsafe_unretained id)arg2 starting:(__unsafe_unretained id)arg3 completion:(__unsafe_unretained id)arg4
{
    overrideViewControllerDismissal = YES;
    %orig;
    overrideViewControllerDismissal = NO;
}
%end

void forceRotation_right(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
    if ([NSBundle.mainBundle.bundleIdentifier isEqual:[(__bridge NSDictionary*)userInfo objectForKey:@"bundleIdentifier"]] == NO)
        return;
    UIInterfaceOrientation newOrientation = UIInterfaceOrientationLandscapeRight;
    [[UIApplication sharedApplication] RA_forceRotationToInterfaceOrientation:newOrientation isReverting:NO];
}
void forceRotation_left(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
    if ([NSBundle.mainBundle.bundleIdentifier isEqual:[(__bridge NSDictionary*)userInfo objectForKey:@"bundleIdentifier"]] == NO)
        return;
    UIInterfaceOrientation newOrientation = UIInterfaceOrientationLandscapeLeft;
    [[UIApplication sharedApplication] RA_forceRotationToInterfaceOrientation:newOrientation isReverting:NO];
}
void forceRotation_portrait(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
    if ([NSBundle.mainBundle.bundleIdentifier isEqual:[(__bridge NSDictionary*)userInfo objectForKey:@"bundleIdentifier"]] == NO)
        return;
    UIInterfaceOrientation newOrientation = UIInterfaceOrientationPortrait;
    [[UIApplication sharedApplication] RA_forceRotationToInterfaceOrientation:newOrientation isReverting:NO];
}
void forceRotation_upsidedown(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
    if ([NSBundle.mainBundle.bundleIdentifier isEqual:[(__bridge NSDictionary*)userInfo objectForKey:@"bundleIdentifier"]] == NO)
        return;
    UIInterfaceOrientation newOrientation = UIInterfaceOrientationPortraitUpsideDown;
    [[UIApplication sharedApplication] RA_forceRotationToInterfaceOrientation:newOrientation isReverting:NO];
}

BOOL inapp_ScalingRotationMode = NO;

void updateStatusBarHidden(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
    NSDictionary *info = (__bridge NSDictionary*)userInfo;
    BOOL hideSB = info[@"hideStatusBar"] ? [info[@"hideStatusBar"] boolValue] : NO;
    if ([NSBundle.mainBundle.bundleIdentifier isEqual:[info objectForKey:@"bundleIdentifier"]])
    {
        if (hideSB)
        {
            if (wasStatusBarHidden == -1)
                wasStatusBarHidden = UIApplication.sharedApplication.statusBarHidden;
            [UIApplication.sharedApplication _setStatusBarHidden:YES animationParameters:nil changeApplicationFlag:YES];
        }
        else
            [UIApplication.sharedApplication _setStatusBarHidden:NO animationParameters:nil changeApplicationFlag:YES];
    }
}

void forceResizing(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
    NSDictionary *info = (__bridge NSDictionary*)userInfo;
    BOOL hideStatusBarIfWanted = info[@"hideStatusBarIfWanted"] ? [info[@"hideStatusBarIfWanted"] boolValue] : YES;
    if ([NSBundle.mainBundle.bundleIdentifier isEqual:[info objectForKey:@"bundleIdentifier"]])
    {
        isTopApp = [[info objectForKey:@"isTopApp"] boolValue];

        if (wasStatusBarHidden == -1 && [RASettings.sharedInstance unifyStatusBar] && hideStatusBarIfWanted)
        {
            wasStatusBarHidden = UIApplication.sharedApplication.statusBarHidden;
            [UIApplication.sharedApplication _setStatusBarHidden:!isTopApp animationParameters:nil changeApplicationFlag:YES];
        }

        inapp_ScalingRotationMode = [[info objectForKey:@"rotationMode"] boolValue];
        if (!inapp_ScalingRotationMode)
        {
            overrideHeight = [[info objectForKey:@"sizeHeight"] floatValue];
            overrideWidth = [[info objectForKey:@"sizeWidth"] floatValue];
        }
        overrideDisplay = YES;


        if (!inapp_ScalingRotationMode)
        {
            if (overrideWidth != -1)
            {
                if ([oldFrames objectForKey:@"statusBar"] == nil)
                    [oldFrames setObject:[NSValue valueWithCGRect:UIApplication.sharedApplication.statusBar.frame] forKey:@"statusBar"];
            	UIApplication.sharedApplication.statusBar.frame = CGRectMake(0, 0, overrideWidth, UIApplication.sharedApplication.statusBar.frame.size.height);
            }
            for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
                if ([oldFrames objectForKey:@(window.hash)] == nil)
                {
                    //NSLog(@"ReachApp: storing frame %@ for rotation %@", NSStringFromCGRect(window.frame), @(UIApplication.sharedApplication.statusBarOrientation));
                    [oldFrames setObject:[NSValue valueWithCGRect:window.frame] forKey:@(window.hash)];
                }
                [UIView animateWithDuration:0.3 animations:^{
                    [window setFrame:window.frame];
                }];
            }
            //((UIView*)[UIKeyboard activeKeyboard]).frame = ((UIView*)[UIKeyboard activeKeyboard]).frame;
        }
    }
}

void endForceResizing(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
    if ([NSBundle.mainBundle.bundleIdentifier isEqual:[(__bridge NSDictionary*)userInfo objectForKey:@"bundleIdentifier"]])
    {
        overrideDisplay = NO;

        if (!inapp_ScalingRotationMode)
        {
            for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
                CGRect frame = window.frame;
                if ([oldFrames objectForKey:@(window.hash)] != nil)
                {
                    frame = [[oldFrames objectForKey:@(window.hash)] CGRectValue];
                    [oldFrames removeObjectForKey:@(window.hash)];
                    //frame.origin.x = 0;
                    //frame.origin.y = 0;
                }
                //NSLog(@"ReachApp: restoring frame %@ for rotation %@", NSStringFromCGRect(frame), @(UIApplication.sharedApplication.statusBarOrientation));
                [UIView animateWithDuration:0.4 animations:^{
                    [window setFrame:frame];
                }];
            }
            if ([oldFrames objectForKey:@"statusBar"] != nil)
                UIApplication.sharedApplication.statusBar.frame = [oldFrames[@"statusBar"] CGRectValue];
        }

        if (setPreviousOrientation)
            [[UIApplication sharedApplication] RA_forceRotationToInterfaceOrientation:prevousOrientation isReverting:YES];
        setPreviousOrientation = NO;
        if (wasStatusBarHidden != -1 && [RASettings.sharedInstance unifyStatusBar])
            [UIApplication.sharedApplication _setStatusBarHidden:wasStatusBarHidden animationParameters:nil changeApplicationFlag:YES];
           wasStatusBarHidden = -1;
    }
}

%ctor
{
    if (!SPRINGBOARD)
    {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, forceRotation_right, CFSTR("com.efrederickson.reachapp.forcerotation-right"), NULL, CFNotificationSuspensionBehaviorDrop);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, forceRotation_left, CFSTR("com.efrederickson.reachapp.forcerotation-left"), NULL, CFNotificationSuspensionBehaviorDrop);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, forceRotation_portrait, CFSTR("com.efrederickson.reachapp.forcerotation-portrait"), NULL, CFNotificationSuspensionBehaviorDrop);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, forceRotation_upsidedown, CFSTR("com.efrederickson.reachapp.forcerotation-upsidedown"), NULL, CFNotificationSuspensionBehaviorDrop);
        
        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, updateStatusBarHidden, CFSTR("com.efrederickson.reachapp.updateStatusBar"), NULL, CFNotificationSuspensionBehaviorCoalesce);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, forceResizing, CFSTR("com.efrederickson.reachapp.beginresizing"), NULL, CFNotificationSuspensionBehaviorCoalesce);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, endForceResizing, CFSTR("com.efrederickson.reachapp.endresizing"), NULL, CFNotificationSuspensionBehaviorDrop);
    }
    %init;
}