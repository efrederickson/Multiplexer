#import "headers.h"
#import "RASwipeOverManager.h"
#import "RASwipeOverOverlay.h"
#import "RAHostedAppView.h"

#define SCREEN_WIDTH (UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation) ? UIScreen.mainScreen.bounds.size.height : UIScreen.mainScreen.bounds.size.width)
#define VIEW_WIDTH(x) (UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation) ? x.frame.size.height : x.frame.size.width)

@interface RASwipeOverManager () {
	RASwipeOverOverlay *overlayWindow;

	CGFloat start;
}
@end

@implementation RASwipeOverManager
+(id) sharedInstance
{
	SHARED_INSTANCE(RASwipeOverManager);
}

-(BOOL) isUsingSwipeOver { return isUsingSwipeOver; }
-(void) showAppSelector { [overlayWindow showAppSelector]; }
-(BOOL) isEdgeViewShowing { return overlayWindow.frame.origin.x < SCREEN_WIDTH; }

-(void) startUsingSwipeOver
{
	start = 0;
	isUsingSwipeOver = YES;
	currentAppIdentifier = [[UIApplication sharedApplication] _accessibilityFrontMostApplication].bundleIdentifier;

	[self createEdgeView];
}

-(void) stopUsingSwipeOver
{
	if (currentAppIdentifier)
	    CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.endresizing"), NULL, (__bridge CFDictionaryRef)@{ @"bundleIdentifier": currentAppIdentifier }, NO);   
	[overlayWindow removeOverlayFromUnderlyingAppImmediately];

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
        app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:identifier];
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

    RAHostedAppView *view = [[RAHostedAppView alloc] initWithBundleIdentifier:identifier];
    view.autosizesApp = YES;
    view.isTopApp = YES;
    view.allowHidingStatusBar = NO;
    view.frame = UIScreen.mainScreen.bounds;
    [view loadApp];

    if (overlayWindow.isHidingUnderlyingApp == NO)
	    view.frame = CGRectMake(10, 0, view.frame.size.width, view.frame.size.height);
	else
		view.frame = CGRectMake(SCREEN_WIDTH, 0, view.frame.size.width, view.frame.size.height);

    view.tag = RASWIPEOVER_VIEW_TAG;
    [overlayWindow addSubview:view];

	[self updateClientSizes:YES];
}

-(void) closeCurrentView
{
	if ([[overlayWindow currentView] isKindOfClass:[RAHostedAppView class]])
	{
		[((RAHostedAppView*)overlayWindow.currentView) unloadApp];
	}
	[[overlayWindow currentView] removeFromSuperview];
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
	
	if (overlayWindow.isShowingAppSelector && reloadAppSelectorSizeNow)
		[self showAppSelector];
	else if (overlayWindow.isHidingUnderlyingApp == NO) // Update swiped-over app. RAHostedAppView takes care of the app sizing if we resize the RAHostedAppView. 
		overlayWindow.currentView.frame = CGRectMake(10, 0, SCREEN_WIDTH - overlayWindow.frame.origin.x - 10, overlayWindow.currentView.frame.size.height);
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
		//if (start + translation.x + targetView.frame.size.width - (targetView.frame.size.width / 2) < 0 && [overlayWindow isHidingUnderlyingApp] == NO)
		//	return;

		if (overlayWindow.isHidingUnderlyingApp && [[overlayWindow currentView] isKindOfClass:[UIScrollView class]] == NO)
		{
			CGFloat scale = (SCREEN_WIDTH - (start + translation.x)) / [overlayWindow currentView].bounds.size.width;
			scale = MIN(MAX(scale, 0.1), 0.98);
			targetView.transform = CGAffineTransformMakeScale(scale, scale);
			targetView.center = (CGPoint) { SCREEN_WIDTH - (targetView.frame.size.width / 2), targetView.center.y };
		} 
		else
		{
			//targetView.frame = CGRectMake(SCREEN_WIDTH - (start + translation.x), 0, SCREEN_WIDTH - (SCREEN_WIDTH - start + translation.x), targetView.frame.size.height);
			targetView.center = (CGPoint) { start + translation.x, targetView.center.y };
		}
	}
	[self updateClientSizes:state == UIGestureRecognizerStateEnded];
}
@end