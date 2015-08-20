#import "headers.h"
#import "RADesktopManager.h"
#import "RAGestureManager.h"
#import "RASettings.h"
#import "RAHostManager.h"
#import "RABackgrounder.h"
#import "RASwipeOverManager.h"
#import "RAWindowStatePreservationSystemManager.h"

BOOL overrideCC = NO;

%hook SBUIController
- (void)_showControlCenterGestureBeganWithLocation:(CGPoint)arg1
{
    if (!overrideCC)
        %orig;
}

- (void)handleShowControlCenterSystemGesture:(unsafe_id)arg1
{
    if (!overrideCC)
        %orig;
}
%end

BOOL locationIsInValidArea(CGFloat x)
{
    if (x == 0) return YES; // more than likely, UIGestureRecognizerStateEnded

    switch ([RASettings.sharedInstance windowedMultitaskingGrabArea])
    {
        case RAGrabAreaBottomLeftThird:
            return x <= UIScreen.mainScreen._interfaceOrientedBounds.size.width / 3.0;
        case RAGrabAreaBottomMiddleThird:
            return x >= UIScreen.mainScreen._interfaceOrientedBounds.size.width / 3.0 && x <= (UIScreen.mainScreen._interfaceOrientedBounds.size.width / 3.0) * 2;
        case RAGrabAreaBottomRightThird:
            return x >= (UIScreen.mainScreen._interfaceOrientedBounds.size.width / 3.0) * 2;
        default:
            return NO;
    }
}

%ctor
{
    __weak __block UIView *appView = nil;
    __block CGFloat lastY = 0;
    __block CGPoint originalCenter;
    [[RAGestureManager sharedInstance] addGestureRecognizer:^RAGestureCallbackResult(UIGestureRecognizerState state, CGPoint location, CGPoint velocity) {

        SBApplication *topApp = [[UIApplication sharedApplication] _accessibilityFrontMostApplication];

        // Dismiss potential CC
        //[[%c(SBUIController) sharedInstance] _showControlCenterGestureEndedWithLocation:CGPointMake(0, UIScreen.mainScreen.bounds.size.height - 1) velocity:CGPointZero];

        if (state == UIGestureRecognizerStateBegan)
        {
            overrideCC = YES;

            // Show HS/Wallpaper
            [[%c(SBWallpaperController) sharedInstance] beginRequiringWithReason:@"BeautifulAnimation"];
            [[%c(SBUIController) sharedInstance] restoreContentAndUnscatterIconsAnimated:NO];

            // Assign view
            appView = [RAHostManager systemHostViewForApplication:topApp].superview;
            originalCenter = appView.center;
        }
        else if (state == UIGestureRecognizerStateChanged)
        {
            lastY = location.y;
            CGFloat scale = location.y / UIScreen.mainScreen._interfaceOrientedBounds.size.height;
            scale = MIN(MAX(scale, 0.3), 1); // .01 for hasWindowInformation

            if (NO && [RAWindowStatePreservationSystemManager.sharedInstance hasWindowInformationForIdentifier:topApp.bundleIdentifier])
            {
                CGFloat actualScale = scale;
                scale = 1 - scale;
                RAPreservedWindowInformation info = [RAWindowStatePreservationSystemManager.sharedInstance windowInformationForAppIdentifier:topApp.bundleIdentifier];

                CGPoint center = CGPointMake(
                    originalCenter.x - (info.center.x * scale),
                    originalCenter.y - (info.center.y * scale)
                );

                center = CGPointMake(
                    MAX(originalCenter.x * actualScale, fabs(info.center.x - (originalCenter.x * actualScale))),
                    MAX(originalCenter.y * actualScale, fabs(info.center.y - (originalCenter.y * actualScale)))
                );


                CGFloat currentRotation = (M_PI * 2) - (atan2(info.transform.b, info.transform.a) * scale);
                CGFloat currentScale = 1 - (sqrt(info.transform.a * info.transform.a + info.transform.c * info.transform.c) * scale);
                CGAffineTransform transform = CGAffineTransformRotate(CGAffineTransformMakeScale(currentScale, currentScale), currentRotation);

                appView.center = center;
                appView.transform = transform;
            }
            else
                appView.transform = CGAffineTransformMakeScale(scale, scale);
        }
        else if (state == UIGestureRecognizerStateEnded)
        {
            overrideCC = NO;

            if (lastY <= (UIScreen.mainScreen._interfaceOrientedBounds.size.height / 4) * 3 && lastY != 0) // 75% down, 0 == gesture ended in most situations
            {
                [UIView animateWithDuration:.3 animations:^{

                    if ([RAWindowStatePreservationSystemManager.sharedInstance hasWindowInformationForIdentifier:topApp.bundleIdentifier])
                    {
                        RAPreservedWindowInformation info = [RAWindowStatePreservationSystemManager.sharedInstance windowInformationForAppIdentifier:topApp.bundleIdentifier];
                        appView.center = info.center;
                        appView.transform = info.transform;
                    }
                    else
                    {
                        appView.transform = CGAffineTransformMakeScale(0.5, 0.5);
                        appView.center = originalCenter;   
                    }
                } completion:^(BOOL _) {
                    // Close app
                    //[RABackgrounder.sharedInstance temporarilyApplyBackgroundingMode:RABackgroundModeForcedForeground forApplication:UIApplication.sharedApplication._accessibilityFrontMostApplication andCloseForegroundApp:NO];
                    FBWorkspaceEvent *event = [%c(FBWorkspaceEvent) eventWithName:@"ActivateSpringBoard" handler:^{
                        SBAppToAppWorkspaceTransaction *transaction = [[%c(SBAppToAppWorkspaceTransaction) alloc] initWithAlertManager:nil exitedApp:UIApplication.sharedApplication._accessibilityFrontMostApplication];
                        [transaction begin];
                    }];
                    [(FBWorkspaceEventQueue*)[%c(FBWorkspaceEventQueue) sharedInstance] executeOrAppendEvent:event];
                [[%c(SBWallpaperController) sharedInstance] endRequiringWithReason:@"BeautifulAnimation"];
                    // Open in window
                    [RADesktopManager.sharedInstance.currentDesktop createAppWindowForSBApplication:topApp animated:YES];
                }];
            }
            else
            {
                appView.center = originalCenter;
                [UIView animateWithDuration:0.2 animations:^{ appView.transform = CGAffineTransformIdentity; }];
                [[%c(SBWallpaperController) sharedInstance] endRequiringWithReason:@"BeautifulAnimation"];
            }

        }

        return RAGestureCallbackResultSuccess;
    } withCondition:^BOOL(CGPoint location, CGPoint velocity) {
        return [RASettings.sharedInstance windowedMultitaskingEnabled] && locationIsInValidArea(location.x) && ![RASwipeOverManager.sharedInstance isUsingSwipeOver] && ![[%c(SBUIController) sharedInstance] isAppSwitcherShowing] && ![[%c(SBLockScreenManager) sharedInstance] isUILocked] && [UIApplication.sharedApplication _accessibilityFrontMostApplication] != nil;
    } forEdge:UIRectEdgeBottom identifier:@"com.efrederickson.reachapp.windowedmultitasking.systemgesture" priority:RAGesturePriorityDefault];
}