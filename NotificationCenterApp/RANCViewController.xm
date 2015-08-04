#import "RANCViewController.h"
#import "RAHostedAppView.h"
#import "RASettings.h"

@interface RANCViewController () {
	RAHostedAppView *appView;
	UILabel *isLockedLabel;

	NSTimer *activityViewCheckTimer;
}
@end

@implementation RANCViewController
-(void) forceReloadAppLikelyBecauseTheSettingChanged
{
	[appView unloadApp];
	[appView removeFromSuperview];
	appView = nil;
}


int patchOrientation(int in)
{
	if (in == 3)
		return 1;
	return in;
}

int rotationDegsForOrientation(int o)
{
	if (o == UIInterfaceOrientationLandscapeRight)
		return 270;
	else if (o == UIInterfaceOrientationLandscapeLeft)
		return 90;
	return 0;
}

-(void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	if (appView)
	{
		[appView loadApp];
	}
}

-(void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	if ([[%c(SBLockScreenManager) sharedInstance] isUILocked])
	{
		if (isLockedLabel == nil)
		{
			isLockedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 400)];
			isLockedLabel.numberOfLines = 2;
			isLockedLabel.textAlignment = NSTextAlignmentCenter;
			isLockedLabel.textColor = [UIColor whiteColor];
			isLockedLabel.font = [UIFont systemFontOfSize:36];
			[self.view addSubview:isLockedLabel];
		}

		isLockedLabel.frame = CGRectMake((self.view.frame.size.width - isLockedLabel.frame.size.width) / 2, (self.view.frame.size.height - isLockedLabel.frame.size.height) / 2, isLockedLabel.frame.size.width, isLockedLabel.frame.size.height);

		isLockedLabel.text = LOCALIZE(@"UNLOCK_FOR_NCAPP");
		return;
	}
	else if (isLockedLabel)
	{
		[isLockedLabel removeFromSuperview];
		isLockedLabel = nil;
	}

	if (!appView)
	{
		NSString *ident = [RASettings.sharedInstance NCApp];
		appView = [[RAHostedAppView alloc] initWithBundleIdentifier:ident];
		appView.frame = UIScreen.mainScreen.bounds;
		[self.view addSubview:appView];

		[appView preloadApp];
	}

	[appView loadApp];
	appView.hideStatusBar = YES;

	if (NO)// (UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation))
	{
		appView.autosizesApp = YES;
		appView.allowHidingStatusBar = YES;
		appView.transform = CGAffineTransformIdentity;
		appView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
	}
	else
	{
		appView.autosizesApp = NO;
		appView.allowHidingStatusBar = YES;

		// Reset
		appView.transform = CGAffineTransformIdentity;
		appView.frame = UIScreen.mainScreen.bounds;

		appView.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(rotationDegsForOrientation(UIApplication.sharedApplication.statusBarOrientation)));
		CGFloat scale = self.view.frame.size.height / UIScreen.mainScreen._interfaceOrientedBounds.size.height;
		appView.transform = CGAffineTransformScale(appView.transform, scale, scale);
		
		// Align vertically
		CGRect f = appView.frame;
		f.origin.y = 0;
		f.origin.x = (self.view.frame.size.width - f.size.width) / 2.0;
		appView.frame = f;
	}
	//[appView rotateToOrientation:UIApplication.sharedApplication.statusBarOrientation];

	activityViewCheckTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(checkIfAppIsRunningAtAllAndStopTimerIfSo) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:activityViewCheckTimer forMode:NSRunLoopCommonModes];
}

-(void) viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];

	[activityViewCheckTimer invalidate];

	appView.hideStatusBar = NO;
	[appView unloadApp];
}

-(void) checkIfAppIsRunningAtAllAndStopTimerIfSo
{
	// Whether started or (hopefully) showing
	if (appView.app.isRunning)
	{
		appView.hideStatusBar = YES; // verify status bar is hidden (doesn't happen the first load)
		//[appView rotateToOrientation:patchOrientation(UIApplication.sharedApplication.statusBarOrientation)];

		[activityViewCheckTimer invalidate];
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
