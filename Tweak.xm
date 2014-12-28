#import <UIKit/UIKit.h>
#import <substrate.h>
#import <SpringBoard/SBApplication.h>
#include <mach/mach.h>
#include <libkern/OSCacheControl.h>
#include <stdbool.h>
#include <dlfcn.h>
#include <sys/sysctl.h>
#import <notify.h>

/*
This code thanks: 
ForceReach: https://github.com/PoomSmart/ForceReach/
Reference: https://github.com/fewjative/Reference
MessageBox: https://github.com/b3ll/MessageBox
This pastie (by @Freerunnering?): http://pastie.org/pastes/8684110

Many concepts and ideas have been used from them.

*/

@interface FBApplicationProcess : NSObject
- (void)launchIfNecessary;
- (BOOL)bootstrapAndExec;
@end

extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);

@interface UITextEffectsWindow : UIWindow
+ (id)sharedTextEffectsWindow;
@end

@interface UIWindow () 
+ (void)setAllWindowsKeepContextInBackground:(BOOL)arg1;
-(void) _setRotatableViewOrientation:(UIInterfaceOrientation)orientation duration:(CGFloat)duration force:(BOOL)force;
- (void)_setRotatableViewOrientation:(int)arg1 updateStatusBar:(BOOL)arg2 duration:(double)arg3 force:(BOOL)arg4;
- (void)_rotateWindowToOrientation:(int)arg1 updateStatusBar:(BOOL)arg2 duration:(double)arg3 skipCallbacks:(BOOL)arg4;
@end

@interface UIApplication ()
- (id)_mainScene;
-(SBApplication*) _accessibilityFrontMostApplication;
- (void)RA_forceRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation isReverting:(BOOL)reverting;
- (void)applicationDidResume;
- (void)_sendWillEnterForegroundCallbacks;
- (void)suspend;
- (void)applicationWillSuspend;
- (void)_setSuspended:(BOOL)arg1;
- (void)applicationSuspend;
- (void)_deactivateForReason:(int)arg1 notify:(BOOL)arg2;
@end

extern const char *__progname;
extern "C" int xpc_connection_get_pid(id connection);

typedef NS_ENUM(NSUInteger, BKSProcessAssertionReason)
{
    kProcessAssertionReasonAudio = 1,
    kProcessAssertionReasonLocation,
    kProcessAssertionReasonExternalAccessory,
    kProcessAssertionReasonFinishTask,
    kProcessAssertionReasonBluetooth,
    kProcessAssertionReasonNetworkAuthentication,
    kProcessAssertionReasonBackgroundUI,
    kProcessAssertionReasonInterAppAudioStreaming,
    kProcessAssertionReasonViewServices
};

typedef NS_ENUM(NSUInteger, ProcessAssertionFlags)
{
    ProcessAssertionFlagNone = 0,
    ProcessAssertionFlagPreventSuspend         = 1 << 0,
    ProcessAssertionFlagPreventThrottleDownCPU = 1 << 1,
    ProcessAssertionFlagAllowIdleSleep         = 1 << 2,
    ProcessAssertionFlagWantsForegroundResourcePriority  = 1 << 3
};


@interface FBWindowContextHostManager
- (id)hostViewForRequester:(id)arg1 enableAndOrderFront:(BOOL)arg2;
- (void)resumeContextHosting;
- (id)_hostViewForRequester:(id)arg1 enableAndOrderFront:(BOOL)arg2;
- (id)snapshotViewWithFrame:(CGRect)arg1 excludingContexts:(id)arg2 opaque:(BOOL)arg3;
- (id)visibleContexts;
- (void)orderRequesterFront:(id)arg1;
- (void)enableHostingForRequester:(id)arg1 orderFront:(BOOL)arg2;
- (void)enableHostingForRequester:(id)arg1 priority:(int)arg2;
- (void)disableHostingForRequester:(id)arg1;
- (void)_updateHostViewFrameForRequester:(id)arg1;
- (void)invalidate;
@end

@interface FBSSceneSettings : NSObject <NSCopying, NSMutableCopying>
{
    CGRect _frame;
    CGPoint _contentOffset;
    float _level;
    int _interfaceOrientation;
    BOOL _backgrounded;
    BOOL _occluded;
    BOOL _occludedHasBeenCalculated;
    NSSet *_ignoreOcclusionReasons;
    NSArray *_occlusions;
    //BSSettings *_otherSettings;
    //BSSettings *_transientLocalSettings;
}

+ (BOOL)_isMutable;
+ (id)settings;
@property(readonly, copy, nonatomic) NSArray *occlusions; // @synthesize occlusions=_occlusions;
@property(readonly, nonatomic, getter=isBackgrounded) BOOL backgrounded; // @synthesize backgrounded=_backgrounded;
@property(readonly, nonatomic) int interfaceOrientation; // @synthesize interfaceOrientation=_interfaceOrientation;
@property(readonly, nonatomic) float level; // @synthesize level=_level;
@property(readonly, nonatomic) CGPoint contentOffset; // @synthesize contentOffset=_contentOffset;
@property(readonly, nonatomic) CGRect frame; // @synthesize frame=_frame;
- (id)valueDescriptionForFlag:(int)arg1 object:(id)arg2 ofSetting:(unsigned int)arg3;
- (id)keyDescriptionForSetting:(unsigned int)arg1;
- (id)description;
- (BOOL)isEqual:(id)arg1;
- (unsigned int)hash;
- (id)_descriptionOfSettingsWithMultilinePrefix:(id)arg1;
- (id)transientLocalSettings;
- (BOOL)isIgnoringOcclusions;
- (id)ignoreOcclusionReasons;
- (id)otherSettings;
- (BOOL)isOccluded;
- (CGRect)bounds;
- (void)dealloc;
- (id)init;
- (id)initWithSettings:(id)arg1;

@end

@interface FBSMutableSceneSettings : FBSSceneSettings
{
}

+ (BOOL)_isMutable;
- (id)mutableCopyWithZone:(struct _NSZone *)arg1;
- (id)copyWithZone:(struct _NSZone *)arg1;
@property(copy, nonatomic) NSArray *occlusions;
- (id)transientLocalSettings;
- (id)ignoreOcclusionReasons;
- (id)otherSettings;
@property(nonatomic, getter=isBackgrounded) BOOL backgrounded;
@property(nonatomic) int interfaceOrientation;
@property(nonatomic) float level;
@property(nonatomic) struct CGPoint contentOffset;
@property(nonatomic) struct CGRect frame;

@end

@interface FBScene
-(FBWindowContextHostManager*) contextHostManager;
@property(readonly, retain, nonatomic) FBSMutableSceneSettings *mutableSettings; // @synthesize mutableSettings=_mutableSettings;
- (void)updateSettings:(id)arg1 withTransitionContext:(id)arg2;
@end

@interface SBApplication ()
-(FBScene*) mainScene;
- (void)activate;

- (void)processDidLaunch:(id)arg1;
- (void)processWillLaunch:(id)arg1;
- (void)resumeForContentAvailable;
- (void)resumeToQuit;
- (void)_sendDidLaunchNotification:(_Bool)arg1;
- (void)notifyResumeActiveForReason:(long long)arg1;

@property(readonly, nonatomic) int pid;
@end

@interface SBApplicationController
+(id) sharedInstance;
-(SBApplication*) applicationWithBundleIdentifier:(NSString*)identifier;
@end

@interface FBWindowContextHostWrapperView : UIView
@property(readonly, nonatomic) FBWindowContextHostManager *manager; // @synthesize manager=_manager;
@property(nonatomic) unsigned int appearanceStyle; // @synthesize appearanceStyle=_appearanceStyle;
- (void)_setAppearanceStyle:(unsigned int)arg1 force:(BOOL)arg2;
- (id)_stringForAppearanceStyle;
- (id)window;
@property(readonly, nonatomic) struct CGRect referenceFrame; // @dynamic referenceFrame;
@property(readonly, nonatomic, getter=isContextHosted) BOOL contextHosted; // @dynamic contextHosted;
- (void)clearManager;
- (void)_hostingStatusChanged;
- (BOOL)_isReallyHosting;
- (void)updateFrame;
@end
@interface FBWindowContextHostView : UIView
@end

@interface SBWorkspace
-(void) updateViewSizes:(CGPoint)center;
@end

@interface UIKeyboard : UIView
+ (id)activeKeyboard;
@end

@interface BKSProcessAssertion
- (id)initWithPID:(int)arg1 flags:(unsigned int)arg2 reason:(unsigned int)arg3 name:(id)arg4 withHandler:(id)arg5;
- (id)initWithBundleIdentifier:(id)arg1 flags:(unsigned int)arg2 reason:(unsigned int)arg3 name:(id)arg4 withHandler:(id)arg5;
- (void)invalidate;
@property(readonly, nonatomic) BOOL valid;
@end

@interface SBReachabilityManager
+ (id)sharedInstance;
@property(readonly, nonatomic) _Bool reachabilityModeActive; // @synthesize reachabilityModeActive=_reachabilityModeActive;
@end

FBWindowContextHostWrapperView *view = nil;
BKSProcessAssertion *keepAlive = nil;
NSMutableArray *lastBundleIdentifiers = [NSMutableArray array];
NSString *lastBundleIdentifier = @"";
NSString *currentBundleIdentifier = @"";

BOOL overrideDisplay = NO;
CGFloat overrideHeight = 0;
CGFloat overrideWidth = 0;
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

BOOL enabled = YES;
BOOL disableAutoDismiss = YES;
BOOL enableRotation = YES;
BOOL showNCInstead = NO;

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
%end

BOOL wasEnabled = NO;
%hook SBWorkspace
- (void)_disableReachabilityImmediately:(_Bool)arg1
{
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
				//notify_post("com.efrederickson.reachapp.endresizing");

				// Notify both top and bottom apps Reachability is closing
				CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.endresizing"), NULL, (__bridge CFDictionaryRef)@{ @"bundleIdentifier": lastBundleIdentifier}, NO);
				CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.endresizing"), NULL, (__bridge CFDictionaryRef)@{ @"bundleIdentifier": currentBundleIdentifier}, NO);

				SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:lastBundleIdentifier];
				if (app && [app pid] && [app mainScene])
				{
					if (view)
					{
						if ([view superview] != nil)
							[view removeFromSuperview];
					}
					if (keepAlive != nil)
				    	[keepAlive invalidate];

					FBScene *scene = [app mainScene];
					FBWindowContextHostManager *contextHostManager = [scene contextHostManager];
					[contextHostManager disableHostingForRequester:@"reachapp"];
				}
				view = nil;
			    keepAlive = nil;
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

		static UIViewController *viewController = [[%c(SBNotificationCenterViewController) alloc] init];
		viewController.view.frame = (CGRect) { { 0, 0 }, w.frame.size };
		w.rootViewController = viewController;
		[w addSubview:viewController.view];

		//[[%c(SBNotificationCenterController) performSelector:@selector(sharedInstance)] performSelector:@selector(_setupForViewPresentation)];
		[viewController performSelector:@selector(hostWillPresent)];
		[viewController performSelector:@selector(hostDidPresent)];
		[[%c(SBNotificationCenterController) performSelector:@selector(sharedInstance)] performSelector:@selector(showGrabberAnimated:) withObject:@YES];

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

		while ([app mainScene] == nil && lastBundleIdentifiers.count > 0)
		{
			if (lastBundleIdentifiers.count > 0)
			{
				//while (lastBundleIdentifiers.count > 0 && [lastBundleIdentifiers[0] isEqual:currentBundleIdentifier])
				//	[lastBundleIdentifiers removeObjectAtIndex:0];
				[lastBundleIdentifiers removeObject:currentBundleIdentifier];
				if (lastBundleIdentifiers.count > 0)
					lastBundleIdentifier = lastBundleIdentifiers[0];
			}
			if (lastBundleIdentifier == nil || lastBundleIdentifier.length == 0)
				return;

			app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:lastBundleIdentifier];
			scene = [app mainScene];

			if (!scene)
				if (lastBundleIdentifiers.count > 0)
					[lastBundleIdentifiers removeObjectAtIndex:0];
		}

		if (!app || ![app pid] || [app mainScene] == nil)
		{
			[lastBundleIdentifiers removeObject:lastBundleIdentifier];
			return;
		}

		if (!scene)
			return; // app is dead

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

		[contextHostManager enableHostingForRequester:@"reachapp" orderFront:YES];
		view = [contextHostManager hostViewForRequester:@"reachapp" enableAndOrderFront:YES];

		[w addSubview:view];

		if (enableRotation)
		{
			// force the last app to orient to the current apps orientation
			if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight)
				notify_post("com.efrederickson.reachapp.forcerotation-right");
			else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft)
				notify_post("com.efrederickson.reachapp.forcerotation-left");
			else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait)
				notify_post("com.efrederickson.reachapp.forcerotation-portrait");
			else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown)
				notify_post("com.efrederickson.reachapp.forcerotation-upsidedown");
		}
	}

	UIView *draggerView = [[UIView alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height * .3, w.frame.size.width, 15)];
	draggerView.alpha = 0.8;
	grabberCenter_X = draggerView.center.x;
	draggerView.backgroundColor = UIColor.lightGrayColor;
	UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
	if (grabberCenter_Y == -1)
		grabberCenter_Y = w.frame.size.height - 15;
	if (grabberCenter_Y < 0)
		grabberCenter_Y = UIScreen.mainScreen.bounds.size.height * 0.3;
	draggerView.center = CGPointMake(grabberCenter_X, grabberCenter_Y);
	[draggerView addGestureRecognizer:recognizer];

	[w addSubview:draggerView];

	// Update sizes of reachability (and their contained apps) and the location of the dragger view
	[self updateViewSizes:draggerView.center];
}

%new -(void)handlePan:(UIPanGestureRecognizer*)sender
{
	UIView *view = sender.view;

	if (sender.state == UIGestureRecognizerStateBegan)
	{
		grabberCenter_X = view.center.x;
		firstLocation = view.center;
		grabberCenter_Y = [sender locationInView:view.superview].y;
	}
	else if (sender.state == UIGestureRecognizerStateChanged)
	{
		CGPoint translation = [sender translationInView:view];

		view.center = CGPointMake(grabberCenter_X, firstLocation.y + translation.y);
		grabberCenter_Y = [sender locationInView:view.superview].y;

		[self updateViewSizes:view.center];
	}
}

%new -(void) updateViewSizes:(CGPoint) center
{
	// Resizing
	UIWindow *topWindow = MSHookIvar<UIWindow*>(self,"_reachabilityEffectWindow");
	CGRect topFrame = CGRectMake(topWindow.frame.origin.x, topWindow.frame.origin.y, topWindow.frame.size.width, center.y);
	topWindow.frame = topFrame;

	UIWindow *bottomWindow = MSHookIvar<UIWindow*>(self,"_reachabilityWindow");
	CGRect bottomFrame = CGRectMake(bottomWindow.frame.origin.x, center.y, bottomWindow.frame.size.width, UIScreen.mainScreen.bounds.size.height - center.y);
	bottomWindow.frame = bottomFrame;

	if (showNCInstead)
	{
		UIViewController *viewController = [[%c(SBNotificationCenterController) performSelector:@selector(sharedInstance)] performSelector:@selector(viewController)];
		viewController.view.frame = (CGRect) { { 0, 0 }, topFrame.size };
	}
	else
	{
		// Notifying clients
		CFMutableDictionaryRef dictionary = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight)
		{
			CFDictionaryAddValue(dictionary, @"sizeWidth", @(topWindow.frame.size.height));
			CFDictionaryAddValue(dictionary, @"sizeHeight", @(topWindow.frame.size.width));
		}
		else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft)
		{
			/* welp, this needs fixed */
			CFDictionaryAddValue(dictionary, @"sizeWidth", @(topWindow.frame.size.height));
			CFDictionaryAddValue(dictionary, @"sizeHeight", @(topWindow.frame.size.width));
		}
		else
		{
			CFDictionaryAddValue(dictionary, @"sizeWidth", @(topWindow.frame.size.width));
			CFDictionaryAddValue(dictionary, @"sizeHeight", @(topWindow.frame.size.height));
		}
		CFDictionaryAddValue(dictionary, @"bundleIdentifier", lastBundleIdentifier);
		CFDictionaryAddValue(dictionary, @"isTopApp", @YES);
		CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.beginresizing"), NULL, dictionary, true);
		CFRelease(dictionary);
	}

	CFMutableDictionaryRef dictionary = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight)
	{
		CFDictionaryAddValue(dictionary, @"sizeWidth", @(bottomWindow.frame.size.height));
		CFDictionaryAddValue(dictionary, @"sizeHeight", @(bottomWindow.frame.size.width));
	}
	else
	{
		CFDictionaryAddValue(dictionary, @"sizeWidth", @(bottomWindow.frame.size.width));
		CFDictionaryAddValue(dictionary, @"sizeHeight", @(bottomWindow.frame.size.height));
	}
	CFDictionaryAddValue(dictionary, @"bundleIdentifier", currentBundleIdentifier);
		CFDictionaryAddValue(dictionary, @"isTopApp", @NO);
	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.beginresizing"), NULL, dictionary, true);
	CFRelease(dictionary);
}
%end

%hook SpringBoard
- (UIInterfaceOrientation)activeInterfaceOrientation
{
	return overrideOrientation ? UIInterfaceOrientationPortrait : %orig;
}
%end

%hook SBApplication
- (void)setApplicationState:(unsigned int)arg1
{
	%orig;
	if (arg1 != UIApplicationStateActive)
	{
		if ([lastBundleIdentifiers containsObject:self.bundleIdentifier])
			[lastBundleIdentifiers removeObject:self.bundleIdentifier];
		[lastBundleIdentifiers insertObject:self.bundleIdentifier atIndex:0];
	}
}
%end

//%hook SBUIController
//- (_Bool)clickedMenuButton; < just close reachability if open?
//%end

%end // Group springboardHook

NSCache *oldFrames = [NSCache new];

%group uikitHooks
%hook UIWindow
+(void) initialize
{
	%orig;

	//if ([UIWindow.keyWindow _scene] == nil)
	//	return;
	//[UIWindow setAllWindowsKeepContextInBackground:YES];
}
//+(void)setAllWindowsKeepContextInBackground:(BOOL)background
//{
//	%orig(background);
//}

-(void) setFrame:(CGRect) frame
{
	if (overrideDisplay)
	{
		if ([oldFrames objectForKey:@(self.hash)] == nil)
			[oldFrames setObject:[NSValue valueWithCGRect:frame] forKey:@(self.hash)];

		frame.origin.x = 0;
		frame.origin.y = 0;
		frame.size.width = overrideWidth;
		frame.size.height = overrideHeight;
		//self.clipsToBounds = YES;
	}

	%orig(frame);
}

- (void)_rotateWindowToOrientation:(int)arg1 updateStatusBar:(BOOL)arg2 duration:(double)arg3 skipCallbacks:(BOOL)arg4
{
	if (overrideDisplay && forcingRotation == NO)
	{
		return;
		//%orig(forcedOrientation, arg2, arg3, arg4);
	}
	%orig;
}

- (BOOL)_shouldAutorotateToInterfaceOrientation:(int)arg1 checkForDismissal:(BOOL)arg2 isRotationDisabled:(BOOL*)arg3
{
	if (overrideDisplay && forcingRotation == NO)
	{
		return NO;
	}
	return %orig;
}

- (void)_setWindowInterfaceOrientation:(int)arg1
{
	if (overrideDisplay) 
		return;
	%orig(overrideDisplay ? forcedOrientation : arg1);
}

- (void)setAutorotates:(BOOL)arg1 forceUpdateInterfaceOrientation:(BOOL)arg2 { %orig(overrideDisplay ? NO : arg1, arg2); }
- (void)setAutorotates:(BOOL)arg1 { %orig(overrideDisplay ? NO : arg1); }
- (void)_rotateToBounds:(struct CGRect)arg1 withAnimator:(id)arg2 transitionContext:(id)arg3
{
	if (overrideDisplay && forcingRotation == NO)
		return;
	%orig;
}
%end

%hook UIApplication


-(int) applicationState
{
	return overrideDisplay ? UIApplicationStateActive : %orig;
}

- (void)applicationWillOrderInContext:(id)arg1 forWindow:(id)arg2
{
	if (![self _mainScene])
		[UIWindow setAllWindowsKeepContextInBackground:NO];
	%orig;
}

- (void)_deactivateReachability
{
	if (overrideViewControllerDismissal)
		return;
	%orig;
}

%new - (void)RA_forceRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation isReverting:(BOOL) reverting
{
	forcingRotation = YES;
	if (!reverting)
	{
		if (setPreviousOrientation == NO)
		{
			setPreviousOrientation = YES;
			prevousOrientation = UIApplication.sharedApplication.statusBarOrientation;
		}
		forcedOrientation = orientation;
	}

    [[UIApplication sharedApplication] setStatusBarOrientation:orientation];
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

// Not sure which combination of these works, but it does. 
- (BOOL)shouldAutorotateToInterfaceOrientation:(int)arg1 { return overrideDisplay && arg1 != forcedOrientation ? NO : %orig; }
- (BOOL)shouldAutorotate { return overrideDisplay ? NO : %orig; }
- (void)_setAllowsAutorotation:(BOOL)arg1 { %orig(overrideDisplay ? NO : arg1); }
- (BOOL)_allowsAutorotation { return overrideDisplay ? NO : %orig; }
- (BOOL)window:(id)arg1 shouldAutorotateToInterfaceOrientation:(int)arg { return overrideDisplay ? NO : %orig; }
- (BOOL)_isInterfaceAutorotationDisabled { return overrideDisplay ? YES : %orig; }
- (int)_rotatingToInterfaceOrientation { return overrideDisplay ? forcedOrientation : %orig; }
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
    if ([entitlement isEqualToString:@"com.apple.multitasking.unlimitedassertions"])
        return true;

    return orig_BSAuditTokenTaskHasEntitlement(connection, entitlement);
}

void forceRotation_right(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
    UIInterfaceOrientation newOrientation = UIInterfaceOrientationLandscapeRight;
    [[UIApplication sharedApplication] RA_forceRotationToInterfaceOrientation:newOrientation isReverting:NO];
}
void forceRotation_left(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
    UIInterfaceOrientation newOrientation = UIInterfaceOrientationLandscapeLeft;
    [[UIApplication sharedApplication] RA_forceRotationToInterfaceOrientation:newOrientation isReverting:NO];
}
void forceRotation_portrait(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
    UIInterfaceOrientation newOrientation = UIInterfaceOrientationPortrait;
    [[UIApplication sharedApplication] RA_forceRotationToInterfaceOrientation:newOrientation isReverting:NO];
}
void forceRotation_upsidedown(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
    UIInterfaceOrientation newOrientation = UIInterfaceOrientationPortraitUpsideDown;
    [[UIApplication sharedApplication] RA_forceRotationToInterfaceOrientation:newOrientation isReverting:NO];
}

BOOL resumed = NO;

void forceResizing(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
	if ([NSBundle.mainBundle.bundleIdentifier isEqual:[(__bridge NSDictionary*)userInfo objectForKey:@"bundleIdentifier"]])
	{
		if (!resumed)
		{
			resumed = YES;
			UIApplication *sharedApp = [UIApplication sharedApplication];
			[sharedApp _sendWillEnterForegroundCallbacks];
			[sharedApp applicationDidResume];
			if ([sharedApp.delegate respondsToSelector:@selector(applicationWillEnterForeground:)])
				[sharedApp.delegate applicationWillEnterForeground:sharedApp];
			if ([sharedApp.delegate respondsToSelector:@selector(applicationDidBecomeActive:)])
				[sharedApp.delegate applicationDidBecomeActive:sharedApp];
			[NSNotificationCenter.defaultCenter postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];
			[NSNotificationCenter.defaultCenter postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
		}

		[UIWindow setAllWindowsKeepContextInBackground:YES];
		overrideHeight = [[(__bridge NSDictionary*)userInfo objectForKey:@"sizeHeight"] floatValue];
		overrideWidth = [[(__bridge NSDictionary*)userInfo objectForKey:@"sizeWidth"] floatValue];
		overrideDisplay = YES;

		//if ([[(__bridge NSDictionary*)userInfo objectForKey:@"isTopApp"] boolValue])
		//	[UIApplication.sharedApplication setStatusBarHidden:NO];
		//else //if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationPortrait)
		//	[UIApplication.sharedApplication setStatusBarHidden:YES];

		for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
			if ([oldFrames objectForKey:@(window.hash)] == nil)
				[oldFrames setObject:[NSValue valueWithCGRect:window.frame] forKey:@(window.hash)];
	        [window setFrame:window.frame];
	    }
	}
}
void endForceResizing(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
	if ([NSBundle.mainBundle.bundleIdentifier isEqual:[(__bridge NSDictionary*)userInfo objectForKey:@"bundleIdentifier"]])
	{
		overrideDisplay = NO;

		//[UIWindow setAllWindowsKeepContextInBackground:NO];
	    [[UIApplication sharedApplication] RA_forceRotationToInterfaceOrientation:prevousOrientation isReverting:YES];
	    setPreviousOrientation = NO;

		for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
			CGRect frame = window.frame;
			if ([oldFrames objectForKey:@(window.hash)] != nil)
			{
				frame = [[oldFrames objectForKey:@(window.hash)] CGRectValue];
				frame.origin.x = 0;
				frame.origin.y = 0;
			}
	        [window setFrame:frame];
	    }

	    if (resumed)
		{
			resumed = NO;
			UIApplication *sharedApp = [UIApplication sharedApplication];
			if ([sharedApp.delegate respondsToSelector:@selector(applicationWillResignActive:)])
				[sharedApp.delegate applicationWillResignActive:sharedApp];
			if ([sharedApp.delegate respondsToSelector:@selector(applicationDidEnterBackground:)])
				[sharedApp.delegate applicationDidEnterBackground:sharedApp];
			[NSNotificationCenter.defaultCenter postNotificationName:UIApplicationWillResignActiveNotification object:nil];
			[NSNotificationCenter.defaultCenter postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
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
}

%ctor
{
	NSString *bundleIdentifier = NSBundle.mainBundle.bundleIdentifier;
	if ([bundleIdentifier isEqual:@"com.apple.springboard"])
	{
		%init(springboardHooks);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &reloadSettings, CFSTR("com.efrederickson.reachapp.settings/reloadSettings"), NULL, 0);
		reloadSettings(NULL, NULL, NULL, NULL, NULL);
	}
	else if (strcmp(__progname, "assertiond") == 0) 
	{
        dlopen("/System/Library/PrivateFrameworks/XPCObjects.framework/XPCObjects", RTLD_LAZY);
        void *xpcFunction = MSFindSymbol(NULL, "_BSAuditTokenTaskHasEntitlement");
        MSHookFunction(xpcFunction, (void *)hax_BSAuditTokenTaskHasEntitlement, (void **)&orig_BSAuditTokenTaskHasEntitlement);
    }
    else
    {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, forceRotation_right, CFSTR("com.efrederickson.reachapp.forcerotation-right"), NULL, CFNotificationSuspensionBehaviorDrop);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, forceRotation_left, CFSTR("com.efrederickson.reachapp.forcerotation-left"), NULL, CFNotificationSuspensionBehaviorDrop);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, forceRotation_portrait, CFSTR("com.efrederickson.reachapp.forcerotation-portrait"), NULL, CFNotificationSuspensionBehaviorDrop);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, forceRotation_upsidedown, CFSTR("com.efrederickson.reachapp.forcerotation-upsidedown"), NULL, CFNotificationSuspensionBehaviorDrop);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, forceResizing, CFSTR("com.efrederickson.reachapp.beginresizing"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, endForceResizing, CFSTR("com.efrederickson.reachapp.endresizing"), NULL, CFNotificationSuspensionBehaviorDrop);
    }
    %init(uikitHooks);
}