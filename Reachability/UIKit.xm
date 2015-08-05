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
- (void)_presentViewController:(__unsafe_unretained id)viewController withAnimationController:(__unsafe_unretained id)animationController completion:(__unsafe_unretained id)completion
{
    overrideViewControllerDismissal = YES;
    %orig;
    overrideViewControllerDismissal = NO;
}

- (void)dismissViewControllerWithTransition:(__unsafe_unretained id)transition completion:(__unsafe_unretained id)completion
{
    overrideViewControllerDismissal = YES;
    %orig;
    overrideViewControllerDismissal = NO;
}
%end

%hook UINavigationController
- (void)pushViewController:(__unsafe_unretained id)viewController transition:(__unsafe_unretained id)transition forceImmediate:(BOOL)immediate
{
    overrideViewControllerDismissal = YES;
    %orig;
    overrideViewControllerDismissal = NO;
}

- (id)_popViewControllerWithTransition:(__unsafe_unretained id)transition allowPoppingLast:(BOOL)last
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
- (void)moveFromPlacement:(__unsafe_unretained id)arg1 toPlacement:(__unsafe_unretained id)arg2 starting:(__unsafe_unretained id)arg3 completion:(__unsafe_unretained id)arg4
{
    overrideViewControllerDismissal = YES;
    %orig;
    overrideViewControllerDismissal = NO;
}
%end