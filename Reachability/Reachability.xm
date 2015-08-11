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
#import "RAWidgetSectionManager.h"
#import "RASettings.h"
#import "RAAppSliderProviderView.h"
#import "RADesktopManager.h"
#import "RADesktopWindow.h"
#import "RAMessagingServer.h"

#define SPRINGBOARD ([NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"])

/*FBWindowContextHostWrapperView*/ UIView *view = nil;
NSString *lastBundleIdentifier = @"";
NSString *currentBundleIdentifier = @"";
UIViewController *ncViewController = nil;
UIView *draggerView = nil;

BOOL overrideOrientation = NO;
CGFloat grabberCenter_Y = -1;
CGPoint firstLocation = CGPointZero;
CGFloat grabberCenter_X = 0;
BOOL showingNC = NO;
BOOL overrideDisableForStatusBar = NO;
CGRect pre_topAppFrame = CGRectZero;
CGAffineTransform pre_topAppTransform = CGAffineTransformIdentity;
UIView *bottomDraggerView = nil;
CGFloat old_grabberCenterY = -1;

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
    if ((view || showingNC) && [RASettings.sharedInstance disableAutoDismiss])
        return;
    %orig;
}

- (void)_handleSignificantTimeChanged
{
    if ((view || showingNC) && [RASettings.sharedInstance disableAutoDismiss])
        return;
    %orig;
}

- (void)_keepAliveTimerFired:(unsafe_id)arg1
{
    if ((view || showingNC) && [RASettings.sharedInstance disableAutoDismiss])
        return;
    %orig;
}

- (void)deactivateReachabilityModeForObserver:(unsafe_id)arg1
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

- (void)_updateReachabilityModeActive:(_Bool)arg1 withRequestingObserver:(unsafe_id)arg2
{
    if (overrideDisableForStatusBar)
        return;
    %orig;
}
%end

BOOL wasEnabled = NO;
id SBWorkspace$sharedInstance;
%hook SBWorkspace

%new +(id) sharedInstance
{
    return SBWorkspace$sharedInstance;
}

-(id) init
{
    SBWorkspace$sharedInstance = %orig;
    return SBWorkspace$sharedInstance;
}

%new -(BOOL) isUsingReachApp
{
    return (view || showingNC);
}

- (void)_exitReachabilityModeWithCompletion:(unsafe_id)arg1
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

%new -(void) RA_closeCurrentView
{
    // Notify both top and bottom apps Reachability is closing
    if (lastBundleIdentifier && lastBundleIdentifier.length > 0)
    {
        [RAMessagingServer.sharedInstance endResizingApp:lastBundleIdentifier completion:nil];
        [RAMessagingServer.sharedInstance setShouldUseExternalKeyboard:NO forApp:lastBundleIdentifier completion:nil];
    }
    if (currentBundleIdentifier)
        [RAMessagingServer.sharedInstance endResizingApp:currentBundleIdentifier completion:nil];
    if ([view isKindOfClass:[RAAppSliderProviderView class]])
    {
        [RAMessagingServer.sharedInstance endResizingApp:[((RAAppSliderProviderView*)view) currentBundleIdentifier] completion:nil];
        [RAMessagingServer.sharedInstance setShouldUseExternalKeyboard:NO forApp:[((RAAppSliderProviderView*)view) currentBundleIdentifier] completion:nil];
    }

    [RAMessagingServer.sharedInstance unforceStatusBarVisibilityForApp:currentBundleIdentifier completion:nil];
    [RAMessagingServer.sharedInstance setShouldUseExternalKeyboard:NO forApp:currentBundleIdentifier completion:nil];
        
    if ([RASettings.sharedInstance showNCInstead])
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
        SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:lastBundleIdentifier];

        if ([view isKindOfClass:[RAAppSliderProviderView class]])
        {
            [((RAAppSliderProviderView*)view) unload];
        }

        // Give them a little time to receive the notifications...
        if (view)
        {
            if ([view superview] != nil)
                [view removeFromSuperview];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if (lastBundleIdentifier && lastBundleIdentifier.length > 0)
            {
                if (app && [app pid] && [app mainScene])
                {
                    FBScene *scene = [app mainScene];
                    FBSMutableSceneSettings *settings = [[scene mutableSettings] mutableCopy];
                    SET_BACKGROUNDED(settings, YES);
                    [scene _applyMutableSettings:settings withTransitionContext:nil completion:nil];
                    MSHookIvar<FBWindowContextHostView*>([app mainScene].contextHostManager, "_hostView").frame = pre_topAppFrame;
                    MSHookIvar<FBWindowContextHostView*>([app mainScene].contextHostManager, "_hostView").transform = pre_topAppTransform;

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

- (void)_disableReachabilityImmediately:(_Bool)arg1
{
    if (overrideDisableForStatusBar)
        return;

    %orig;

    if (![RASettings.sharedInstance reachabilityEnabled])
    {
        return;
    }

    if (arg1 && wasEnabled)
    {
        wasEnabled = NO;
        [self RA_closeCurrentView];
        if (draggerView)
            draggerView = nil;

    }

}

- (void) handleReachabilityModeActivated
{
    %orig;
    if (![RASettings.sharedInstance reachabilityEnabled])
        return;
    wasEnabled = YES;

    UIWindow *w = MSHookIvar<UIWindow*>(self, "_reachabilityEffectWindow");
    if ([RASettings.sharedInstance showNCInstead])
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

        if ([RASettings.sharedInstance enableRotation])
        {
            [w _setRotatableViewOrientation:[UIApplication sharedApplication].statusBarOrientation updateStatusBar:YES duration:0.0 force:YES];
        }
    }
    else
    {
        currentBundleIdentifier = [[UIApplication sharedApplication] _accessibilityFrontMostApplication].bundleIdentifier;
        if (!currentBundleIdentifier)
            return;

        if ([RASettings.sharedInstance showWidgetSelector])
        {
            [self RA_showWidgetSelector];
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
    recognizer.delegate = (id<UIGestureRecognizerDelegate>)self;
    [draggerView addGestureRecognizer:recognizer];

    UILongPressGestureRecognizer *recognizer2 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(RA_handleLongPress:)];
    recognizer2.delegate = (id<UILongPressGestureRecognizerDelegate>)self;
    [draggerView addGestureRecognizer:recognizer2];

    UITapGestureRecognizer *recognizer3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(RA_detachAppAndClose:)];
    recognizer3.numberOfTapsRequired = 2;
    recognizer3.delegate = (id<UIGestureRecognizerDelegate>)self;
    [draggerView addGestureRecognizer:recognizer3];

    [w addSubview:draggerView];

    if ([RASettings.sharedInstance showBottomGrabber])
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

%new -(void)RA_showWidgetSelector
{
    if (view)
        [self RA_closeCurrentView];
    UIWindow *w = MSHookIvar<UIWindow*>(self, "_reachabilityEffectWindow");
    //CGSize iconSize = [%c(SBIconView) defaultIconImageSize];
    static CGSize fullSize = [%c(SBIconView) defaultIconSize];
    fullSize.height = fullSize.width; // otherwise it often looks like {60,74}
    CGFloat padding = 20;

    NSInteger numIconsPerLine = 0;
    CGFloat tmpWidth = 10;
    while (tmpWidth + fullSize.width <= w.frame.size.width)
    {
        numIconsPerLine++;
        tmpWidth += fullSize.width + 20;
    }
    padding = (w.frame.size.width - (numIconsPerLine * fullSize.width)) / numIconsPerLine;

    UIView *widgetSelectorView = [[RAWidgetSectionManager sharedInstance] createViewForEnabledSectionsWithBaseFrame:w.frame preferredIconSize:fullSize iconsThatFitPerLine:numIconsPerLine spacing:padding];
    widgetSelectorView.frame = (CGRect){ { 0, 0 }, widgetSelectorView.frame.size };
    //widgetSelectorView.frame = w.frame;
    
    if (draggerView)
        [w insertSubview:widgetSelectorView belowSubview:draggerView];
    else
        [w addSubview:widgetSelectorView];
    view = widgetSelectorView;

    if ([RASettings.sharedInstance autoSizeWidgetSelector])
    {
        CGFloat moddedHeight = widgetSelectorView.frame.size.height;
        if (old_grabberCenterY == -1)
            old_grabberCenterY = UIScreen.mainScreen.bounds.size.height * 0.3;
        old_grabberCenterY = grabberCenter_Y;
        grabberCenter_Y = moddedHeight;
    }
    CGPoint newCenter = CGPointMake(draggerView.center.x, grabberCenter_Y);
    draggerView.center = newCenter;
    [self updateViewSizes:newCenter animate:YES];
}

CGFloat startingY = -1;
%new -(void)handlePan:(UIPanGestureRecognizer*)sender
{
    UIView *view = draggerView; //sender.view;

    if (sender.state == UIGestureRecognizerStateBegan)
    {
        startingY = grabberCenter_Y;
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
        if (startingY != -1 && fabs(grabberCenter_Y - startingY) < 3)
            [self RA_handleLongPress:nil];
        startingY = -1;
        [self updateViewSizes:view.center animate:YES];
    }
}

%new -(void) RA_handleLongPress:(UILongPressGestureRecognizer*)gesture
{
    [self RA_showWidgetSelector];
}

%new -(void) RA_detachAppAndClose:(UITapGestureRecognizer*)gesture
{
    NSString *ident = lastBundleIdentifier;
    if ([view isKindOfClass:[RAAppSliderProviderView class]])
    {
        RAAppSliderProviderView *temp = (RAAppSliderProviderView*)view;
        ident = temp.currentBundleIdentifier;
        [temp unload];
    }

    if (!ident || ident.length == 0)
        return;

    [self handleReachabilityModeDeactivated];
    [RADesktopManager.sharedInstance.currentDesktop createAppWindowWithIdentifier:ident animated:YES];
}

%new - (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([view isKindOfClass:[UIScrollView class]])
        return NO;
    return YES;
}

%new -(void) RA_updateViewSizes
{
    [self updateViewSizes:draggerView.center animate:YES];
}

%new -(void) updateViewSizes:(CGPoint) center animate:(BOOL)animate
{
    // Resizing
    UIWindow *topWindow = MSHookIvar<UIWindow*>(self,"_reachabilityEffectWindow");
    UIWindow *bottomWindow = MSHookIvar<UIWindow*>(self,"_reachabilityWindow");

    CGRect topFrame = CGRectMake(topWindow.frame.origin.x, topWindow.frame.origin.y, topWindow.frame.size.width, center.y);
    CGRect bottomFrame = CGRectMake(bottomWindow.frame.origin.x, center.y, bottomWindow.frame.size.width, UIScreen.mainScreen.bounds.size.height - center.y);

    if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeLeft)
    {
        topFrame = CGRectMake(topWindow.frame.origin.x, center.y, topWindow.frame.size.width, UIScreen.mainScreen.bounds.size.height - center.y);
        bottomFrame = CGRectMake(bottomWindow.frame.origin.x, bottomWindow.frame.origin.y, bottomWindow.frame.size.width, center.y);
    }

    if ([view isKindOfClass:[RAAppSliderProviderView class]])
    {
        RAAppSliderProviderView *sliderView = (RAAppSliderProviderView*)view;
        sliderView.frame = topFrame;
    }

    if ([RASettings.sharedInstance flipTopAndBottom])
    {
        CGRect tmp = topFrame;
        topFrame = bottomFrame;
        bottomFrame = tmp;
    }

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

    if ([RASettings.sharedInstance showNCInstead])
    {
        if (ncViewController)
            ncViewController.view.frame = (CGRect) { { 0, 0 }, topFrame.size };
    }
    else if (lastBundleIdentifier != nil || [view isKindOfClass:[RAAppSliderProviderView class]])
    {
        // Notify clients

        CGFloat width = - 1, height = -1;

        if ([view isKindOfClass:[RAAppSliderProviderView class]])
        {
            RAAppSliderProviderView *sliderView = (RAAppSliderProviderView*)view;
            width = sliderView.clientFrame.size.width;
            height = sliderView.clientFrame.size.height;
        }
        else
        {
            if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight)
            {
                width = topWindow.frame.size.height;
                height = topWindow.frame.size.width;
            }
            else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft)
            {
                width = topWindow.frame.size.height;
                height = topWindow.frame.size.width;
            }
            else
            {
                width = topWindow.frame.size.width;
                height = topWindow.frame.size.height;
            }
        }

        NSString *targetIdentifier = lastBundleIdentifier;
        if ([view isKindOfClass:[RAAppSliderProviderView class]])
            targetIdentifier = [((RAAppSliderProviderView*)view) currentBundleIdentifier];

        [RAMessagingServer.sharedInstance resizeApp:targetIdentifier toSize:CGSizeMake(width, height) completion:nil];
        [RAMessagingServer.sharedInstance setShouldUseExternalKeyboard:YES forApp:targetIdentifier completion:nil];
    }

    if ([view isKindOfClass:[%c(FBWindowContextHostWrapperView) class]] == NO && [view isKindOfClass:[RAAppSliderProviderView class]] == NO)
        return; // only resize when the app is being shown. That way it's more like native Reachability


    CGFloat width = -1, height = -1;

    if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight)
    {
        width = bottomWindow.frame.size.height;
        height = bottomWindow.frame.size.width;
    }
    else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft)
    {
        width = bottomWindow.frame.size.height;
        height = bottomWindow.frame.size.width;
    }
    else
    {
        width = bottomWindow.frame.size.width;
        height = bottomWindow.frame.size.height;
    }
    [RAMessagingServer.sharedInstance resizeApp:currentBundleIdentifier toSize:CGSizeMake(width, height) completion:nil];
    [RAMessagingServer.sharedInstance setShouldUseExternalKeyboard:YES forApp:currentBundleIdentifier completion:nil];

    if ([RASettings.sharedInstance unifyStatusBar])
        [RAMessagingServer.sharedInstance forceStatusBarVisibility:NO forApp:currentBundleIdentifier completion:nil];
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
    SET_BACKGROUNDED(settings, NO);
    [scene _applyMutableSettings:settings withTransitionContext:nil completion:nil];

    [contextHostManager enableHostingForRequester:@"reachapp" orderFront:YES];
    view = [contextHostManager hostViewForRequester:@"reachapp" enableAndOrderFront:YES];

    if (draggerView && draggerView.superview == w)
        [w insertSubview:view belowSubview:draggerView];
    else
        [w addSubview:view];

    if ([RASettings.sharedInstance enableRotation] && ![RASettings.sharedInstance scalingRotationMode])
    {
        [RAMessagingServer.sharedInstance rotateApp:lastBundleIdentifier toOrientation:[UIApplication sharedApplication].statusBarOrientation completion:nil];
    }
    else if ([RASettings.sharedInstance scalingRotationMode] && [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight)
    {
        overrideDisableForStatusBar = YES;

        // Force portrait
        [RAMessagingServer.sharedInstance rotateApp:lastBundleIdentifier toOrientation:UIInterfaceOrientationPortrait completion:nil];
        [RAMessagingServer.sharedInstance rotateApp:currentBundleIdentifier toOrientation:UIInterfaceOrientationPortrait completion:nil];

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

%new -(void) RA_setView:(UIView*)view_ preferredHeight:(CGFloat)pHeight
{
    view_.hidden = NO;
    UIWindow *w = MSHookIvar<UIWindow*>(self, "_reachabilityEffectWindow");
    if (view)
        [view removeFromSuperview];
    view = view_;
    [w addSubview:view];
    if (draggerView && draggerView.superview)
        [draggerView.superview bringSubviewToFront:draggerView];

    CGPoint center = (CGPoint){ draggerView.center.x, pHeight <= 0 ? draggerView.center.y : pHeight };
    [self updateViewSizes:center animate:YES];
    draggerView.center = center;
}

%new -(void) RA_animateWidgetSelectorOut:(id)completion
{
    [UIView animateWithDuration:0.3
    animations:^{
        view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.01, 0.01);
        view.alpha = 0;
    }
    completion:completion];
}

%new -(void) appViewItemTap:(UITapGestureRecognizer*)sender
{
    int pid = [sender.view tag];
    SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithPid:pid];
    if (!app)
        app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:sender.view.restorationIdentifier];

    if (app)
    {
        // before we re-assign view...
        [self RA_animateWidgetSelectorOut:^(BOOL a){
            [view removeFromSuperview];
            view = nil;

            lastBundleIdentifier = app.bundleIdentifier;
            [self RA_launchTopAppWithIdentifier:app.bundleIdentifier];

            if ([RASettings.sharedInstance autoSizeWidgetSelector])
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

%ctor
{
    if (SPRINGBOARD)
    {
        %init;            
    }
}