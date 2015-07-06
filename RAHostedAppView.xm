#import "RAHostedAppView.h"

@implementation RAHostedAppView
-(id) initWithBundleIdentifier:(NSString*)bundleIdentifier
{
	if (self = [super init])
	{
		self.bundleIdentifier = bundleIdentifier;
	}
	return self;
}

-(void) _preloadOrAttemptToUpdateReachabilityCounterpart
{
    if (app)
    {
        if ([app mainScene] && ((SBReachabilityManager*)[%c(SBReachabilityManager) sharedInstance]).reachabilityModeActive)
        {
            [[%c(SBWorkspace) sharedInstance] performSelector:@selector(RA_updateViewSizes) withObject:nil afterDelay:0.5]; // App is launched using ReachApp - animations commence. We have to wait for those animations to finish or this won't work.
        }
        else if (![app mainScene])
            [self preloadApp];
    }
}

-(void) preloadApp
{
	app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:self.bundleIdentifier];
    if (app == nil)
        return;
	FBScene *scene = [app mainScene];
    if (![app pid] || scene == nil)
    {
        [UIApplication.sharedApplication launchApplicationWithIdentifier:self.bundleIdentifier suspended:YES];
        [[%c(FBProcessManager) sharedInstance] createApplicationProcessForBundleID:self.bundleIdentifier];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [self _preloadOrAttemptToUpdateReachabilityCounterpart]; }); 
    // this ^ runs either way. when _preloadOrAttemptToUpdateReachabilityCounterpart runs, if the app is "loaded" it will not call preloadApp again, otherwise
    // it will call it again.
}

-(void) loadApp
{
	[self preloadApp];
    if (!app)
        return;

	FBScene *scene = [app mainScene];
    FBWindowContextHostManager *contextHostManager = [scene contextHostManager];

    FBSMutableSceneSettings *settings = [[scene mutableSettings] mutableCopy];
    SET_BACKGROUNDED(settings, NO);
    [scene _applyMutableSettings:settings withTransitionContext:nil completion:nil];

    [contextHostManager enableHostingForRequester:@"reachapp" orderFront:YES];
    view = [contextHostManager hostViewForRequester:@"reachapp" enableAndOrderFront:YES];

    view.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [self addSubview:view];
}

-(void) unloadApp
{
	FBScene *scene = [app mainScene];

    if (!scene) return;

    FBSMutableSceneSettings *settings = [[scene mutableSettings] mutableCopy];
    SET_BACKGROUNDED(settings, YES);
    [scene _applyMutableSettings:settings withTransitionContext:nil completion:nil];
    FBWindowContextHostManager *contextHostManager = [scene contextHostManager];
    [contextHostManager disableHostingForRequester:@"reachapp"];
}
@end