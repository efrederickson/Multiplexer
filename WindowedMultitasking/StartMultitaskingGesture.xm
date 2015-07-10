#import "headers.h"
#import "RADesktopManager.h"
#import "RAGestureManager.h"

%ctor
{
    [[RAGestureManager sharedInstance] addGestureRecognizer:^RAGestureCallbackResult(UIGestureRecognizerState state, CGPoint location) {
        if (state == UIGestureRecognizerStateBegan)
        {
            [[%c(SBUIController) sharedInstance] _showControlCenterGestureEndedWithLocation:CGPointMake(0, UIScreen.mainScreen.bounds.size.height - 1) velocity:CGPointZero]; // Dismiss CC

            SBApplication *topApp = [[UIApplication sharedApplication] _accessibilityFrontMostApplication];
            FBWorkspaceEvent *event = [%c(FBWorkspaceEvent) eventWithName:@"ActivateSpringBoard" handler:^{
                SBDeactivationSettings *settings = [[%c(SBDeactivationSettings) alloc] init];
                [settings setFlag:YES forDeactivationSetting:20];
                [settings setFlag:NO forDeactivationSetting:2];
                [UIApplication.sharedApplication._accessibilityFrontMostApplication _setDeactivationSettings:settings];
         
                SBAppToAppWorkspaceTransaction *transaction = [[%c(SBAppToAppWorkspaceTransaction) alloc] initWithAlertManager:nil exitedApp:UIApplication.sharedApplication._accessibilityFrontMostApplication];
                [transaction begin];
            }];
            [(FBWorkspaceEventQueue*)[%c(FBWorkspaceEventQueue) sharedInstance] executeOrAppendEvent:event];
            [RADesktopManager.sharedInstance.currentDesktop createAppWindowForSBApplication:topApp animated:YES];   
        }
        return RAGestureCallbackResultSuccess;
    } withCondition:^BOOL(CGPoint location) {
        return location.x <= 100 && ![[%c(SBLockScreenManager) sharedInstance] isUILocked] && [UIApplication.sharedApplication _accessibilityFrontMostApplication] != nil;
    } forEdge:UIRectEdgeBottom identifier:@"com.efrederickson.reachapp.windowedmultitasking.systemgesture" priority:RAGesturePriorityDefault];
}