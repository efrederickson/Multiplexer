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
Various tips and help: @sharedRoutine

Many concepts and ideas have been used from them.
*/

@interface SBWorkspace (ReachApp)
-(void)RA_launchTopAppWithIdentifier:(NSString*)bundleIdentifier;
@end

extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);
extern const char *__progname; 
extern "C" int xpc_connection_get_pid(id connection);

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

BOOL enabled = YES;
BOOL disableAutoDismiss = YES;
BOOL enableRotation = YES;
BOOL showNCInstead = NO;
BOOL homeButtonClosesReachability = YES;
BOOL showBottomGrabber = NO;
BOOL showAppSelector = YES;
BOOL scalingRotationMode = NO; 
BOOL autoSizeAppChooser = YES;
NSMutableArray *favorites = nil;
BOOL showAllAppsInAppChooser = YES;
BOOL showRecents = YES;
BOOL pagingEnabled = YES;

/*
@interface RAScrollViewDelegate : NSObject <UIScrollViewDelegate>
@end
@implementation RAScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)sender { sender.decelerationRate = UIScrollViewDecelerationRateFast; }
- (void)scrollViewDidEndDecelerating:(UIScrollView *)sender
{
	static BOOL isPaging = NO;
	if (isPaging == NO)
	{
		isPaging = YES;
		CGFloat pageWidth = sender.frame.size.width;
		int page = floor((sender.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
		
		CGRect frame;
		frame.origin.x = sender.frame.size.width * page;
		frame.origin.y = 0;
		frame.size = sender.frame.size;
		[UIView animateWithDuration:0.3 animations:^{
		    [sender scrollRectToVisible:frame animated:NO];
		} completion:^(BOOL finished) {
			isPaging = NO;
		}];
	}
}
@end
*/

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
				// Give them a little time to receive the notifications...
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

							if (view)
							{
								if ([view superview] != nil)
									[view removeFromSuperview];
							}

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
		//FBScene *scene = nil;

		currentBundleIdentifier = [[UIApplication sharedApplication] _accessibilityFrontMostApplication].bundleIdentifier;
		if (!currentBundleIdentifier)
			return;

		if (showAppSelector)
		{
			UIView *appSelectorView = [[UIView alloc] initWithFrame:w.frame];
			appSelectorView.backgroundColor = [UIColor clearColor];
			[appSelectorView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];

			CGFloat y = 10;
			CGSize contentSize = CGSizeZero;
			CGRect frame = CGRectZero;
			CGFloat oneRowHeight = -1;
			CGFloat oneRowWidth = -1;
			NSInteger width = 0;
			BOOL isTop = YES;
			BOOL hasSecondRow = NO;
			CGFloat interval = 0, intervalCount = 1, numIconsPerLine = 0, padding = 0;

			// Recents
			if (showRecents)
			{
				NSMutableArray *recents = [[[%c(SBAppSwitcherModel) sharedInstance] snapshotOfFlattenedArrayOfAppIdentifiersWhichIsOnlyTemporary] mutableCopy];
		   		[recents removeObject:currentBundleIdentifier];
				if (recents.count > 1) // item 1 = current app
				{
					UILabel *recentsLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 300, 20)];
					y += 30;
					recentsLabel.textColor = [UIColor whiteColor];
					recentsLabel.text = @"Recents";
					recentsLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:20]; // was HelveticaNeue-UltraLight
					[appSelectorView addSubview:recentsLabel];

					UIScrollView *recentsView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, y, appSelectorView.frame.size.width - 20, 20)];
					recentsView.backgroundColor = [UIColor clearColor];
					recentsView.pagingEnabled = pagingEnabled;
					contentSize = CGSizeMake(10, 10);
					for (NSString *str in recents)
					{
						app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:str];
				        SBIcon *icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForBundleIdentifier:app.bundleIdentifier];
				        SBIconView *iconView = [[%c(SBIconViewMap) homescreenMap] _iconViewForIcon:icon];
				        if (!iconView)
				        	continue;
				        
				        if (interval != 0 && contentSize.width + iconView.frame.size.width > interval * intervalCount)
						{
							if (isTop)
							{
								contentSize.height += oneRowHeight + 10;
								contentSize.width -= interval;
							}
							else
							{
								intervalCount++;
								contentSize.height -= (oneRowHeight + 10);
								width += interval;
							}
							hasSecondRow = YES;
							isTop = !isTop;
						}

				        iconView.frame = CGRectMake(contentSize.width, contentSize.height, iconView.frame.size.width, iconView.frame.size.height);
				        switch (UIApplication.sharedApplication.statusBarOrientation)
				        {
				        	case UIInterfaceOrientationLandscapeRight:
				        		iconView.frame = CGRectMake(contentSize.width + 15, contentSize.height, iconView.frame.size.width, iconView.frame.size.height);
				        		iconView.transform = CGAffineTransformMakeRotation(M_PI_2);
				        		break;
				        	case UIInterfaceOrientationLandscapeLeft:
				        		iconView.transform = CGAffineTransformMakeRotation(-M_PI_2);
				        		break;
				        	case UIInterfaceOrientationPortraitUpsideDown:
				        		appSelectorView.transform = CGAffineTransformMakeRotation(M_PI);
				        		break;
				        	case UIInterfaceOrientationPortrait:
				        	default:
				        		break;
				        }

				        iconView.tag = [app pid];
				        iconView.restorationIdentifier = app.bundleIdentifier;
				        UITapGestureRecognizer *iconViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(appViewItemTap:)];
				        [iconView addGestureRecognizer:iconViewTapGestureRecognizer];
				        if (oneRowHeight == -1)
				        {
				        	oneRowHeight = iconView.frame.size.height + 10;
				        	oneRowWidth = iconView.frame.size.width;
				        	while (interval + oneRowWidth <= recentsView.frame.size.width)
				        	{
				        		numIconsPerLine++;
					        	interval += oneRowWidth + 20;
				        	}
				        	padding = (recentsView.frame.size.width - (numIconsPerLine * oneRowWidth)) / numIconsPerLine;
				        	interval = (oneRowWidth + padding) * numIconsPerLine;
					        width = interval;
				        }
				        [recentsView addSubview:iconView];

				        contentSize.width += iconView.frame.size.width + padding;
					}
					contentSize.width = width;
					contentSize.height = 10 + ((oneRowHeight + 10) * (hasSecondRow ? 2 : 1));
					y += contentSize.height + 10;
					frame = recentsView.frame;
					frame.size.height = contentSize.height;
					recentsView.frame = frame;
					[recentsView setContentSize:contentSize];
					[appSelectorView addSubview:recentsView];
				}
			}

			// Favorites
			if (favorites.count > 0)
			{
				UILabel *favoritesLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 300, 20)];
				y += 30;
				favoritesLabel.textColor = [UIColor whiteColor];
				favoritesLabel.text = @"Favorites";
				favoritesLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:20]; // was HelveticaNeue-UltraLight
				[appSelectorView addSubview:favoritesLabel];

				UIScrollView *favoritesView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, y, appSelectorView.frame.size.width - 20, 20)];
				favoritesView.backgroundColor = [UIColor clearColor];
				favoritesView.pagingEnabled = pagingEnabled;
				contentSize = CGSizeMake(10, 10);
				for (NSString *str in favorites)
				{
					if ([currentBundleIdentifier isEqual:str] == NO && str && str.length > 0)
					{
						app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:str];
				        SBIcon *icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForBundleIdentifier:app.bundleIdentifier];
				        SBIconView *iconView = [[%c(SBIconViewMap) homescreenMap] _iconViewForIcon:icon];
				        if (!iconView)
				        	continue;

				        iconView.frame = CGRectMake(contentSize.width, contentSize.height, iconView.frame.size.width, iconView.frame.size.height);
				        switch (UIApplication.sharedApplication.statusBarOrientation)
				        {
				        	case UIInterfaceOrientationLandscapeRight:
				        		iconView.frame = CGRectMake(contentSize.width + 15, contentSize.height, iconView.frame.size.width, iconView.frame.size.height);
				        		iconView.transform = CGAffineTransformMakeRotation(M_PI_2);
				        		break;
				        	case UIInterfaceOrientationLandscapeLeft:
				        		iconView.transform = CGAffineTransformMakeRotation(-M_PI_2);
				        		break;
				        	case UIInterfaceOrientationPortraitUpsideDown:
				        		appSelectorView.transform = CGAffineTransformMakeRotation(M_PI);
				        		break;
				        	case UIInterfaceOrientationPortrait:
				        	default:
				        		break;
				        }

				        iconView.tag = [app pid];
				        iconView.restorationIdentifier = app.bundleIdentifier;
				        UITapGestureRecognizer *iconViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(appViewItemTap:)];
				        [iconView addGestureRecognizer:iconViewTapGestureRecognizer];
				        [favoritesView addSubview:iconView];
				        if (oneRowHeight == -1)
				        {
				        	oneRowHeight = iconView.frame.size.height + 10;
				        	oneRowWidth = iconView.frame.size.width;
				        	while (interval + oneRowWidth <= favoritesView.frame.size.width)
				        	{
				        		numIconsPerLine++;
					        	interval += oneRowWidth + 20;
				        	}
				        	padding = (favoritesView.frame.size.width - (numIconsPerLine * oneRowWidth)) / numIconsPerLine;
				        	interval = (oneRowWidth + padding) * numIconsPerLine;
					        width = interval;
				        }
				        contentSize.width += iconView.frame.size.width + padding;
					}
				}
				contentSize.height = oneRowHeight + 10;
				CGRect frame = favoritesView.frame;
				frame.size.height = contentSize.height + 10;
				favoritesView.frame = frame;
				[favoritesView setContentSize:contentSize];
				[appSelectorView addSubview:favoritesView];
				y += contentSize.height;
			}

			// All Apps
			if (showAllAppsInAppChooser)
			{
				UILabel *allAppsLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, appSelectorView.frame.size.width, 20)];
				y += 30;
				allAppsLabel.textColor = [UIColor whiteColor];
				allAppsLabel.text = @"All Apps";
				allAppsLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:20];
				[appSelectorView addSubview:allAppsLabel];

				UIScrollView *allAppsView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, y, appSelectorView.frame.size.width - 20, 20)];
				allAppsView.pagingEnabled = pagingEnabled;
				allAppsView.backgroundColor = [UIColor clearColor];
				NSMutableArray *allApps = [[[[%c(SBIconViewMap) homescreenMap] iconModel] visibleIconIdentifiers] mutableCopy];
			    [allApps sortUsingComparator: ^(NSString* a, NSString* b) {
			    	NSString *a_ = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:a].displayName;
			    	NSString *b_ = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:b].displayName;
			        return [a_ caseInsensitiveCompare:b_];
		   		}];
		   		[allApps removeObject:currentBundleIdentifier];
				width = interval;
				isTop = YES;
				contentSize = CGSizeMake(10, 10);
				intervalCount = 1;
				hasSecondRow = NO;
				for (NSString *str in allApps)
				{
					app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:str];
			        SBIcon *icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForBundleIdentifier:app.bundleIdentifier];
			        SBIconView *iconView = [[%c(SBIconViewMap) homescreenMap] _iconViewForIcon:icon];
			        if (!iconView || ![icon isKindOfClass:[%c(SBApplicationIcon) class]])
			        	continue;

			        if (interval != 0 && contentSize.width + iconView.frame.size.width > interval * intervalCount)
					{
						if (isTop)
						{
							contentSize.height += oneRowHeight + 10;
							contentSize.width -= interval;
						}
						else
						{
							intervalCount++;
							contentSize.height -= (oneRowHeight + 10);
							width += interval;
						}
						isTop = !isTop;
						hasSecondRow = YES;
					}

			        iconView.frame = CGRectMake(contentSize.width, contentSize.height, iconView.frame.size.width, iconView.frame.size.height);
			        switch (UIApplication.sharedApplication.statusBarOrientation)
			        {
			        	case UIInterfaceOrientationLandscapeRight:
			        		iconView.frame = CGRectMake(contentSize.width + 15, contentSize.height, iconView.frame.size.width, iconView.frame.size.height);
			        		iconView.transform = CGAffineTransformMakeRotation(M_PI_2);
			        		break;
			        	case UIInterfaceOrientationLandscapeLeft:
			        		iconView.transform = CGAffineTransformMakeRotation(-M_PI_2);
			        		break;
				        case UIInterfaceOrientationPortraitUpsideDown:
				        		appSelectorView.transform = CGAffineTransformMakeRotation(M_PI);
			        		break;
			        	case UIInterfaceOrientationPortrait:
			        	default:
			        		break;
			        }

			        iconView.tag = [app pid];
			        iconView.restorationIdentifier = app.bundleIdentifier;
			        UITapGestureRecognizer *iconViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(appViewItemTap:)];
			        [iconView addGestureRecognizer:iconViewTapGestureRecognizer];
			        [allAppsView addSubview:iconView];
			        if (oneRowHeight == -1)
			        {
			        	oneRowHeight = iconView.frame.size.height + 10;
			        	oneRowWidth = iconView.frame.size.width;
			        	while (interval + oneRowWidth <= allAppsView.frame.size.width)
			        	{
			        		numIconsPerLine++;
				        	interval += oneRowWidth + 20;
			        	}
			        	padding = (allAppsView.frame.size.width - (numIconsPerLine * oneRowWidth)) / numIconsPerLine;
			        	interval = (oneRowWidth + padding) * numIconsPerLine;
				        width = interval;
			        }
			        contentSize.width += iconView.frame.size.width + padding;
				}
				contentSize.width = width; //(oneRowHeight + 20) * (recents.count / 2) + 10;
				contentSize.height = 10 + ((oneRowHeight + 10) * (hasSecondRow ? 2 : 1));
				y += contentSize.height + 10;
				frame = allAppsView.frame;
				frame.size.height = contentSize.height;
				allAppsView.frame = frame;
				[allAppsView setContentSize:contentSize];
				[appSelectorView addSubview:allAppsView];
			}
			
			[w addSubview:appSelectorView];
			//NSLog(@"[ReachApp] app chooser just created: %@ %@", @(y), appSelectorView.superview);
			//appSelectorView.clipsToBounds = YES;
			view = appSelectorView;

			if (autoSizeAppChooser)
			{
				CGFloat moddedHeight = y;
				//if (moddedHeight > oneRowHeight * 3)
				//	moddedHeight = (oneRowHeight * 3) + 10;
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
	[self updateViewSizes:draggerView.center animate:NO];
}

%new -(void)handlePan:(UIPanGestureRecognizer*)sender
{
	UIView *view = draggerView; //sender.view;

	if (sender.state == UIGestureRecognizerStateBegan)
	{
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

	if ([view isKindOfClass:[%c(FBWindowContextHostWrapperView) class]] == NO)
		return; // only resize when the app is being shown. Otherwise it's more like native Reachability

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
		[UIView animateWithDuration:0.3
	             animations:^{
					view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.01, 0.01);
					view.alpha = 0;
	             }
	             completion:^(BOOL a){
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

		scalingRotationMode = [[info objectForKey:@"rotationMode"] boolValue];
		if (!scalingRotationMode)
		{
			overrideHeight = [[info objectForKey:@"sizeHeight"] floatValue];
			overrideWidth = [[info objectForKey:@"sizeWidth"] floatValue];
		}
		overrideDisplay = YES;


		if (!scalingRotationMode)
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
	scalingRotationMode = [prefs objectForKey:@"rotationMode"] != nil ? [prefs[@"rotationMode"] boolValue] : NO;
	autoSizeAppChooser = [prefs objectForKey:@"autoSizeAppChooser"] != nil ? [prefs[@"autoSizeAppChooser"] boolValue] : YES;
	showAllAppsInAppChooser = [prefs objectForKey:@"showAllAppsInAppChooser"] != nil ? [prefs[@"showAllAppsInAppChooser"] boolValue] : YES;
	showRecents = [prefs objectForKey:@"showRecents"] != nil ? [prefs[@"showRecents"] boolValue] : YES;
	pagingEnabled = [prefs objectForKey:@"pagingEnabled"] != nil ? [prefs[@"pagingEnabled"] boolValue] : YES;

	if (favorites)
	{
		[favorites release];
		favorites = nil;
	}
	favorites = [[[NSMutableArray alloc] init] retain];
	for (NSString *key in prefs.allKeys)
	{
		if ([key hasPrefix:@"Favorites-"])
		{
			NSString *ident = [key substringFromIndex:10];
			if ([prefs[key] boolValue])
				[favorites addObject:ident];
		}
	}
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