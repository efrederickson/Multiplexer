#import "headers.h"
#import "RAMissionControlWindow.h"
#import "RAMissionControlManager.h"
#import "RAMissionControlPreviewView.h"
#import "RADesktopWindow.h"
#import "RADesktopManager.h"
#import "RAWindowBar.h"
#import "RAHostedAppView.h"
#import "RASnapshotProvider.h"
#import "RAAppKiller.h"
#import "RAGestureManager.h"
#import "RAWindowStatePreservationSystemManager.h"
#import "RAHostManager.h"
#import "RARunningAppsProvider.h"
#import "RAControlCenterInhibitor.h"
#import "RASettings.h"

@interface RAMissionControlManager () {
	SBApplication *lastOpenedApp;
	NSMutableArray *appsWithoutWindows;

	UIStatusBar *statusBar;

	__block UIView *originalAppView;
	__block CGRect originalAppFrame;
	BOOL hasMoved;
	BOOL didStoreSnapshot;
}
@end

CGRect swappedForOrientation(CGRect in)
{
	if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeLeft)
	{
		CGFloat x = in.origin.x;
		in.origin.x = in.origin.y;
		in.origin.y = x;
	}
	else if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeRight)
	{
		CGFloat x = in.origin.x;
		in.origin.x = fabs(in.origin.y) + UIScreen.mainScreen.bounds.size.width;
		in.origin.y = x;
	}

	return in;
}

CGRect swappedForOrientation2(CGRect in)
{
	if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeLeft)
	{
		CGFloat x = in.origin.x;
		in.origin.x = in.origin.y;
		in.origin.y = x;
	}
	else if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeRight)
	{
		CGFloat x = in.origin.x;
		in.origin.x = -in.size.width;
		in.origin.y = x;
	}

	return in;
}

@implementation RAMissionControlManager
+(instancetype) sharedInstance
{
	SHARED_INSTANCE2(RAMissionControlManager, 
		sharedInstance->originalAppView = nil;
		sharedInstance.inhibitDismissalGesture = NO;
		sharedInstance->hasMoved = NO;
		sharedInstance->inhibitedApplications = [NSMutableArray array];
	);
}

-(void) showMissionControl:(BOOL)animated
{
	if (![NSThread isMainThread])
	{
		dispatch_sync(dispatch_get_main_queue(), ^{ [self showMissionControl:animated]; });
		return;
	}
	
	_isShowingMissionControl = YES;

	SBApplication *app = UIApplication.sharedApplication._accessibilityFrontMostApplication;
	if (app)
		lastOpenedApp = app;

	[self createWindow];

	if (animated)
		//window.alpha = 0;
		window.frame = swappedForOrientation(CGRectMake(0, -window.frame.size.height, window.frame.size.width, window.frame.size.height));
	
	[window makeKeyAndVisible];

	if (lastOpenedApp && lastOpenedApp.isRunning)
	{
		originalAppView = [%c(RAHostManager) systemHostViewForApplication:lastOpenedApp].superview;
		originalAppFrame = originalAppView.frame;
	}

	if (animated)
	{
		//[UIView animateWithDuration:0.5 animations:^{ window.alpha = 1; }];
		[UIView animateWithDuration:0.5 animations:^{ 
			window.frame = CGRectMake(0, 0, window.frame.size.width, window.frame.size.height); 

			if (originalAppView)
					originalAppView.frame = swappedForOrientation2(CGRectMake(originalAppFrame.origin.x, originalAppView.frame.size.height, originalAppFrame.size.width, originalAppFrame.size.height));
		} completion:nil];
	}
	else if (originalAppView) // dismiss even if not animating open
	{
		originalAppView.frame = swappedForOrientation2(CGRectMake(originalAppFrame.origin.x, originalAppView.frame.size.height, originalAppFrame.size.width, originalAppFrame.size.height));
	}

	[window updateForOrientation:UIApplication.sharedApplication.statusBarOrientation];
	[[%c(RAGestureManager) sharedInstance] addGestureRecognizerWithTarget:self forEdge:UIRectEdgeBottom identifier:@"com.efrederickson.reachapp.missioncontrol.dismissgesture" priority:RAGesturePriorityHigh];
	[[%c(RAGestureManager) sharedInstance] ignoreSwipesBeginningInRect:UIScreen.mainScreen.bounds forIdentifier:@"com.efrederickson.reachapp.windowedmultitasking.systemgesture"];
	[[%c(RARunningAppsProvider) sharedInstance] addTarget:window];
	[[%c(SBUIController) sharedInstance] _lockOrientationForSwitcher];
    [[%c(SBWallpaperController) sharedInstance] beginRequiringWithReason:@"RAMissionControlManager"];
	self.inhibitDismissalGesture = NO;
	[%c(RAControlCenterInhibitor) setInhibited:YES];

	if ([[%c(SBControlCenterController) sharedInstance] isVisible])
		[[%c(SBControlCenterController) sharedInstance] dismissAnimated:YES];

	didStoreSnapshot = NO;
}

-(void) createWindow
{
	if (window)
	{
		if (originalAppView)
			originalAppView.frame = originalAppFrame;
		window.hidden = YES;
		window = nil;
	}

	window = [[RAMissionControlWindow alloc] initWithFrame:UIScreen.mainScreen._interfaceOrientedBounds];
	window.manager = self;
	[window _rotateWindowToOrientation:UIApplication.sharedApplication.statusBarOrientation updateStatusBar:YES duration:1 skipCallbacks:NO];

	//_UIBackdropView *blurView = [[%c(_UIBackdropView) alloc] initWithStyle:1];
	_UIBackdropViewSettings *blurSettings = [_UIBackdropViewSettings settingsForStyle:THEMED(missionControlBlurStyle)];
	[blurSettings setBlurQuality:@"low"]; // speed++ hopefully
	_UIBackdropView *blurView = [[%c(_UIBackdropView) alloc] initWithSettings:blurSettings];
	blurView.frame = window.frame;
	[window addSubview:blurView];

	int statusBarStyle = 0x12F; //Normal notification center style
	UIInterfaceOrientation orientation = UIApplication.sharedApplication.statusBarOrientation;
	statusBar = [[UIStatusBar alloc] initWithFrame:CGRectMake(0, 0, UIApplication.sharedApplication.statusBar.bounds.size.width, [UIStatusBar heightForStyle:statusBarStyle orientation:orientation])];
	[statusBar requestStyle:statusBarStyle];
	statusBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[window addSubview:statusBar];
	[statusBar setOrientation:UIApplication.sharedApplication.statusBarOrientation];

	// DESKTOPS
	[self reloadDesktopSection];

	// APPS WITH PANES
	[self reloadWindowedAppsSection];

	// APPS WITHOUT PANES
	[self reloadOtherAppsSection];
}

-(void) reloadDesktopSection
{
	[window reloadDesktopSection];
}

-(void) reloadWindowedAppsSection
{
	[window reloadWindowedAppsSection:[[%c(RARunningAppsProvider) sharedInstance] runningApplications]];
}

-(void) reloadOtherAppsSection
{
	[window reloadOtherAppsSection];
}

-(void) hideMissionControl:(BOOL)animated
{
	if (!didStoreSnapshot)
		[[%c(RASnapshotProvider) sharedInstance] storeSnapshotOfMissionControl:window];
	[[%c(RARunningAppsProvider) sharedInstance] removeTarget:window];

	void (^destructor)() = ^{
		originalAppView = nil;
		window.hidden = YES;
		window = nil;

		// This goes here to prevent the wallpaper from appearing black when dismissing
	    [[%c(SBWallpaperController) sharedInstance] endRequiringWithReason:@"RAMissionControlManager"];
	};

	if (animated)
	{
		[UIView animateWithDuration:0.5 animations:^{
			window.frame = swappedForOrientation(CGRectMake(0, -window.frame.size.height, window.frame.size.width, window.frame.size.height)); 

			if (originalAppView)
					originalAppView.frame = originalAppFrame;
		} completion:^(BOOL _) { destructor(); }];
	}
	else
	{
		if (originalAppView)
			originalAppView.frame = originalAppFrame;
		destructor();
	}

	_isShowingMissionControl = NO;
	[[%c(RADesktopManager) sharedInstance] reshowDesktop];
	[[[%c(RADesktopManager) sharedInstance] currentDesktop] loadApps];
	[[%c(RAGestureManager) sharedInstance] removeGestureWithIdentifier:@"com.efrederickson.reachapp.missioncontrol.dismissgesture"];
	[[%c(RAGestureManager) sharedInstance] stopIgnoringSwipesForIdentifier:@"com.efrederickson.reachapp.windowedmultitasking.systemgesture"];
	[[%c(SBUIController) sharedInstance] releaseSwitcherOrientationLock];
    [%c(RAControlCenterInhibitor) setInhibited:NO];

	//if (lastOpenedApp && lastOpenedApp.isRunning && UIApplication.sharedApplication._accessibilityFrontMostApplication != lastOpenedApp)
	//{
	//	if ([[%c(RADesktopManager) sharedInstance] isAppOpened:lastOpenedApp.bundleIdentifier] == NO)
	//	{
	//		[[%c(SBUIController) sharedInstance] activateApplicationAnimated:lastOpenedApp];
	//	}
	//}
	lastOpenedApp = nil; // Fix it opening the same app later if on the Homescreen
}

-(void) toggleMissionControl:(BOOL)animated
{
	if (_isShowingMissionControl)
		[self hideMissionControl:animated];
	else
		[self showMissionControl:animated];
}

-(BOOL) RAGestureCallback_canHandle:(CGPoint)point velocity:(CGPoint)velocity
{
	return self.isShowingMissionControl && self.inhibitDismissalGesture == NO;
}

-(RAGestureCallbackResult) RAGestureCallback_handle:(UIGestureRecognizerState)state withPoint:(CGPoint)location velocity:(CGPoint)velocity forEdge:(UIRectEdge)edge
{
	static CGPoint initialCenter;
	static CGRect initialAppFrame;

	if (state == UIGestureRecognizerStateEnded)
	{
		hasMoved = NO;
		[%c(RAControlCenterInhibitor) setInhibited:NO];

		BOOL dismiss = NO;
		if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeRight)
		{
			dismiss = window.frame.origin.x + velocity.y > UIScreen.mainScreen.bounds.size.width / 2.0;
		}
		else if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeLeft)
		{
			dismiss = window.frame.origin.x + window.frame.size.width < UIScreen.mainScreen._interfaceOrientedBounds.size.width / 2.0;
		}
		else if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationPortrait)
			dismiss = window.frame.origin.y + window.frame.size.height + velocity.y < UIScreen.mainScreen._interfaceOrientedBounds.size.height / 2;

		if (dismiss)
		{
			// Close
			CGFloat distance = UIScreen.mainScreen._interfaceOrientedBounds.size.height - (window.frame.origin.y + window.frame.size.height);
			CGFloat duration = MIN(distance / velocity.y, 0.3);

			[UIView animateWithDuration:duration animations:^{
				if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationPortrait)
					window.center = CGPointMake(window.center.x, -initialCenter.y);
				if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeRight)	
				{
					CGRect f = window.frame;
					f.origin.x = UIScreen.mainScreen.bounds.size.width;
					window.frame = f;
				}
				else if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeLeft)
				{
					CGRect f = window.frame;
					f.origin.x = -UIScreen.mainScreen.bounds.size.width;
					window.frame = f;
				}

				if (originalAppView)
					originalAppView.frame = originalAppFrame;
			} completion:^(BOOL _) {
				[self hideMissionControl:NO];
			}];
		}
		else
		{
			CGFloat distance = window.center.y + window.frame.origin.y /* origin.y is less than 0 so the + is actually a - operation */;
			CGFloat duration = MIN(distance / velocity.y, 0.3);

			[UIView animateWithDuration:duration animations:^{
				window.center = initialCenter;
				if (originalAppView)
					originalAppView.frame = swappedForOrientation2(CGRectMake(originalAppFrame.origin.x, originalAppView.frame.size.height, originalAppFrame.size.width, originalAppFrame.size.height));
			}];
		}
	}
	else if (state == UIGestureRecognizerStateBegan)
	{
		//[[%c(RASnapshotProvider) sharedInstance] storeSnapshotOfMissionControl:window];
		didStoreSnapshot = YES;
		hasMoved = YES;
		[%c(RAControlCenterInhibitor) setInhibited:YES];
		initialCenter = window.center;
		if (originalAppView)
			initialAppFrame = initialAppFrame;
	}
	else
	{
		if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeRight)
		{
			CGRect f = window.frame;
			f.origin.x = UIScreen.mainScreen.bounds.size.width - location.y;
			window.frame = f;
		}
		else if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeLeft)
		{
			CGRect f = window.frame;
			f.origin.x = -UIScreen.mainScreen.bounds.size.width + location.y;
			window.frame = f;
		}
		else if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationPortrait)
			window.center = CGPointMake(window.center.x, location.y - initialCenter.y);

		if (originalAppView)
			originalAppView.frame = swappedForOrientation2(CGRectMake(originalAppView.frame.origin.x, UIScreen.mainScreen._interfaceOrientedBounds.size.height - (UIScreen.mainScreen._interfaceOrientedBounds.size.height - location.y), originalAppFrame.size.width, originalAppFrame.size.height));
	}
	return RAGestureCallbackResultSuccess;
}

-(void) inhibitApplication:(NSString*)identifer 
{
	if ([inhibitedApplications containsObject:identifer] == NO)
		[inhibitedApplications addObject:identifer];
}

-(void) uninhibitApplication:(NSString*)identifer
{
	if ([inhibitedApplications containsObject:identifer])
		[inhibitedApplications removeObject:identifer];
}

-(NSArray*) inhibitedApplications { return inhibitedApplications; }
-(void) setInhibitedApplications:(NSArray*)icons { inhibitedApplications = [icons mutableCopy]; }

-(RAMissionControlWindow*) missionControlWindow { return window; }

-(void) setInhibitDismissalGesture:(BOOL)value
{
	_inhibitDismissalGesture = value;
	if (value && hasMoved)
	{
		[self RAGestureCallback_handle:UIGestureRecognizerStateEnded withPoint:CGPointZero velocity:CGPointZero forEdge:UIRectEdgeBottom];
	}
}
@end

%hook SBLockStateAggregator
-(void) _updateLockState
{
    %orig;
    
    if ([self hasAnyLockState])
		if (RAMissionControlManager.sharedInstance.isShowingMissionControl)
			[RAMissionControlManager.sharedInstance hideMissionControl:NO];
}
%end