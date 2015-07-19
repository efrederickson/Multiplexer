#import "RAHostedAppView.h"

@interface RAHostedAppView () {
    NSTimer *verifyTimer;
    BOOL isPreloading;
    FBWindowContextHostManager *contextHostManager;
    UIActivityIndicatorView *activityView;
}
@end

@implementation RAHostedAppView
-(id) initWithBundleIdentifier:(NSString*)bundleIdentifier
{
	if (self = [super init])
	{
		self.bundleIdentifier = bundleIdentifier;
        self.autosizesApp = NO;
        self.isTopApp = NO;
        self.allowHidingStatusBar = YES;
	}
	return self;
}

-(void) _preloadOrAttemptToUpdateReachabilityCounterpart
{
    if (app)
    {
        if ([app mainScene])
        {
            isPreloading = NO;
            if (((SBReachabilityManager*)[%c(SBReachabilityManager) sharedInstance]).reachabilityModeActive)
            [[%c(SBWorkspace) sharedInstance] performSelector:@selector(RA_updateViewSizes) withObject:nil afterDelay:0.5]; // App is launched using ReachApp - animations commence. We have to wait for those animations to finish or this won't work.
        }
        else if (![app mainScene])
            [self preloadApp];
    }
}

-(void) setBundleIdentifier:(NSString*)value
{
    _orientation = UIInterfaceOrientationPortrait;
    _bundleIdentifier = value;
    app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:value];
}

-(void) preloadApp
{
    if (app == nil)
        return;
    isPreloading = YES;
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
    contextHostManager = [scene contextHostManager];

    FBSMutableSceneSettings *settings = [[scene mutableSettings] mutableCopy];
    if (!settings)
        return;

    SET_BACKGROUNDED(settings, NO);
    [scene _applyMutableSettings:settings withTransitionContext:nil completion:nil];

    [contextHostManager enableHostingForRequester:@"reachapp" orderFront:YES];
    view = [contextHostManager hostViewForRequester:@"reachapp" enableAndOrderFront:YES];

    view.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    //view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [self addSubview:view];

    if (verifyTimer)
        [verifyTimer invalidate];

    verifyTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(verifyHostingAndRehostIfNecessary) userInfo:nil repeats:YES];
    [NSRunLoop.currentRunLoop addTimer:verifyTimer forMode:NSRunLoopCommonModes];

    if (!activityView)
    {
        activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self addSubview:activityView];
    }

    CGFloat size = 50;
    activityView.frame = CGRectMake((self.frame.size.width - size) / 2, (self.frame.size.height - size) / 2, size, size);

    [activityView startAnimating];
}

-(void) verifyHostingAndRehostIfNecessary
{
    if (!isPreloading && (app.isRunning == NO || view.contextHosted == NO)) // && (app.pid == 0 || view == nil || view.manager == nil)) // || view._isReallyHosting == NO))
    {
        [activityView startAnimating];
        [self unloadApp];
        [self loadApp];
    }
    else
        [activityView stopAnimating];
}

-(void) setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [view setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];

    if (self.autosizesApp)
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[@"sizeWidth"] = @(frame.size.width);
        dict[@"sizeHeight"] = @(frame.size.height);
        dict[@"bundleIdentifier"] = self.bundleIdentifier;
        dict[@"isTopApp"] = @(self.isTopApp);
        dict[@"rotationMode"] = @NO;
        dict[@"hideStatusBarIfWanted"] = @(self.allowHidingStatusBar);
        CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.beginresizing"), NULL, (__bridge CFDictionaryRef)dict, true);
    }
    else if (self.bundleIdentifier)
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[@"bundleIdentifier"] = self.bundleIdentifier;
        CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.endresizing"), NULL, (__bridge CFDictionaryRef)dict, true);
    }
}

-(void) setHideStatusBar:(BOOL)value
{
    _hideStatusBar = value;

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"bundleIdentifier"] = self.bundleIdentifier;
    dict[@"hideStatusBar"] = @(value);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.updateStatusBar"), NULL, (__bridge CFDictionaryRef)dict, true);
}

-(void) unloadApp
{
    if (activityView)
        [activityView stopAnimating];
    [verifyTimer invalidate];
	FBScene *scene = [app mainScene];

    if (!scene) return;
    CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.endresizing"), NULL, (__bridge CFDictionaryRef)@{ @"bundleIdentifier": self.bundleIdentifier }, NO);   

    FBSMutableSceneSettings *settings = [[scene mutableSettings] mutableCopy];
    SET_BACKGROUNDED(settings, YES);
    [scene _applyMutableSettings:settings withTransitionContext:nil completion:nil];
    //FBWindowContextHostManager *contextHostManager = [scene contextHostManager];
    [contextHostManager disableHostingForRequester:@"reachapp"];
    contextHostManager = nil;
}

-(void) rotateToOrientation:(UIInterfaceOrientation)o
{
    _orientation = o;
    NSString *event = @"";
    // force the last app to orient to the current apps orientation
    if (o == UIInterfaceOrientationLandscapeRight)
        event = @"com.efrederickson.reachapp.forcerotation-right";
    else if (o == UIInterfaceOrientationLandscapeLeft)
        event = @"com.efrederickson.reachapp.forcerotation-left";
    else if (o == UIInterfaceOrientationPortrait)
        event = @"com.efrederickson.reachapp.forcerotation-portrait";
    else if (o == UIInterfaceOrientationPortraitUpsideDown)
        event = @"com.efrederickson.reachapp.forcerotation-upsidedown";

    CFMutableDictionaryRef dictionary = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionaryAddValue(dictionary,  (__bridge const void*)@"bundleIdentifier",  (__bridge const void*)self.bundleIdentifier);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), (__bridge CFStringRef)event, NULL, dictionary, true);
    CFRelease(dictionary);
}

// This allows for any subviews with gestures (e.g. the SwipeOver bar with a negative y origin) to recieve touch events.
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event 
{
    BOOL isContained = NO;
    for (UIView *subview in self.subviews)
    {
        if (CGRectContainsPoint(subview.frame, point)) // [self convertPoint:point toView:view]))
            isContained = YES;
    }
    return isContained;
}

-(SBApplication*) app { return app; }
-(NSString*) displayName { return app.displayName; }
@end