#import "headers.h"
#import "RADesktopManager.h"
#import "RAGestureManager.h"
#import "RASettings.h"
#import "RAHostManager.h"
#import "RABackgrounder.h"

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
        }
        else if (state == UIGestureRecognizerStateChanged)
        {
            lastY = location.y;
            CGFloat scale = location.y / UIScreen.mainScreen._interfaceOrientedBounds.size.height;
            scale = MIN(MAX(scale, 0.3), 1);
            appView.transform = CGAffineTransformMakeScale(scale, scale);
        }
        else if (state == UIGestureRecognizerStateEnded)
        {
            overrideCC = NO;

            if (lastY <= (UIScreen.mainScreen._interfaceOrientedBounds.size.height / 4) * 3 && lastY != 0) // 75% down, 0 == gesture ended in most situations
            {
                [UIView animateWithDuration:0.2 animations:^{
                    appView.transform = CGAffineTransformMakeScale(0.5, 0.5);
                } completion:^(BOOL _) {
                    // Close app
                    //[RABackgrounder.sharedInstance temporarilyApplyBackgroundingMode:RABackgroundModeForcedForeground forApplication:UIApplication.sharedApplication._accessibilityFrontMostApplication andCloseForegroundApp:NO];
                    FBWorkspaceEvent *event = [%c(FBWorkspaceEvent) eventWithName:@"ActivateSpringBoard" handler:^{
                        SBAppToAppWorkspaceTransaction *transaction = [[%c(SBAppToAppWorkspaceTransaction) alloc] initWithAlertManager:nil exitedApp:UIApplication.sharedApplication._accessibilityFrontMostApplication];
                        [transaction begin];
                    }];
                    [(FBWorkspaceEventQueue*)[%c(FBWorkspaceEventQueue) sharedInstance] executeOrAppendEvent:event];
                    // Open in window
                    [RADesktopManager.sharedInstance.currentDesktop createAppWindowForSBApplication:topApp animated:YES];
                }];
            }
            else            
                [UIView animateWithDuration:0.2 animations:^{ appView.transform = CGAffineTransformIdentity; }];

        }

        return RAGestureCallbackResultSuccess;
    } withCondition:^BOOL(CGPoint location, CGPoint velocity) {
        return [RASettings.sharedInstance windowedMultitaskingEnabled] && locationIsInValidArea(location.x) && ![[%c(SBUIController) sharedInstance] isAppSwitcherShowing] && ![[%c(SBLockScreenManager) sharedInstance] isUILocked] && [UIApplication.sharedApplication _accessibilityFrontMostApplication] != nil;
    } forEdge:UIRectEdgeBottom identifier:@"com.efrederickson.reachapp.windowedmultitasking.systemgesture" priority:RAGesturePriorityDefault];
}