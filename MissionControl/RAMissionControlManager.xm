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
#import "RALockStateUpdater.h"
#import "RAHostManager.h"
#import "RARunningAppsProvider.h"

extern BOOL overrideCC;

@interface RAMissionControlManager () {
	SBApplication *lastOpenedApp;
	NSMutableArray *appsWithoutWindows;

	__block UIView *originalAppView;
	__block CGRect originalAppFrame;
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

@implementation RAMissionControlManager
+(instancetype) sharedInstance
{
	SHARED_INSTANCE2(RAMissionControlManager, 
		sharedInstance->originalAppView = nil;
	);
}

-(void) showMissionControl:(BOOL)animated
{
	_isShowingMissionControl = YES;

	SBApplication *app = UIApplication.sharedApplication._accessibilityFrontMostApplication;
	if (app)
		lastOpenedApp = app;

	if (window)
		window = nil;

	[self createWindow];

	if (animated)
		//window.alpha = 0;
		window.frame = swappedForOrientation(CGRectMake(0, -window.frame.size.height, window.frame.size.width, window.frame.size.height));
	
	[window makeKeyAndVisible];

	if (lastOpenedApp)
	{
		originalAppView = [RAHostManager systemHostViewForApplication:lastOpenedApp].superview;
		originalAppFrame = originalAppView.frame;
	}

	if (animated)
	{
		//[UIView animateWithDuration:0.5 animations:^{ window.alpha = 1; }];
		[UIView animateWithDuration:0.5 animations:^{ window.frame = CGRectMake(0, 0, window.frame.size.width, window.frame.size.height); } completion:nil];

		if (originalAppView)
			[UIView animateWithDuration:0.5 animations:^{
				originalAppView.frame = CGRectMake(originalAppFrame.origin.x, originalAppView.frame.size.height, originalAppFrame.size.width, originalAppFrame.size.height);
			} completion:^(BOOL _) {
				//originalAppView.frame = originalAppFrame;
				//dismissApp();
			}];
	}
	else if (lastOpenedApp) // dismiss even if not animating open
	{
		originalAppView.frame = CGRectMake(originalAppFrame.origin.x, originalAppView.frame.size.height, originalAppFrame.size.width, originalAppFrame.size.height);
	}

	//[window updateForOrientation:UIApplication.sharedApplication.statusBarOrientation];
	
	[RAGestureManager.sharedInstance addGestureRecognizerWithTarget:self forEdge:UIRectEdgeBottom identifier:@"com.efrederickson.reachapp.missioncontrol.dismissgesture"];
	overrideCC = YES;
}

-(void) createWindow
{
	if (window)
	{
		window.hidden = YES;
		window = nil;
	}

	window = [[RAMissionControlWindow alloc] initWithFrame:UIScreen.mainScreen._interfaceOrientedBounds];
	window.manager = self;
	[window _rotateWindowToOrientation:UIApplication.sharedApplication.statusBarOrientation updateStatusBar:YES duration:1 skipCallbacks:NO];

	//_UIBackdropView *blurView = [[%c(_UIBackdropView) alloc] initWithStyle:1];
	_UIBackdropViewSettings *blurSettings = [_UIBackdropViewSettings settingsForStyle:THEMED(missionControlBlurStyle)];
	[blurSettings setBlurQuality:@"low"];
	_UIBackdropView *blurView = [[%c(_UIBackdropView) alloc] initWithSettings:blurSettings];
	blurView.frame = window.frame;
	[window addSubview:blurView];

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
	[window reloadWindowedAppsSection:RARunningAppsProvider.sharedInstance.runningApplications];
}

-(void) reloadOtherAppsSection
{
	[window reloadOtherAppsSection];
}

-(void) hideMissionControl:(BOOL)animated
{
	[RASnapshotProvider.sharedInstance storeSnapshotOfMissionControl:window];

	void (^destructor)() = ^{
		originalAppView = nil;
		_isShowingMissionControl = NO;
		[window deconstructComponents];
		window.hidden = YES;
		window = nil;
	};

	if (animated)
	{
		if (originalAppView)
			[UIView animateWithDuration:0.5 animations:^{
				originalAppView.frame = originalAppFrame;
			}];
		[UIView animateWithDuration:0.5 animations:^{ window.frame = swappedForOrientation(CGRectMake(0, -window.frame.size.height, window.frame.size.width, window.frame.size.height)); } completion:^(BOOL _) { destructor(); }];
	}
	else
	{
		if (originalAppView)
			originalAppView.frame = originalAppFrame;
		destructor();
	}

	[RADesktopManager.sharedInstance reshowDesktop];
	[RADesktopManager.sharedInstance.currentDesktop loadApps];
	[RAGestureManager.sharedInstance removeGestureWithIdentifier:@"com.efrederickson.reachapp.missioncontrol.dismissgesture"];
	overrideCC = NO;

	if (lastOpenedApp && lastOpenedApp.isRunning)
	{
		if ([RADesktopManager.sharedInstance isAppOpened:lastOpenedApp.bundleIdentifier] == NO)
		{
			[[%c(SBUIController) sharedInstance] activateApplicationAnimated:lastOpenedApp];
		}
		lastOpenedApp = nil; // Fix it opening the same app later if on the Homescreen
	}
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
	return self.isShowingMissionControl;
}

-(RAGestureCallbackResult) RAGestureCallback_handle:(UIGestureRecognizerState)state withPoint:(CGPoint)location velocity:(CGPoint)velocity forEdge:(UIRectEdge)edge
{
	static CGPoint initialCenter;

	if (state == UIGestureRecognizerStateEnded)
	{
		if (window.frame.origin.y + window.frame.size.height + velocity.y < UIScreen.mainScreen._interfaceOrientedBounds.size.height / 2)
		{
			// Close
			CGFloat distance = UIScreen.mainScreen._interfaceOrientedBounds.size.height - (window.frame.origin.y + window.frame.size.height);
			CGFloat duration = MIN(distance / velocity.y, 0.3);

			[UIView animateWithDuration:duration animations:^{
				window.center = CGPointMake(window.center.x, -initialCenter.y);
			} completion:^(BOOL _) {
				[self hideMissionControl:NO];
			}];
		}
		else
		{
			CGFloat distance = window.frame.size.height + window.frame.origin.y /* origin.y is less than 0 so the + is actually a - operation */;
			CGFloat duration = MIN(distance / velocity.y, 0.3);

			[UIView animateWithDuration:duration animations:^{
				window.center = initialCenter;
			}];
		}
	}
	else if (state == UIGestureRecognizerStateBegan)
	{
		initialCenter = window.center;
	}
	else
	{
		window.center = CGPointMake(window.center.x, location.y - initialCenter.y);
	}
	return RAGestureCallbackResultSuccess;
}

-(RAMissionControlWindow*) missionControlWindow { if (!window) [self createWindow]; return window; }
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