#import "headers.h"

BOOL overrideViewControllerDismissal = NO;

%hook UIApplication
- (void)_deactivateReachability
{
    if (overrideViewControllerDismissal)
        return;
    %orig;
}
%end

%hook UIWindow
- (void)makeKeyAndVisible
{
    overrideViewControllerDismissal = YES;
    %orig;
    overrideViewControllerDismissal = NO;
}
%end

%hook UIViewController
- (void)_presentViewController:(unsafe_id)viewController withAnimationController:(unsafe_id)animationController completion:(unsafe_id)completion
{
    overrideViewControllerDismissal = YES;
    %orig;
    overrideViewControllerDismissal = NO;
}

- (void)dismissViewControllerWithTransition:(unsafe_id)transition completion:(unsafe_id)completion
{
    overrideViewControllerDismissal = YES;
    %orig;
    overrideViewControllerDismissal = NO;
}
%end

%hook UINavigationController
- (void)pushViewController:(unsafe_id)viewController transition:(unsafe_id)transition forceImmediate:(BOOL)immediate
{
    overrideViewControllerDismissal = YES;
    %orig;
    overrideViewControllerDismissal = NO;
}

- (id)_popViewControllerWithTransition:(unsafe_id)transition allowPoppingLast:(BOOL)last
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
- (void)moveFromPlacement:(unsafe_id)arg1 toPlacement:(unsafe_id)arg2 starting:(unsafe_id)arg3 completion:(unsafe_id)arg4
{
    overrideViewControllerDismissal = YES;
    %orig;
    overrideViewControllerDismissal = NO;
}
%end