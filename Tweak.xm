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

/*
This code thanks: 
ForceReach: https://github.com/PoomSmart/ForceReach/
Reference: https://github.com/fewjative/Reference
MessageBox: https://github.com/b3ll/MessageBox
This pastie (by @Freerunnering?): http://pastie.org/pastes/8684110
AppHeads disassembly: Original binary from @sharedRoutine

Many concepts and ideas have been used from them.
*/

@interface SBWorkspace (ReachApp)
-(void)RA_launchTopAppWithIdentifier:(NSString*)bundleIdentifier;
@end

extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);
extern const char *__progname; 
extern "C" int xpc_connection_get_pid(id connection);

/*FBWindowContextHostWrapperView*/ UIView *view = nil;
BKSProcessAssertion *keepAlive = nil;
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
BOOL wasStatusBarHidden = NO;
BOOL overrideDisableForStatusBar = NO;
CGRect pre_topAppFrame = CGRectZero;
CGAffineTransform pre_topAppTransform = CGAffineTransformIdentity;
UIView *bottomDraggerView = nil;
CGFloat old_grabberCenterY = -1;

BOOL enabled = YES;
BOOL disableAutoDismiss = YES;
BOOL enableRotation = YES;
BOOL showNCInstead = NO;
BOOL homeButtonClosesReachability = YES;
BOOL showBottomGrabber = NO;
BOOL showAppSelector = YES;
BOOL scalingRotationMode = NO; 
BOOL autoSizeAppChooser = YES;

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
	if ((view || showingNC) && disableAutoDismiss)
		return;
	%orig;
}

- (void)_handleSignificantTimeChanged
{
	if ((view || showingNC) && disableAutoDismiss)
		return;
	%orig;
}

- (void)_keepAliveTimerFired:(id)arg1
{
	if ((view || showingNC) && disableAutoDismiss)
		return;
	%orig;
}

- (void)_handleReachabilityDeactivated
{
	if (overrideDisableForStatusBar)
		return;

	%orig;
}
%end

BOOL wasEnabled = NO;
%hook SBWorkspace
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

- (void)_disableReachabilityImmediately:(_Bool)arg1
{
	if (overrideDisableForStatusBar)
		return;

	if (!enabled)
	{
		%orig;
		return;
	}

	//if ([[%c(SBReachabilityManager) sharedInstance] reachabilityModeActive])
	if (wasEnabled)
	{
		wasEnabled = NO;
		if (arg1)
		{
			// Notify both top and bottom apps Reachability is closing
			if (lastBundleIdentifier)
				CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.endresizing"), NULL, (__bridge CFDictionaryRef)@{ @"bundleIdentifier": lastBundleIdentifier}, NO);
			if (currentBundleIdentifier)
				CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.endresizing"), NULL, (__bridge CFDictionaryRef)@{ @"bundleIdentifier": currentBundleIdentifier}, NO);

			if (draggerView)
				draggerView = nil;

			if (showNCInstead)
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
				for (UIView *v in MSHookIvar<UIWindow*>(self, "_reachabilityEffectWindow").subviews)
				{
					if ([v isKindOfClass:[UIScrollView class]])
					{
						for (UIView *v2 in v.subviews)
						{
							if ([v2 isKindOfClass:[%c(SBIconView) class]])
							{
								for (UIGestureRecognizer *gesture in [v2 gestureRecognizers])
					            {
					               if ([gesture isKindOfClass:[UITapGestureRecognizer class]])
					               {
						                if (MSHookIvar<id>(MSHookIvar<NSMutableArray*>(gesture, "_targets")[0], "_target") == self)
						                	[v2 removeGestureRecognizer:gesture];
					               }
					            }
							}
						}
					}
				}

				// Give them a little time to receive the notifications...
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
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

							if (view)
							{
								if ([view superview] != nil)
									[view removeFromSuperview];
							}
							if (keepAlive != nil)
						    	[keepAlive invalidate];

							FBWindowContextHostManager *contextHostManager = [scene contextHostManager];
							[contextHostManager disableHostingForRequester:@"reachapp"];
						}
					}
					view = nil;
				    keepAlive = nil;
				    lastBundleIdentifier = nil;
				});
			}
		}
	}

	%orig;
}

- (void) handleReachabilityModeActivated
{
	%orig;
	if (!enabled)
		return;
	wasEnabled = YES;

	UIWindow *w = MSHookIvar<UIWindow*>(self, "_reachabilityEffectWindow");
	if (showNCInstead)
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

		if (enableRotation)
		{
        	[w _setRotatableViewOrientation:[UIApplication sharedApplication].statusBarOrientation updateStatusBar:YES duration:0.0 force:YES];
		}
	}
	else
	{
		SBApplication *app = nil;
		FBScene *scene = nil;

		currentBundleIdentifier = [[UIApplication sharedApplication] _accessibilityFrontMostApplication].bundleIdentifier;
		if (!currentBundleIdentifier)
			return;

		if (showAppSelector)
		{
			UIScrollView *appSelectorView = [[UIScrollView alloc] initWithFrame:w.frame];
			appSelectorView.backgroundColor = [UIColor clearColor];
			CGSize contentSize = CGSizeMake(20, 20);
			CGFloat oneRowHeight = -1;
			for (NSString *str in [[%c(SBAppSwitcherModel) sharedInstance] snapshotOfFlattenedArrayOfAppIdentifiersWhichIsOnlyTemporary])
			{
				if ([currentBundleIdentifier isEqual:str] == NO && str && str.length > 0)
				{
					app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:str];
					scene = [app mainScene];
					if (scene)
					{
				        SBIcon *icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForBundleIdentifier:app.bundleIdentifier];
				        SBIconView *iconView = [[%c(SBIconViewMap) homescreenMap] _iconViewForIcon:icon];
				        if (!iconView)
				        	continue;
				        
				        if (contentSize.width + iconView.frame.size.width >= UIScreen.mainScreen.bounds.size.width)
						{
							contentSize.width = 20;
				        	contentSize.height += oneRowHeight + 10;
						}

				        iconView.frame = CGRectMake(contentSize.width, contentSize.height, iconView.frame.size.width, iconView.frame.size.height);
				        switch (UIApplication.sharedApplication.statusBarOrientation)
				        {
				        	case UIInterfaceOrientationLandscapeRight:
				        		iconView.frame = CGRectMake(contentSize.width + 5, contentSize.height + 5, iconView.frame.size.width, iconView.frame.size.height);
				        		iconView.transform = CGAffineTransformMakeRotation(M_PI_2);
				        		if (oneRowHeight != -1)
					        		oneRowHeight += 5;
				        		break;
				        	case UIInterfaceOrientationLandscapeLeft:
				        	case UIInterfaceOrientationPortrait:
				        	default:
				        		break;
				        }

				        iconView.tag = [app pid];
				        UITapGestureRecognizer *iconViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(appViewItemTap:)];
				        [iconView addGestureRecognizer:iconViewTapGestureRecognizer];
				        if (oneRowHeight == -1)
				        	oneRowHeight = iconView.frame.size.height + 10;
				        [appSelectorView addSubview:iconView];
				        contentSize.width += iconView.frame.size.width + 20;
					}
				}
			}
			if (oneRowHeight != -1)
				contentSize.height += oneRowHeight + 10;
			[appSelectorView setContentSize:contentSize];
			[w addSubview:appSelectorView];
			view = appSelectorView;

			if (autoSizeAppChooser && appSelectorView.subviews.count > 2) // These two are the "default" UIImageView's that are the scroll indicators. What a pain.
			{
				CGFloat moddedHeight = contentSize.height;
				if (moddedHeight > oneRowHeight * 3)
					moddedHeight = (oneRowHeight * 3) + 10;
				if (old_grabberCenterY == -1)
					old_grabberCenterY = UIScreen.mainScreen.bounds.size.height * 0.3;
				old_grabberCenterY = grabberCenter_Y;
				grabberCenter_Y = moddedHeight;
			}
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
	UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
	if (grabberCenter_Y == -1)
		grabberCenter_Y = w.frame.size.height - (knobHeight / 2);
	if (grabberCenter_Y < 0)
		grabberCenter_Y = UIScreen.mainScreen.bounds.size.height * 0.3;
	draggerView.center = CGPointMake(grabberCenter_X, grabberCenter_Y);
	[draggerView addGestureRecognizer:recognizer];

	[w addSubview:draggerView];

	if (showBottomGrabber)
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
	[self updateViewSizes:draggerView.center];
}

%new -(void)handlePan:(UIPanGestureRecognizer*)sender
{
	//static CGFloat initialGrabberY = 0;
	UIView *view = draggerView; //sender.view;

	if (sender.state == UIGestureRecognizerStateBegan)
	{
		grabberCenter_X = view.center.x;
		firstLocation = view.center;
		grabberCenter_Y = [sender locationInView:view.superview].y;
		//initialGrabberY = grabberCenter_Y;
		draggerView.alpha = 0.8;
		bottomDraggerView.alpha = 0.8;
	}
	else if (sender.state == UIGestureRecognizerStateChanged)
	{
		CGPoint translation = [sender translationInView:view];

		//BOOL needsToResizeNow = NO;
		//if (initialGrabberY < firstLocation.y + translation.y)
		//	needsToResizeNow = YES;
		//else
		//	initialGrabberY = firstLocation.y + translation.y;

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
		//if (needsToResizeNow)
			[self updateViewSizes:view.center];
	}
	else if (sender.state == UIGestureRecognizerStateEnded)
	{
		draggerView.alpha = 0.3;
		bottomDraggerView.alpha = 0.3;
		[self updateViewSizes:view.center];
	}
}

%new -(void) updateViewSizes:(CGPoint) center
{
	// Resizing
	UIWindow *topWindow = MSHookIvar<UIWindow*>(self,"_reachabilityEffectWindow");
	UIWindow *bottomWindow = MSHookIvar<UIWindow*>(self,"_reachabilityWindow");

	CGRect topFrame = CGRectMake(topWindow.frame.origin.x, topWindow.frame.origin.y, topWindow.frame.size.width, center.y);
	CGRect bottomFrame = CGRectMake(bottomWindow.frame.origin.x, center.y, bottomWindow.frame.size.width, UIScreen.mainScreen.bounds.size.height - center.y);

	[UIView animateWithDuration:0.3 animations:^{
		bottomWindow.frame = bottomFrame;
		topWindow.frame = topFrame;
		if (view && [view isKindOfClass:[UIScrollView class]])
			view.frame = topFrame;
    }];

	if (showNCInstead)
	{
		if (ncViewController)
			ncViewController.view.frame = (CGRect) { { 0, 0 }, topFrame.size };
	}
	else
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
		dict[@"rotationMode"] = @(scalingRotationMode);
		CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.beginresizing"), NULL, (__bridge CFDictionaryRef)dict, true);
	}

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
	dict[@"rotationMode"] = @(scalingRotationMode);
	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.beginresizing"), NULL, (__bridge CFDictionaryRef)dict, true);
}

%new -(void) RA_launchTopAppWithIdentifier:(NSString*) bundleIdentifier
{
	UIWindow *w = MSHookIvar<UIWindow*>(self, "_reachabilityEffectWindow");
	SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:lastBundleIdentifier];
	FBScene *scene = [app mainScene];
	if (!app || ![app pid] || [app mainScene] == nil)
	{
		return;
	}

	if (keepAlive != nil)
    	[keepAlive invalidate]; // shouldn't get here - this removes the old last apps backgrounding assertion
	keepAlive = [[%c(BKSProcessAssertion) alloc] initWithPID:[app pid]
	                                                   flags:(ProcessAssertionFlagPreventSuspend |
                                                                      ProcessAssertionFlagAllowIdleSleep |
                                                                      ProcessAssertionFlagPreventThrottleDownCPU |
                                                                      ProcessAssertionFlagWantsForegroundResourcePriority)
                                                              reason:kProcessAssertionReasonBackgroundUI
	                                                    name:@"reachapp"
	                                             withHandler:nil //^void (void)
                  //{
                  //    NSLog(@"ReachApp: %d kept alive: %@", [app pid], [keepAlive valid] > 0 ? @"TRUE" : @"FALSE");
                  //}
                  ];


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

	if (enableRotation && !scalingRotationMode)
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
	else if (scalingRotationMode && [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight)
	{
		overrideDisableForStatusBar = YES;

		// Force portrait
		NSString *event = @"com.efrederickson.reachapp.forcerotation-portrait";
		CFMutableDictionaryRef dictionary = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFDictionaryAddValue(dictionary, @"bundleIdentifier", lastBundleIdentifier); // Top app
		CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), (__bridge CFStringRef)event, NULL, dictionary, true);
		CFDictionaryAddValue(dictionary, @"bundleIdentifier", currentBundleIdentifier); // Bottom app
		CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), (__bridge CFStringRef)event, NULL, dictionary, true);
		CFRelease(dictionary);

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
			MSHookIvar<FBWindowContextHostView*>([currentApp mainScene].contextHostManager, "_hostView").frame = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height);
		}

		// Gotta for the animations to finish... ;_;
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			overrideDisableForStatusBar = NO;
			// welp. 
			[[%c(SBReachabilityManager) sharedInstance] _handleReachabilityActivated];
		});
	}
}

%new -(void) appViewItemTap:(UITapGestureRecognizer*)sender
{
	int pid = [sender.view tag];
	if (!pid)
		return;
	SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithPid:pid];
	if (app)
	{
		UIWindow *w = MSHookIvar<UIWindow*>(self,"_reachabilityEffectWindow");

		// Wow... 
		for (UIView *v in w.subviews)
		{
			if ([v isKindOfClass:[UIScrollView class]])
			{
				for (UIView *v2 in v.subviews)
				{
					if ([v2 isKindOfClass:[%c(SBIconView) class]])
					{
						for (UIGestureRecognizer *gesture in [v2 gestureRecognizers])
			            {
			               if ([gesture isKindOfClass:[UITapGestureRecognizer class]])
			               {
				               if (MSHookIvar<id>(MSHookIvar<NSMutableArray*>(gesture, "_targets")[0], "_target") == self)
				                    [v2 removeGestureRecognizer:gesture];
			               }
			            }
					}
				}
			}
		}

		// before we re-assign view...
		/*[UIView animateWithDuration:0.8
	             animations:^{
					view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0, 0);
					view.alpha = 0;
	             }
	             completion:^(BOOL a){*/
					[view removeFromSuperview];
					view = nil;

					lastBundleIdentifier = app.bundleIdentifier;
					[self RA_launchTopAppWithIdentifier:app.bundleIdentifier];

					if (autoSizeAppChooser)
					{
						if (old_grabberCenterY == -1)
							old_grabberCenterY = UIScreen.mainScreen.bounds.size.height * 0.3;
						grabberCenter_Y = old_grabberCenterY;
						draggerView.center = CGPointMake(grabberCenter_X, grabberCenter_Y);
					}
					[self updateViewSizes:draggerView.center];
	             //}];
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
	if (homeButtonClosesReachability && (view || showingNC) && ((SBReachabilityManager*)[%c(SBReachabilityManager) sharedInstance]).reachabilityModeActive)
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

//- (void)_notifySpringBoardOfStatusBarOrientationChangeAndFenceWithAnimationDuration:(double)arg1
//{
//    if (scalingRotationMode && (overrideDisplay || overrideRotation))
//        return;
//    %orig;
//}

/*
- (void)_setStatusBarHidden:(BOOL)arg1 animationParameters:(id)arg2 changeApplicationFlag:(BOOL)arg3
{
	if (overrideDisplay && forcedOrientation == UIInterfaceOrientationPortrait && isTopApp == NO)
	{
		%orig(YES, arg2, arg3);
		return;
	}
	else if (overrideDisplay && forcedOrientation == UIInterfaceOrientationPortrait && isTopApp == YES)
	{
		%orig(NO, arg2, arg3);
		return;
	}
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
	NSLog(@"ReachApp: RA_forceRotationToInterfaceOrientation %@", @(orientation));
	forcingRotation = YES;

	if (!reverting)
	{
		if (setPreviousOrientation == NO)
		{
			setPreviousOrientation = YES;
			prevousOrientation = UIApplication.sharedApplication.statusBarOrientation;


		}
		forcedOrientation = orientation;
		
		//wasStatusBarHidden = UIApplication.sharedApplication.statusBarHidden;
		//if (overrideDisplay && isTopApp && orientation == UIInterfaceOrientationPortrait)
		//	[UIApplication.sharedApplication setStatusBarHidden:NO];
		//else if (overrideDisplay && orientation == UIInterfaceOrientationPortrait)
		//	[UIApplication.sharedApplication setStatusBarHidden:YES];
	}
	else
	{
		//[UIApplication.sharedApplication setStatusBarHidden:wasStatusBarHidden];
	}

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) 
	{
		// TODO
	}
	else
	{
		//[[UIApplication sharedApplication] setStatusBarOrientation:orientation];

	    for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
	    	[window _setRotatableViewOrientation:orientation updateStatusBar:YES duration:0.0 force:YES];
	    }
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

static int (*orig_BSAuditTokenTaskHasEntitlement)(id connection, NSString *entitlement);
static int hax_BSAuditTokenTaskHasEntitlement(id connection, NSString *entitlement) 
{
	// TODO: should probably verify it's SpringBoard asking
    if ([entitlement isEqualToString:@"com.apple.multitasking.unlimitedassertions"])
        return true;

    return orig_BSAuditTokenTaskHasEntitlement(connection, entitlement);
}

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

void forceResizing(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
	if ([NSBundle.mainBundle.bundleIdentifier isEqual:[(__bridge NSDictionary*)userInfo objectForKey:@"bundleIdentifier"]])
	{
		isTopApp = [[(__bridge NSDictionary*)userInfo objectForKey:@"isTopApp"] boolValue];

		//[UIWindow setAllWindowsKeepContextInBackground:YES];

		scalingRotationMode = [[(__bridge NSDictionary*)userInfo objectForKey:@"rotationMode"] boolValue];
		if (!scalingRotationMode)
		{
			overrideHeight = [[(__bridge NSDictionary*)userInfo objectForKey:@"sizeHeight"] floatValue];
			overrideWidth = [[(__bridge NSDictionary*)userInfo objectForKey:@"sizeWidth"] floatValue];
		}
		overrideDisplay = YES;


		if (!scalingRotationMode)
		{
			for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
				if ([oldFrames objectForKey:@(window.hash)] == nil)
					[oldFrames setObject:[NSValue valueWithCGRect:window.frame] forKey:@(window.hash)];
				[UIView animateWithDuration:0.3 animations:^{
			        [window setFrame:window.frame];
			    }];
		    }
		    ((UIView*)[UIKeyboard activeKeyboard]).frame = ((UIView*)[UIKeyboard activeKeyboard]).frame;
		}
	}
}
void endForceResizing(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
	if ([NSBundle.mainBundle.bundleIdentifier isEqual:[(__bridge NSDictionary*)userInfo objectForKey:@"bundleIdentifier"]])
	{
		overrideDisplay = NO;

		//[UIWindow setAllWindowsKeepContextInBackground:NO];
		if (setPreviousOrientation)
		    [[UIApplication sharedApplication] RA_forceRotationToInterfaceOrientation:prevousOrientation isReverting:YES];
	    setPreviousOrientation = NO;
	    //[UIApplication.sharedApplication setStatusBarHidden:wasStatusBarHidden];

	    if (!scalingRotationMode)
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
		        [UIView animateWithDuration:0.3 animations:^{
			        [window setFrame:frame];
			    }];
		    }
		}
	}
}

void reloadSettings(CFNotificationCenterRef center,
                    void *observer,
                    CFStringRef name,
                    const void *object,
                    CFDictionaryRef userInfo)
{
	NSDictionary *prefs = nil;

	CFStringRef appID = CFSTR("com.efrederickson.reachapp.settings");
	CFArrayRef keyList = CFPreferencesCopyKeyList(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (!keyList) {
		return;
	}
	prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (!prefs) {
		return;
	}
	CFRelease(keyList);

    enabled = [prefs objectForKey:@"enabled"] != nil ? [prefs[@"enabled"] boolValue] : YES;
	disableAutoDismiss = [prefs objectForKey:@"disableAutoDismiss"] != nil ? [prefs[@"disableAutoDismiss"] boolValue] : YES;
	enableRotation = [prefs objectForKey:@"enableRotation"] != nil ? [prefs[@"enableRotation"] boolValue] : YES;
	showNCInstead = [prefs objectForKey:@"showNCInstead"] != nil ? [prefs[@"showNCInstead"] boolValue] : NO;
	homeButtonClosesReachability = [prefs objectForKey:@"homeButtonClosesReachability"] != nil ? [prefs[@"homeButtonClosesReachability"] boolValue] : YES;
	showBottomGrabber = [prefs objectForKey:@"showBottomGrabber"] != nil ? [prefs[@"showBottomGrabber"] boolValue] : NO;
	showAppSelector = [prefs objectForKey:@"showAppSelector"] != nil ? [prefs[@"showAppSelector"] boolValue] : YES;
	scalingRotationMode = [prefs objectForKey:@"rotationMode"] != nil ? [prefs[@"rotationMode"] intValue] : NO;
	autoSizeAppChooser = [prefs objectForKey:@"autoSizeAppChooser"] != nil ? [prefs[@"autoSizeAppChooser"] intValue] : YES;
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
	else if (strcmp(__progname, "assertiond") == 0) 
	{
        dlopen("/System/Library/PrivateFrameworks/XPCObjects.framework/XPCObjects", RTLD_LAZY);
        void *xpcFunction = MSFindSymbol(NULL, "_BSAuditTokenTaskHasEntitlement");
        MSHookFunction(xpcFunction, (void *)hax_BSAuditTokenTaskHasEntitlement, (void **)&orig_BSAuditTokenTaskHasEntitlement);
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
	        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, forceResizing, CFSTR("com.efrederickson.reachapp.beginresizing"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, endForceResizing, CFSTR("com.efrederickson.reachapp.endresizing"), NULL, CFNotificationSuspensionBehaviorDrop);
	    }
    	%init(uikitHooks);
    }
}