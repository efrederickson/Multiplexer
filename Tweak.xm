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
#import "RATouchGestureRecognizer.h"

/*
This code thanks: 
ForceReach: https://github.com/PoomSmart/ForceReach/
Reference: https://github.com/fewjative/Reference
MessageBox: https://github.com/b3ll/MessageBox
This pastie (by @Freerunnering?): http://pastie.org/pastes/8684110
Various tips and help: @sharedRoutine

Many concepts and ideas have been used from them.
*/


extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);
extern const char *__progname; 

/*FBWindowContextHostWrapperView*/ UIView *view = nil;
NSString *lastBundleIdentifier = @"";
NSString *currentBundleIdentifier = @"";
UIViewController *ncViewController = nil;
UIView *draggerView = nil;

BOOL overrideDisplay = NO;
CGFloat overrideHeight = -1;
CGFloat overrideWidth = -1;
BOOL overrideViewControllerDismissal = NO;
BOOL overrideOrientation = NO;
UIInterfaceOrientation forcedOrientation;
UIInterfaceOrientation prevousOrientation;
CGFloat grabberCenter_Y = -1;
CGPoint firstLocation = CGPointZero;
CGFloat grabberCenter_X = 0;
BOOL forcingRotation = NO;
BOOL showingNC = NO;
BOOL setPreviousOrientation = NO;
BOOL isTopApp = NO;
NSInteger wasStatusBarHidden = -1;
BOOL overrideDisableForStatusBar = NO;
CGRect pre_topAppFrame = CGRectZero;
CGAffineTransform pre_topAppTransform = CGAffineTransformIdentity;
UIView *bottomDraggerView = nil;
CGFloat old_grabberCenterY = -1;

%group springboardHooks
%hook SBReachabilityManager
+(BOOL)reachabilitySupported
{
	return YES; 
}

- (void)_handleReachabilityActivated
{
	overrideOrientation = YES;
	%orig;
	overrideOrientation = NO;
}

- (void)enableExpirationTimerForEndedInteraction
{
	if ((view || showingNC) && [RASettings.sharedInstance disableAutoDismiss])
		return;
	%orig;
}

- (void)_handleSignificantTimeChanged
{
	if ((view || showingNC) && [RASettings.sharedInstance disableAutoDismiss])
		return;
	%orig;
}

- (void)_keepAliveTimerFired:(id)arg1
{
	if ((view || showingNC) && [RASettings.sharedInstance disableAutoDismiss])
		return;
	%orig;
}

- (void)deactivateReachabilityModeForObserver:(id)arg1
{
	if (overrideDisableForStatusBar)
		return;
	%orig;
}

- (void)_handleReachabilityDeactivated
{
	if (overrideDisableForStatusBar)
		return;
	%orig;
}

- (void)_updateReachabilityModeActive:(_Bool)arg1 withRequestingObserver:(id)arg2
{
	if (overrideDisableForStatusBar)
		return;
	%orig;
}
%end

BOOL wasEnabled = NO;
id SBWorkspace$sharedInstance;
%hook SBWorkspace

%new + (id) sharedInstance
{
	return SBWorkspace$sharedInstance;
}

- (id) init
{
	SBWorkspace$sharedInstance = %orig;
	return SBWorkspace$sharedInstance;
}

- (void)_exitReachabilityModeWithCompletion:(id)arg1
{
	if (overrideDisableForStatusBar)
		return;

	%orig;
}

- (void)handleReachabilityModeDeactivated
{
	if (overrideDisableForStatusBar)
		return;

	%orig;
}

%new -(void) RA_closeCurrentView
{
	// Notify both top and bottom apps Reachability is closing
	if (lastBundleIdentifier)
		CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.endresizing"), NULL, (__bridge CFDictionaryRef)@{ @"bundleIdentifier": lastBundleIdentifier}, NO);
	if (currentBundleIdentifier)
		CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.endresizing"), NULL, (__bridge CFDictionaryRef)@{ @"bundleIdentifier": currentBundleIdentifier}, NO);

	if ([RASettings.sharedInstance showNCInstead])
	{
		showingNC = NO;
		UIWindow *window = MSHookIvar<UIWindow*>(self, "_reachabilityEffectWindow");
		[window _setRotatableViewOrientation:UIInterfaceOrientationPortrait updateStatusBar:YES duration:0.0 force:YES];
		window.rootViewController = nil;
		UIViewController *viewController = [[%c(SBNotificationCenterController) performSelector:@selector(sharedInstance)] performSelector:@selector(viewController)];
		[viewController performSelector:@selector(hostWillDismiss)];
		[viewController performSelector:@selector(hostDidDismiss)];
		//[viewController.view removeFromSuperview];
	}
	else
	{
		// Give them a little time to receive the notifications...
		if (view)
		{
			if ([view superview] != nil)
				[view removeFromSuperview];
		}
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			if (lastBundleIdentifier && lastBundleIdentifier.length > 0)
			{
				SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:lastBundleIdentifier];
				if (app && [app pid] && [app mainScene])
				{
					FBScene *scene = [app mainScene];
					FBSMutableSceneSettings *settings = [[scene mutableSettings] mutableCopy];
					object_setInstanceVariable(settings, "_backgrounded", (void*)YES);
					[scene _applyMutableSettings:settings withTransitionContext:nil completion:nil];
					MSHookIvar<FBWindowContextHostView*>([app mainScene].contextHostManager, "_hostView").frame = pre_topAppFrame;
					MSHookIvar<FBWindowContextHostView*>([app mainScene].contextHostManager, "_hostView").transform = pre_topAppTransform;

					SBApplication *currentApp = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:currentBundleIdentifier];
					if ([currentApp mainScene])
					{
						MSHookIvar<FBWindowContextHostView*>([currentApp mainScene].contextHostManager, "_hostView").frame = pre_topAppFrame;
						MSHookIvar<FBWindowContextHostView*>([currentApp mainScene].contextHostManager, "_hostView").transform = pre_topAppTransform;
					}

					FBWindowContextHostManager *contextHostManager = [scene contextHostManager];
					[contextHostManager disableHostingForRequester:@"reachapp"];
				}
			}
			view = nil;
		    lastBundleIdentifier = nil;
		});
	}
}

- (void)_disableReachabilityImmediately:(_Bool)arg1
{
	if (overrideDisableForStatusBar)
		return;

	if (![RASettings.sharedInstance enabled])
	{
		%orig;
		return;
	}

	if (arg1 && wasEnabled)
	{
		wasEnabled = NO;
		[self RA_closeCurrentView];
		if (draggerView)
			draggerView = nil;

	}

	%orig;
}

- (void) handleReachabilityModeActivated
{
	%orig;
	if (![RASettings.sharedInstance enabled])
		return;
	wasEnabled = YES;

	UIWindow *w = MSHookIvar<UIWindow*>(self, "_reachabilityEffectWindow");
	if ([RASettings.sharedInstance showNCInstead])
	{
		showingNC = YES;

		if (ncViewController == nil)
			ncViewController = [[%c(SBNotificationCenterViewController) alloc] init];
		ncViewController.view.frame = (CGRect) { { 0, 0 }, w.frame.size };
		w.rootViewController = ncViewController;
		[w addSubview:ncViewController.view];

		//[[%c(SBNotificationCenterController) performSelector:@selector(sharedInstance)] performSelector:@selector(_setupForViewPresentation)];
		[ncViewController performSelector:@selector(hostWillPresent)];
		[ncViewController performSelector:@selector(hostDidPresent)];

		if ([RASettings.sharedInstance enableRotation])
		{
        	[w _setRotatableViewOrientation:[UIApplication sharedApplication].statusBarOrientation updateStatusBar:YES duration:0.0 force:YES];
		}
	}
	else
	{
		currentBundleIdentifier = [[UIApplication sharedApplication] _accessibilityFrontMostApplication].bundleIdentifier;
		if (!currentBundleIdentifier)
			return;

		if ([RASettings.sharedInstance showWidgetSelector])
		{
			[self RA_showWidgetSelector];
		}
		else
		{
			SBApplication *app = nil;
			FBScene *scene = nil;
			NSMutableArray *bundleIdentifiers = [[%c(SBAppSwitcherModel) sharedInstance] snapshotOfFlattenedArrayOfAppIdentifiersWhichIsOnlyTemporary];
			while (scene == nil && bundleIdentifiers.count > 0)
			{
				lastBundleIdentifier = bundleIdentifiers[0];

				if ([lastBundleIdentifier isEqual:currentBundleIdentifier])
				{
					[bundleIdentifiers removeObjectAtIndex:0];
					continue;
				}

				app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:lastBundleIdentifier];
				scene = [app mainScene];
				if (!scene)
					if (bundleIdentifiers.count > 0)
						[bundleIdentifiers removeObjectAtIndex:0];
			}
			if (lastBundleIdentifier == nil || lastBundleIdentifier.length == 0)
				return;

			[self RA_launchTopAppWithIdentifier:lastBundleIdentifier];
		}
	}

	CGFloat knobWidth = 60;
	CGFloat knobHeight = 25;
	draggerView = [[UIView alloc] initWithFrame:CGRectMake(
		(UIScreen.mainScreen.bounds.size.width / 2) - (knobWidth / 2), 
		[UIScreen mainScreen].bounds.size.height * .3, 
		knobWidth, knobHeight)];
	draggerView.alpha = 0.3;
	draggerView.layer.cornerRadius = 10;
	grabberCenter_X = draggerView.center.x;

	draggerView.backgroundColor = UIColor.lightGrayColor;
	RATouchGestureRecognizer *recognizer = [[RATouchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
	if (grabberCenter_Y == -1)
		grabberCenter_Y = w.frame.size.height - (knobHeight / 2);
	if (grabberCenter_Y < 0)
		grabberCenter_Y = UIScreen.mainScreen.bounds.size.height * 0.3;
	draggerView.center = CGPointMake(grabberCenter_X, grabberCenter_Y);
	[draggerView addGestureRecognizer:recognizer];

	[w addSubview:draggerView];

	if ([RASettings.sharedInstance showBottomGrabber])
	{
		bottomDraggerView = [[UIView alloc] initWithFrame:CGRectMake(
			(UIScreen.mainScreen.bounds.size.width / 2) - (knobWidth / 2), 
			-(knobHeight / 2), 
			knobWidth, knobHeight)];
		bottomDraggerView.alpha = 0.3;
		bottomDraggerView.layer.cornerRadius = 10;
		bottomDraggerView.backgroundColor = UIColor.lightGrayColor;
		[bottomDraggerView addGestureRecognizer:recognizer];
		[MSHookIvar<UIWindow*>(self,"_reachabilityWindow") addSubview:bottomDraggerView];
	}

	// Update sizes of reachability (and their contained apps) and the location of the dragger view
	[self updateViewSizes:draggerView.center animate:NO];
}

%new -(void)RA_showWidgetSelector
{
	if (view)
		[self RA_closeCurrentView];
	UIWindow *w = MSHookIvar<UIWindow*>(self, "_reachabilityEffectWindow");
	//CGSize iconSize = [%c(SBIconView) defaultIconImageSize];
	CGSize fullSize = [%c(SBIconView) defaultIconSize];
	CGFloat padding = 20;

	NSInteger numIconsPerLine = 0;
	CGFloat tmpWidth = 10;
	while (tmpWidth + fullSize.width <= w.frame.size.width)
	{
		numIconsPerLine++;
		tmpWidth += fullSize.width + 20;
	}
	padding = (w.frame.size.width - (numIconsPerLine * fullSize.width)) / numIconsPerLine;

	UIView *widgetSelectorView = [[RAWidgetSectionManager sharedInstance] createViewForEnabledSectionsWithBaseFrame:w.frame preferredIconSize:fullSize iconsThatFitPerLine:numIconsPerLine spacing:padding];
	//widgetSelectorView.frame = w.frame;
	
	if (draggerView)
		[w insertSubview:widgetSelectorView belowSubview:draggerView];
	else
		[w addSubview:widgetSelectorView];
	view = widgetSelectorView;

	if ([RASettings.sharedInstance autoSizeWidgetSelector])
	{
		CGFloat moddedHeight = widgetSelectorView.frame.size.height;
		if (old_grabberCenterY == -1)
			old_grabberCenterY = UIScreen.mainScreen.bounds.size.height * 0.3;
		old_grabberCenterY = grabberCenter_Y;
		grabberCenter_Y = moddedHeight;
	}
	CGPoint newCenter = CGPointMake(draggerView.center.x, grabberCenter_Y);
	draggerView.center = newCenter;
	[self updateViewSizes:newCenter animate:YES];
}

CGFloat startingY = -1;
%new -(void)handlePan:(UIPanGestureRecognizer*)sender
{
	UIView *view = draggerView; //sender.view;

	if (sender.state == UIGestureRecognizerStateBegan)
	{
		startingY = grabberCenter_Y;
		grabberCenter_X = view.center.x;
		firstLocation = view.center;
		grabberCenter_Y = [sender locationInView:view.superview].y;
		draggerView.alpha = 0.8;
		bottomDraggerView.alpha = 0;
	}
	else if (sender.state == UIGestureRecognizerStateChanged)
	{
		CGPoint translation = [sender translationInView:view];

		if (firstLocation.y + translation.y < 50)
		{
			view.center = CGPointMake(grabberCenter_X, 50);
			grabberCenter_Y = 50;
		}
		else if (firstLocation.y + translation.y > UIScreen.mainScreen.bounds.size.height - 30)
		{
			view.center = CGPointMake(grabberCenter_X, UIScreen.mainScreen.bounds.size.height - 30);
			grabberCenter_Y = UIScreen.mainScreen.bounds.size.height - 30;
		}
		else
		{
			view.center = CGPointMake(grabberCenter_X, firstLocation.y + translation.y);
			grabberCenter_Y = [sender locationInView:view.superview].y;
		}

		[self updateViewSizes:view.center animate:YES];
	}
	else if (sender.state == UIGestureRecognizerStateEnded)
	{
		draggerView.alpha = 0.3;
		bottomDraggerView.alpha = 0.3;
		if (startingY != -1 && abs(grabberCenter_Y - startingY) < 3)
			[self RA_showWidgetSelector];
		startingY = -1;
		//[self updateViewSizes:view.center animate:YES];
	}
}

%new -(void) updateViewSizes:(CGPoint) center animate:(BOOL)animate
{
	// Resizing
	UIWindow *topWindow = MSHookIvar<UIWindow*>(self,"_reachabilityEffectWindow");
	UIWindow *bottomWindow = MSHookIvar<UIWindow*>(self,"_reachabilityWindow");

	CGRect topFrame = CGRectMake(topWindow.frame.origin.x, topWindow.frame.origin.y, topWindow.frame.size.width, center.y);
	CGRect bottomFrame = CGRectMake(bottomWindow.frame.origin.x, center.y, bottomWindow.frame.size.width, UIScreen.mainScreen.bounds.size.height - center.y);
	if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeLeft)
	{
		topFrame = CGRectMake(topWindow.frame.origin.x, center.y, topWindow.frame.size.width, UIScreen.mainScreen.bounds.size.height - center.y);
		bottomFrame = CGRectMake(bottomWindow.frame.origin.x, bottomWindow.frame.origin.y, bottomWindow.frame.size.width, center.y);
	}

	if (animate)
	{
		[UIView animateWithDuration:0.3 animations:^{
			bottomWindow.frame = bottomFrame;
			topWindow.frame = topFrame;
			if (view && [view isKindOfClass:[UIScrollView class]])
				view.frame = topFrame;
	    }];
	}
	else
	{
		bottomWindow.frame = bottomFrame;
		topWindow.frame = topFrame;
		if (view && [view isKindOfClass:[UIScrollView class]])
			view.frame = topFrame;
	}

	if ([RASettings.sharedInstance showNCInstead])
	{
		if (ncViewController)
			ncViewController.view.frame = (CGRect) { { 0, 0 }, topFrame.size };
	}
	else if (lastBundleIdentifier != nil)
	{
		// Notify clients
		NSMutableDictionary *dict = [NSMutableDictionary dictionary];
		if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight)
		{
			dict[@"sizeWidth"] = @(topWindow.frame.size.height);
			dict[@"sizeHeight"] = @(topWindow.frame.size.width);
		}
		else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft)
		{
			dict[@"sizeWidth"] = @(topWindow.frame.size.height);
			dict[@"sizeHeight"] = @(topWindow.frame.size.width);
		}
		else
		{
			dict[@"sizeWidth"] = @(topWindow.frame.size.width);
			dict[@"sizeHeight"] = @(topWindow.frame.size.height);
		}
		if (lastBundleIdentifier)
			dict[@"bundleIdentifier"] = lastBundleIdentifier;
		dict[@"isTopApp"] = @YES;
		dict[@"rotationMode"] = @([RASettings.sharedInstance scalingRotationMode]);
		CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.beginresizing"), NULL, (__bridge CFDictionaryRef)dict, true);
	}

	if ([view isKindOfClass:[%c(FBWindowContextHostWrapperView) class]] == NO)
		return; // only resize when the app is being shown. That way it's more like native Reachability

	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight)
	{
		dict[@"sizeWidth"] = @(bottomWindow.frame.size.height);
		dict[@"sizeHeight"] = @(bottomWindow.frame.size.width);
	}
	else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft)
	{
		dict[@"sizeWidth"] = @(bottomWindow.frame.size.height);
		dict[@"sizeHeight"] = @(bottomWindow.frame.size.width);
	}
	else
	{
		dict[@"sizeWidth"] = @(bottomWindow.frame.size.width);
		dict[@"sizeHeight"] = @(bottomWindow.frame.size.height);
	}
	dict[@"bundleIdentifier"] = currentBundleIdentifier;
	dict[@"isTopApp"] = @NO;
	dict[@"rotationMode"] = @([RASettings.sharedInstance scalingRotationMode]);
	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.beginresizing"), NULL, (__bridge CFDictionaryRef)dict, true);
}

%new -(void) RA_launchTopAppWithIdentifier:(NSString*) bundleIdentifier
{
	UIWindow *w = MSHookIvar<UIWindow*>(self, "_reachabilityEffectWindow");
	SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:lastBundleIdentifier];
	FBScene *scene = [app mainScene];
	if (app == nil)
		return;
	if (![app pid] || [app mainScene] == nil)
	{
		overrideDisableForStatusBar = YES;
		[UIApplication.sharedApplication launchApplicationWithIdentifier:bundleIdentifier suspended:YES];
		[[%c(FBProcessManager) sharedInstance] createApplicationProcessForBundleID:bundleIdentifier];

		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[self RA_launchTopAppWithIdentifier:bundleIdentifier];
			[self updateViewSizes:draggerView.center animate:YES];
		});
		return;
	}
	overrideDisableForStatusBar = NO;

	[[%c(SBAppSwitcherModel) sharedInstance] addToFront:[%c(SBDisplayLayout) fullScreenDisplayLayoutForApplication:[[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:bundleIdentifier]]];

	FBWindowContextHostManager *contextHostManager = [scene contextHostManager];

	FBSMutableSceneSettings *settings = [[scene mutableSettings] mutableCopy];
	object_setInstanceVariable(settings, "_backgrounded", (void*)NO);
	[scene _applyMutableSettings:settings withTransitionContext:nil completion:nil];

	[contextHostManager enableHostingForRequester:@"reachapp" orderFront:YES];
	view = [contextHostManager hostViewForRequester:@"reachapp" enableAndOrderFront:YES];

	if (draggerView && draggerView.superview == w)
		[w insertSubview:view belowSubview:draggerView];
	else
		[w addSubview:view];

	if ([RASettings.sharedInstance enableRotation] && ![RASettings.sharedInstance scalingRotationMode])
	{
		NSString *event = @"";
		// force the last app to orient to the current apps orientation
		if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight)
			event = @"com.efrederickson.reachapp.forcerotation-right";
		else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft)
			event = @"com.efrederickson.reachapp.forcerotation-left";
		else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait)
			event = @"com.efrederickson.reachapp.forcerotation-portrait";
		else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown)
			event = @"com.efrederickson.reachapp.forcerotation-upsidedown";

		CFMutableDictionaryRef dictionary = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFDictionaryAddValue(dictionary, @"bundleIdentifier", lastBundleIdentifier); // Top app
		CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), (__bridge CFStringRef)event, NULL, dictionary, true);
		CFRelease(dictionary);


	}
	else if ([RASettings.sharedInstance scalingRotationMode] && [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight)
	{
		overrideDisableForStatusBar = YES;

		// Force portrait
		NSString *event = @"com.efrederickson.reachapp.forcerotation-portrait";
		CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), (__bridge CFStringRef)event, NULL, (__bridge CFDictionaryRef)@{ @"bundleIdentifier": lastBundleIdentifier }, true);
		CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), (__bridge CFStringRef)event, NULL, (__bridge CFDictionaryRef)@{ @"bundleIdentifier": currentBundleIdentifier }, true);

		// Scale app
		CGFloat scale = view.frame.size.width / UIScreen.mainScreen.bounds.size.height;
		pre_topAppTransform = MSHookIvar<FBWindowContextHostView*>([app mainScene].contextHostManager, "_hostView").transform;
		MSHookIvar<FBWindowContextHostView*>([app mainScene].contextHostManager, "_hostView").transform = CGAffineTransformConcat(CGAffineTransformMakeScale(scale, scale), CGAffineTransformMakeRotation(M_PI_2));
		pre_topAppFrame = MSHookIvar<FBWindowContextHostView*>([app mainScene].contextHostManager, "_hostView").frame;
		MSHookIvar<FBWindowContextHostView*>([app mainScene].contextHostManager, "_hostView").frame = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height);
		UIWindow *window = MSHookIvar<UIWindow*>(self,"_reachabilityEffectWindow");
		window.frame = (CGRect) { window.frame.origin, { window.frame.size.width, view.frame.size.width } };

		window = MSHookIvar<UIWindow*>(self,"_reachabilityWindow");
		window.frame = (CGRect) { { window.frame.origin.x, view.frame.size.width }, { window.frame.size.width, view.frame.size.width } };
		
		SBApplication *currentApp = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:currentBundleIdentifier];
		if ([currentApp mainScene]) // just checking...
		{
			MSHookIvar<FBWindowContextHostView*>([currentApp mainScene].contextHostManager, "_hostView").transform = CGAffineTransformConcat(CGAffineTransformMakeScale(scale, scale), CGAffineTransformMakeRotation(M_PI_2));
			MSHookIvar<FBWindowContextHostView*>([currentApp mainScene].contextHostManager, "_hostView").frame = CGRectMake(0, 0, window.frame.size.width, window.frame.size.height);
		}

		// Gotta for the animations to finish... ;_;
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			overrideDisableForStatusBar = NO;
		});
	}
}

%new -(void) RA_setView:(UIView*)view_
{
	UIWindow *w = MSHookIvar<UIWindow*>(self, "_reachabilityEffectWindow");
	if (view)
		[view removeFromSuperview];
	view = view_;
	if (draggerView && draggerView.superview == w)
		[w insertSubview:view belowSubview:draggerView];
	else
		[w addSubview:view];
	[self updateViewSizes:draggerView.center animate:NO];
}

%new -(void) RA_animateWidgetSelectorOut:(id)completion
{
	[UIView animateWithDuration:0.3
        animations:^{
			view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.01, 0.01);
			view.alpha = 0;
        }
        completion:completion];
}

%new -(void) appViewItemTap:(UITapGestureRecognizer*)sender
{
	int pid = [sender.view tag];
	if (!pid)
		return;
	SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithPid:pid];
	if (!app)
		app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:sender.view.restorationIdentifier];

	if (app)
	{
		// before we re-assign view...
		[self RA_animateWidgetSelectorOut:^(BOOL a){
			[view removeFromSuperview];
			view = nil;

			lastBundleIdentifier = app.bundleIdentifier;
			[self RA_launchTopAppWithIdentifier:app.bundleIdentifier];

			if ([RASettings.sharedInstance autoSizeWidgetSelector])
			{
				if (old_grabberCenterY == -1)
					old_grabberCenterY = UIScreen.mainScreen.bounds.size.height * 0.3;
				grabberCenter_Y = old_grabberCenterY;
				draggerView.center = CGPointMake(grabberCenter_X, grabberCenter_Y);
			}
			[self updateViewSizes:draggerView.center animate:YES];
         }];
	}
}
%end

%hook SpringBoard
- (UIInterfaceOrientation)activeInterfaceOrientation
{
	return overrideOrientation ? UIInterfaceOrientationPortrait : %orig;
}
%end

%hook SBUIController
- (_Bool)clickedMenuButton
{
	if ([RASettings.sharedInstance homeButtonClosesReachability] && (view || showingNC) && ((SBReachabilityManager*)[%c(SBReachabilityManager) sharedInstance]).reachabilityModeActive)
	{
		[[%c(SBReachabilityManager) sharedInstance] _handleReachabilityDeactivated];
		return YES;
	}
	return %orig;
}
%end

%end // Group springboardHooks

NSCache *oldFrames = [NSCache new];

%group uikitHooks

%hook UIWindow
-(void) setFrame:(CGRect) frame
{
	if (overrideDisplay && overrideWidth != -1 && overrideHeight != -1)
	{
		if ([oldFrames objectForKey:@(self.hash)] == nil)
			[oldFrames setObject:[NSValue valueWithCGRect:frame] forKey:@(self.hash)];

		frame.origin.x = 0;
		frame.origin.y = 0;
		frame.size.width = overrideWidth;
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
%end

%hook UIApplication

- (void)_setStatusBarHidden:(BOOL)arg1 animationParameters:(id)arg2 changeApplicationFlag:(BOOL)arg3
{
	arg1 = (forcingRotation || overrideDisplay) ? (isTopApp ? NO : YES) : arg1;
	%orig(arg1, arg2, YES);
}

/*
- (void)_notifySpringBoardOfStatusBarOrientationChangeAndFenceWithAnimationDuration:(double)arg1
{
    if (scalingRotationMode && (overrideDisplay || forcingRotation))
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

%new - (void)RA_forceRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation isReverting:(BOOL) reverting
{
	//NSLog(@"ReachApp: RA_forceRotationToInterfaceOrientation %@", @(orientation));
	forcingRotation = YES;

	if (!reverting)
	{
		if (setPreviousOrientation == NO)
		{
			setPreviousOrientation = YES;
			prevousOrientation = UIApplication.sharedApplication.statusBarOrientation;


		}
		forcedOrientation = orientation;
		
		//if (wasStatusBarHidden == -1)
		//{
		//	wasStatusBarHidden = UIApplication.sharedApplication.statusBarHidden;
		//	[UIApplication.sharedApplication setStatusBarHidden:NO /* it doesn't matter, hooks will take care of it 8) */];
		//}
	}
	else
	{
		//[UIApplication.sharedApplication setStatusBarHidden:wasStatusBarHidden];
	}

		//[[UIApplication sharedApplication] setStatusBarOrientation:orientation];

    for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
    	[window _setRotatableViewOrientation:orientation updateStatusBar:YES duration:0.0 force:YES];
    }

    forcingRotation = NO;
}
%end

%hook UIViewController
- (void)_presentViewController:(id)viewController withAnimationController:(id)animationController completion:(id)completion
{
	overrideViewControllerDismissal = YES;
	%orig;
	overrideViewControllerDismissal = NO;
}

- (void)dismissViewControllerWithTransition:(id)transition completion:(id)completion
{
	overrideViewControllerDismissal = YES;
	%orig;
	overrideViewControllerDismissal = NO;
}
%end

%hook UINavigationController
- (void)pushViewController:(id)viewController transition:(id)transition forceImmediate:(BOOL)immediate
{
	overrideViewControllerDismissal = YES;
	%orig;
	overrideViewControllerDismissal = NO;
}

- (id)_popViewControllerWithTransition:(id)transition allowPoppingLast:(BOOL)last
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
- (void)moveFromPlacement:(id)arg1 toPlacement:(id)arg2 starting:(id)arg3 completion:(id)arg4
{
	overrideViewControllerDismissal = YES;
	%orig;
	overrideViewControllerDismissal = NO;
}
%end
%end // group uikitHooks

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

void forceResizing(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
	NSDictionary *info = (__bridge NSDictionary*)userInfo;
	if ([NSBundle.mainBundle.bundleIdentifier isEqual:[info objectForKey:@"bundleIdentifier"]])
	{
		isTopApp = [[info objectForKey:@"isTopApp"] boolValue];

		if (wasStatusBarHidden == -1 && forcedOrientation == UIInterfaceOrientationPortrait)
		{
			wasStatusBarHidden = UIApplication.sharedApplication.statusBarHidden;
			[UIApplication.sharedApplication _setStatusBarHidden:NO /* it doesn't matter, hooks will take care of it 8) */ animationParameters:nil changeApplicationFlag:YES];
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
		}

		//[UIWindow setAllWindowsKeepContextInBackground:NO];
		if (setPreviousOrientation)
		    [[UIApplication sharedApplication] RA_forceRotationToInterfaceOrientation:prevousOrientation isReverting:YES];
	    setPreviousOrientation = NO;
	    if (wasStatusBarHidden != -1)
		    [UIApplication.sharedApplication _setStatusBarHidden:wasStatusBarHidden animationParameters:nil changeApplicationFlag:YES];
	}
}

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
	if (strcmp(__progname, "filecoordinationd") == 0)
	{
		// Somehow, filecoordinationd seems to be crashing (due to XPC?)
		// although it might be unrelated to ReachApp. 
		// I haven't noticed it crashing though.
		// Simply not initializing any of the hooks/CFNotificationCenter callbacks should do the trick.
		// But I won't know until people either stop sending emails or continue sending emails...
		return;
	}
    else
    {
		NSString *bundleIdentifier = NSBundle.mainBundle.bundleIdentifier;
	    if ([bundleIdentifier isEqual:@"com.apple.springboard"])
		{
			%init(springboardHooks);
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &reloadSettings, CFSTR("com.efrederickson.reachapp.settings/reloadSettings"), NULL, 0);
			reloadSettings(NULL, NULL, NULL, NULL, NULL);
		}
		else
		{
	        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, forceRotation_right, CFSTR("com.efrederickson.reachapp.forcerotation-right"), NULL, CFNotificationSuspensionBehaviorDrop);
	        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, forceRotation_left, CFSTR("com.efrederickson.reachapp.forcerotation-left"), NULL, CFNotificationSuspensionBehaviorDrop);
	        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, forceRotation_portrait, CFSTR("com.efrederickson.reachapp.forcerotation-portrait"), NULL, CFNotificationSuspensionBehaviorDrop);
	        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, forceRotation_upsidedown, CFSTR("com.efrederickson.reachapp.forcerotation-upsidedown"), NULL, CFNotificationSuspensionBehaviorDrop);
	        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, forceResizing, CFSTR("com.efrederickson.reachapp.beginresizing"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, endForceResizing, CFSTR("com.efrederickson.reachapp.endresizing"), NULL, CFNotificationSuspensionBehaviorDrop);
	    }
    	%init(uikitHooks);
    }
}