#import "headers.h"
#import "RASwipeOverManager.h"
#import "RASwipeOverOverlay.h"

#define SCREEN_WIDTH (UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation) ? UIScreen.mainScreen.bounds.size.height : UIScreen.mainScreen.bounds.size.width)
#define VIEW_WIDTH(x) (UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation) ? x.frame.size.height : x.frame.size.width)

@interface RASwipeOverManager () {
	RASwipeOverOverlay *overlayWindow;
	BOOL isLaunchingApp;

	CGFloat start;
}
@end

@implementation RASwipeOverManager
+(id) sharedInstance
{
	SHARED_INSTANCE(RASwipeOverManager);
}

-(void) startUsingSwipeOver
{
	start = 0;
	isUsingSwipeOver = YES;
	currentAppIdentifier = [[UIApplication sharedApplication] _accessibilityFrontMostApplication].bundleIdentifier;

	[self createEdgeView];
}

-(void) stopUsingSwipeOver
{
	[overlayWindow removeOverlayFromUnderlyingAppImmediately];

	if (currentAppIdentifier)
		CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.endresizing"), NULL, (__bridge CFDictionaryRef)@{ @"bundleIdentifier": currentAppIdentifier }, NO);

	isUsingSwipeOver = NO;
	currentAppIdentifier = nil;

	[UIView animateWithDuration:0.3 animations:^{
		overlayWindow.frame = CGRectMake(SCREEN_WIDTH, overlayWindow.frame.origin.y, overlayWindow.frame.size.width, overlayWindow.frame.size.height);
	} completion:^(BOOL _) {
		[self closeCurrentView];

		overlayWindow.hidden = YES;
		overlayWindow = nil;
	}];
}

-(BOOL) isUsingSwipeOver { return isUsingSwipeOver; }

-(void) createEdgeView
{
	overlayWindow = [[RASwipeOverOverlay alloc] initWithFrame:UIScreen.mainScreen.bounds];
	[overlayWindow makeKeyAndVisible];

	[overlayWindow showEnoughToDarkenUnderlyingApp];
	[self showApp:nil];
}

-(void) showApp:(NSString*)identifier
{
	[self closeCurrentView];

	SBApplication *app = nil;
    FBScene *scene = nil;

    if (identifier)
    {
        app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:identifier];
    }
    else
    {
	    NSMutableArray *bundleIdentifiers = [[%c(SBAppSwitcherModel) sharedInstance] snapshotOfFlattenedArrayOfAppIdentifiersWhichIsOnlyTemporary];
	    while (scene == nil && bundleIdentifiers.count > 0)
	    {
	        identifier = bundleIdentifiers[0];

	        if ([identifier isEqual:currentAppIdentifier])
	        {
	            [bundleIdentifiers removeObjectAtIndex:0];
	            continue;
	        }

	        app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:identifier];
	        break;
	    }
    }

    if (identifier == nil || identifier.length == 0)
        return;

    scene = [app mainScene];

    if (![app pid] || [app mainScene] == nil)
    {
    	if (!isLaunchingApp)
    	{
	    	[UIApplication.sharedApplication launchApplicationWithIdentifier:identifier suspended:YES];
	    	[[%c(FBProcessManager) sharedInstance] createApplicationProcessForBundleID:identifier];	

	    	UIView *tempView = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
	    	tempView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
	    	tempView.tag = RASWIPEOVER_VIEW_TAG;
	    	[overlayWindow addSubview:tempView];
    	}
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        	isLaunchingApp = YES;
            [self showApp:identifier];
        });
        return;
    }
    if (isLaunchingApp)
    	[[overlayWindow viewWithTag:RASWIPEOVER_VIEW_TAG] removeFromSuperview];
    isLaunchingApp = NO;

    FBSMutableSceneSettings *settings = [[scene mutableSettings] mutableCopy];
    SET_BACKGROUNDED(settings, NO);
    [scene _applyMutableSettings:settings withTransitionContext:nil completion:nil];

    FBWindowContextHostManager *contextHostManager = [scene contextHostManager];
    [contextHostManager enableHostingForRequester:@"reachapp" orderFront:YES];
    UIView *view = [contextHostManager hostViewForRequester:@"reachapp" enableAndOrderFront:YES];

    if (overlayWindow.isHidingUnderlyingApp == NO)
	    view.frame = CGRectMake(10, 0, view.frame.size.width, view.frame.size.height);
	else
		view.frame = CGRectMake(SCREEN_WIDTH, 0, view.frame.size.width, view.frame.size.height);

    view.tag = RASWIPEOVER_VIEW_TAG;
    [overlayWindow addSubview:view];
	currentHostingIdentifier = identifier;

	[self updateClientSizes:YES];
}

-(void) closeCurrentView
{
	[[overlayWindow currentView] removeFromSuperview];

	if (currentHostingIdentifier)
	{
		CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.endresizing"), NULL, (__bridge CFDictionaryRef)@{ @"bundleIdentifier": currentHostingIdentifier}, NO);
		SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:currentHostingIdentifier];

		if (app && app.pid && app.mainScene)
		{
	        FBScene *scene = [app mainScene];
	        FBSMutableSceneSettings *settings = [[scene mutableSettings] mutableCopy];
	        SET_BACKGROUNDED(settings, YES);
	        [scene _applyMutableSettings:settings withTransitionContext:nil completion:nil];
	        [[scene contextHostManager] disableHostingForRequester:@"reachapp"];
		}

		currentHostingIdentifier = nil;
	}
}

-(void) showAppSelector
{
	//[self closeCurrentView];
	[overlayWindow showAppSelector];
}

-(BOOL) isEdgeViewShowing
{
	return overlayWindow.frame.origin.x < SCREEN_WIDTH;
}

-(void) convertSwipeOverViewToSideBySide
{
	if (currentAppIdentifier == nil)
	{
		[self stopUsingSwipeOver];
		return;
	}
	[overlayWindow currentView].transform = CGAffineTransformIdentity;
	[overlayWindow removeOverlayFromUnderlyingApp];
	[overlayWindow currentView].frame = (CGRect) { { 10, 0 }, [overlayWindow currentView].frame.size };
	overlayWindow.frame = CGRectOffset(overlayWindow.frame, SCREEN_WIDTH / 2, 0);
	[self sizeViewForTranslation:CGPointZero state:UIGestureRecognizerStateEnded]; // force it
	[self updateClientSizes:YES];
}

-(void) updateClientSizes:(BOOL)reloadAppSelectorSizeNow
{
	if (currentAppIdentifier)
	{
		CGFloat underWidth = [overlayWindow isHidingUnderlyingApp] ? -1 : overlayWindow.frame.origin.x;
		SEND_RESIZE_TO_UNDERLYING_APP(CGSizeMake(underWidth, -1));
	}
	
	if (currentHostingIdentifier == nil && overlayWindow.isShowingAppSelector)
	{
		if (reloadAppSelectorSizeNow)
			[self showAppSelector];
	}
	else if (currentHostingIdentifier)
	{
		if ([overlayWindow isHidingUnderlyingApp])
		{

		}
		else
		{
			CGFloat overWidth = [overlayWindow isHidingUnderlyingApp] ? overlayWindow.frame.size.width : SCREEN_WIDTH - overlayWindow.frame.origin.x;
			SEND_RESIZE_TO_OVERLYING_APP(CGSizeMake(overWidth, -1));	
		}
	}
}

-(void) sizeViewForTranslation:(CGPoint)translation state:(UIGestureRecognizerState)state
{
	UIView *targetView = [overlayWindow isHidingUnderlyingApp] ? [overlayWindow viewWithTag:RASWIPEOVER_VIEW_TAG] : overlayWindow;

	if (start == 0)
		start = targetView.center.x;
	
	if (state == UIGestureRecognizerStateEnded)
	{
		start = 0;

		CGFloat scale = (SCREEN_WIDTH - targetView.frame.origin.x) / [overlayWindow currentView].bounds.size.width;
		if (scale <= 0.12 && (!CGPointEqualToPoint(translation, CGPointZero)))
		{
			[self stopUsingSwipeOver]; 
			return;
		}
	}
	else
	{
		//if (start + translation.x + (targetView.frame.size.width / 2) < UIScreen.mainScreen.bounds.size.width && [overlayWindow isHidingUnderlyingApp])
		//	return;
		if (start + translation.x + targetView.frame.size.width - (targetView.frame.size.width / 2) < 0)
			return;

		if (overlayWindow.isHidingUnderlyingApp && [[overlayWindow currentView] isKindOfClass:[UIScrollView class]] == NO)
		{
			targetView.center = (CGPoint) { start + translation.x, targetView.center.y };
			CGFloat scale = (SCREEN_WIDTH - targetView.frame.origin.x) / [overlayWindow currentView].bounds.size.width;
			scale = MIN(MAX(scale, 0.1), 0.98);
			targetView.transform = CGAffineTransformMakeScale(scale, scale);
			targetView.center = (CGPoint) { SCREEN_WIDTH - (targetView.frame.size.width / 2), targetView.center.y };
		} 
		else
			targetView.center = (CGPoint) { start + translation.x, targetView.center.y };
	}

	if (state == UIGestureRecognizerStateEnded)
	{
		overlayWindow.frame = (CGRect) { overlayWindow.frame.origin, { SCREEN_WIDTH - overlayWindow.frame.origin.x, overlayWindow.frame.size.height } };

		if (targetView.frame.origin.x > SCREEN_WIDTH)
			[self stopUsingSwipeOver];
	}
	[self updateClientSizes:state == UIGestureRecognizerStateEnded];
}
@end