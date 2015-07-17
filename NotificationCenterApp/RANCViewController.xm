#import "RANCViewController.h"
#import "RAHostedAppView.h"
#import "RASettings.h"

@interface RANCViewController () {
	RAHostedAppView *appView;
	UIActivityIndicatorView *activityView;

	NSTimer *activityViewCheckTimer;
}
@end

@implementation RANCViewController
-(void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	if (!activityView)
	{
		activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		[self.view addSubview:activityView];
	}

	CGFloat size = 50;
	activityView.frame = CGRectMake((self.view.frame.size.width - size) / 2, (self.view.frame.size.height - size) / 2, size, size);

	[activityView startAnimating];
}

-(void) forceReloadAppLikelyBecauseTheSettingChanged
{
	[appView unloadApp];
	appView = nil;
}


int patchOrientation(int in)
{
	if (in == 3)
		return 1;
	return in;
}

-(void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	if (!appView)
	{
		NSString *ident = [RASettings.sharedInstance NCApp] ?: @"com.apple.Preferences";
		appView = [[RAHostedAppView alloc] initWithBundleIdentifier:ident];
		appView.frame = UIScreen.mainScreen.bounds;
		[self.view addSubview:appView];

		[appView preloadApp];
	}

	[appView loadApp];
	appView.hideStatusBar = YES;

	if (UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation))
	{
		//appView.autosizesApp = YES;
		appView.transform = CGAffineTransformIdentity;
		appView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
	}
	else
	{
		appView.autosizesApp = NO;

		// Reset
		appView.transform = CGAffineTransformIdentity;
		appView.frame = UIScreen.mainScreen.bounds;

		CGFloat scale = self.view.frame.size.height / UIScreen.mainScreen.bounds.size.height;
		appView.transform = CGAffineTransformMakeScale(scale, scale);
		
		// Align vertically
		CGRect frame = appView.frame;
		frame.origin.y = 0;
		appView.frame = frame;
	}
//[appView rotateToOrientation:UIDevice.currentDevice.orientation];

	activityViewCheckTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(checkIfAppIsRunningAtAllAndStopTimerIfSo) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:activityViewCheckTimer forMode:NSRunLoopCommonModes];

	NSLog(@"[ReachApp] hello");
}

-(void) viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];

	[activityViewCheckTimer invalidate];
	[activityView stopAnimating];

	appView.hideStatusBar = NO;
	[appView unloadApp];

	NSLog(@"[ReachApp] bye");
}

-(void) checkIfAppIsRunningAtAllAndStopTimerIfSo
{
	// Whether started or (hopefully) showing
	if (appView.app.isRunning)
	{
		appView.hideStatusBar = YES; // verify status bar is hidden (doesn't happen the first load)
	[appView rotateToOrientation:patchOrientation(UIDevice.currentDevice.orientation)];

		[activityViewCheckTimer invalidate];
		[activityView stopAnimating];
	}
}

-(RAHostedAppView*) hostedApp { return appView; }

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	// Override
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
	if (signature == nil && class_respondsToSelector(%c(SBBulletinObserverViewController), aSelector)) 
		signature = [%c(SBBulletinObserverViewController) instanceMethodSignatureForSelector:aSelector];
	return signature;
}

- (BOOL)isKindOfClass:(Class)aClass
{
	if (aClass == %c(SBBulletinObserverViewController))
		return YES;
	else
		return [super isKindOfClass:aClass];
}
@end
