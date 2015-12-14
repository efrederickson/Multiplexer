#import "RADesktopWindow.h"
#import "RAWindowBar.h"
#import "RAWindowStatePreservationSystemManager.h"
#import "RADesktopManager.h"
#import "RASnapshotProvider.h"
#import "RAMessagingServer.h"
#import "RAFakePhoneMode.h"

@implementation RADesktopWindow
-(id) initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		appViews = [NSMutableArray array];
		self.windowLevel = 1000;
	}
	return self;
}

-(RAWindowBar*) addAppWithView:(RAHostedAppView*)view animated:(BOOL)animated
{
	// Avoid adding duplicates - if it already exists as a window, return the existing window
	for (RAWindowBar *bar in self.subviews)
		if ([bar isKindOfClass:[RAWindowBar class]]) // Just verify
			if (bar.attachedView.app == view.app)
				return bar;

	if ([RAFakePhoneMode shouldFakeForAppWithIdentifier:view.app.bundleIdentifier])
	{
		view.frame = (CGRect){ { 0, 100 }, [RAFakePhoneMode fakeSizeForAppWithIdentifier:view.app.bundleIdentifier] };
	}
	else
		view.frame = CGRectMake(0, 100, UIScreen.mainScreen._referenceBounds.size.width, UIScreen.mainScreen._referenceBounds.size.height);
	view.center = self.center;

	RAWindowBar *windowBar = [[RAWindowBar alloc] init];
	windowBar.desktop = self;
	[windowBar attachView:view];
	[appViews addObject:view];

	if (animated)
		windowBar.alpha = 0;
	[self addSubview:windowBar];
	if (animated)
		[UIView animateWithDuration:0.5 animations:^{ windowBar.alpha = 1; }];

	if (self.hidden == NO)
		[view loadApp];
	view.hideStatusBar = YES;
	windowBar.transform = CGAffineTransformMakeScale(0.5, 0.5);
	if (![RAFakePhoneMode shouldFakeForAppWithIdentifier:view.app.bundleIdentifier])
		windowBar.transform = CGAffineTransformRotate(windowBar.transform, DEGREES_TO_RADIANS([self baseRotationForOrientation]));
	windowBar.hidden = NO;

	lastKnownOrientation = -1;

	//view.shouldUseExternalKeyboard = YES;

	if ([RAWindowStatePreservationSystemManager.sharedInstance hasWindowInformationForIdentifier:view.app.bundleIdentifier])
	{
		RAPreservedWindowInformation info = [RAWindowStatePreservationSystemManager.sharedInstance windowInformationForAppIdentifier:view.app.bundleIdentifier];

		windowBar.center = info.center;
		windowBar.transform = info.transform;
		[UIView animateWithDuration:0.3 animations:^{
			windowBar.center = info.center;
			windowBar.transform = info.transform;
		} completion:^(BOOL _) {
			[windowBar updateClientRotation];	
			RADesktopManager.sharedInstance.lastUsedWindow = windowBar;
		}];
	}

	//[self saveInfo];
	[windowBar updateClientRotation];

	return windowBar;
}

-(void) addExistingWindow:(RAWindowBar*)window
{
	[appViews addObject:window.attachedView];
	[self addSubview:window];

	[self addAppWithView:window.attachedView animated:NO];
	((UIView*)self.subviews[self.subviews.count - 1]).transform = window.transform;
}

-(RAWindowBar*) createAppWindowForSBApplication:(SBApplication*)app animated:(BOOL)animated
{
	return [self createAppWindowWithIdentifier:app.bundleIdentifier animated:animated];
}

-(RAWindowBar*) createAppWindowWithIdentifier:(NSString*)identifier animated:(BOOL)animated
{
	RAHostedAppView *view = [[RAHostedAppView alloc] initWithBundleIdentifier:identifier];
	view.renderWallpaper = YES;
	return [self addAppWithView:view animated:animated];
}

-(void) removeAppWithIdentifier:(NSString*)identifier animated:(BOOL)animated
{
	[self removeAppWithIdentifier:identifier animated:animated forceImmediateUnload:NO];
}

-(void) removeAppWithIdentifier:(NSString*)identifier animated:(BOOL)animated forceImmediateUnload:(BOOL)force
{
	for (RAHostedAppView *view in appViews)
	{
		if ([view.bundleIdentifier isEqual:identifier])
		{
			void (^destructor)() = ^{
				//view.shouldUseExternalKeyboard = NO;
				[view unloadApp:force];
				[view.superview removeFromSuperview];
				[view removeFromSuperview];
				[appViews removeObject:view];
				[self saveInfo];

				if (dontClearForcedPhoneState == NO && [RAFakePhoneMode shouldFakeForAppWithIdentifier:identifier])
					[RAMessagingServer.sharedInstance forcePhoneMode:NO forIdentifier:identifier andRelaunchApp:YES];
			};
			if (animated)
				[UIView animateWithDuration:0.3 animations:^{
					view.superview.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1);
					view.superview.layer.position = CGPointMake(UIScreen.mainScreen._referenceBounds.size.width / 2, UIScreen.mainScreen._referenceBounds.size.height);
					view.superview.layer.opacity = 0.0f;
					[RADesktopManager.sharedInstance findNewForemostApp];
				//view.superview.alpha = 0; 
				} completion:^(BOOL _) { destructor(); }];
			else
				destructor();

			return;
		}
	}
}

-(void) updateWindowSizeForApplication:(NSString*)identifier
{
	NSArray *tempArrayToAvoidMutationCrash = [appViews copy];
	for (RAHostedAppView *view in tempArrayToAvoidMutationCrash)
	{
		if ([view.bundleIdentifier isEqual:identifier])
		{
			dontClearForcedPhoneState = YES;
			[self removeAppWithIdentifier:identifier animated:NO forceImmediateUnload:YES];
			[self createAppWindowWithIdentifier:identifier animated:NO];
			dontClearForcedPhoneState = NO;

			/*CGAffineTransform t = view.transform;
			CGPoint origin = view.frame.origin;

			view.transform = CGAffineTransformIdentity;
			if ([RAFakePhoneMode shouldFakeForAppWithIdentifier:view.app.bundleIdentifier])
				view.frame = (CGRect){ origin, [RAFakePhoneMode fakeSizeForAppWithIdentifier:view.app.bundleIdentifier] };
			else
				view.frame = CGRectMake(origin.x, origin.y, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);

			view.transform = t;*/
		}
	}
}

-(NSArray*) hostedWindows
{
	return appViews;
}

-(void) unloadApps
{
	for (RAHostedAppView *view in appViews)
		[view unloadApp];
}

-(void) loadApps
{
	for (RAHostedAppView *view in appViews)
		[view loadApp];
}

-(void) closeAllApps
{
	//while (appViews.count > 0)
	int i = appViews.count - 1;
	while (i --> 0) // Always wanted to use that 😍
	{
		[self removeAppWithIdentifier:((RAHostedAppView*)appViews[i]).bundleIdentifier animated:YES];
	}	
}

-(void) updateRotationOnClients:(UIInterfaceOrientation)orientation
{
	lastKnownOrientation = orientation;

	for (RAWindowBar *app in self.subviews)
		if ([app isKindOfClass:[RAWindowBar class]]) // could be a diferent kind of UIView actually
			[app updateClientRotation:orientation];	
}

-(BOOL) isAppOpened:(NSString*)identifier
{
	for (RAHostedAppView *app in appViews)
		if ([app.app.bundleIdentifier isEqual:identifier])
			return YES;
	return NO;
}

-(RAWindowBar*) windowForIdentifier:(NSString*)identifier
{
	for (UIView *view in self.subviews)
		if ([view isKindOfClass:[RAWindowBar class]])
		{
			RAWindowBar *bar = (RAWindowBar*)view;
			if ([bar.attachedView.app.bundleIdentifier isEqual:identifier])
				return bar;
		}
	return nil;
}

-(void) saveInfo
{
	[RAWindowStatePreservationSystemManager.sharedInstance saveDesktopInformation:self];
	[RASnapshotProvider.sharedInstance forceReloadSnapshotOfDesktop:self];
}

-(void) loadInfo
{
	NSInteger index = [RADesktopManager.sharedInstance.availableDesktops indexOfObject:self];
	if ([RAWindowStatePreservationSystemManager.sharedInstance hasDesktopInformationAtIndex:index] == NO)
		return;
	RAPreservedDesktopInformation info = [RAWindowStatePreservationSystemManager.sharedInstance desktopInformationForIndex:index];
	for (NSString *bundleIdentifier in info.openApps)
		[self createAppWindowWithIdentifier:bundleIdentifier animated:YES];
}

-(UIInterfaceOrientation) currentOrientation
{
	if (lastKnownOrientation >= 0)
		return lastKnownOrientation;
	return UIApplication.sharedApplication.statusBarOrientation;
}

-(CGFloat) baseRotationForOrientation
{
	UIInterfaceOrientation o = [self currentOrientation];
	if (o == UIInterfaceOrientationLandscapeRight)
		return 90;
	else if (o == UIInterfaceOrientationLandscapeLeft)
		return 270;
	else if (o == UIInterfaceOrientationPortraitUpsideDown)
		return 180;
	return 0;
}

-(UIInterfaceOrientation) appOrientationRelativeToThisOrientation:(CGFloat)currentRotation
{
	UIInterfaceOrientation base = [self currentOrientation];

	switch (base)
	{
		case UIInterfaceOrientationLandscapeLeft:
	    	if (currentRotation >= 315 || currentRotation <= 45)
	    		return UIInterfaceOrientationLandscapeLeft;
	    	else if (currentRotation > 45 && currentRotation <= 135)
	    		return UIInterfaceOrientationPortraitUpsideDown;
	    	else if (currentRotation > 135 && currentRotation <= 215)
	    		return UIInterfaceOrientationLandscapeRight;
	    	else
	    		return UIInterfaceOrientationPortrait;

		case UIInterfaceOrientationLandscapeRight:
	    	if (currentRotation >= 315 || currentRotation <= 45)
	    		return UIInterfaceOrientationLandscapeRight;
	    	else if (currentRotation > 45 && currentRotation <= 135)
	    		return UIInterfaceOrientationPortrait;
	    	else if (currentRotation > 135 && currentRotation <= 215)
	    		return UIInterfaceOrientationLandscapeLeft;
	    	else
	    		return UIInterfaceOrientationPortraitUpsideDown;

		case UIInterfaceOrientationPortraitUpsideDown:
			if (currentRotation >= 315 || currentRotation <= 45)
				return UIInterfaceOrientationPortraitUpsideDown;
			else if (currentRotation > 45 && currentRotation <= 135)
				return UIInterfaceOrientationLandscapeRight;
			else if (currentRotation > 135 && currentRotation <= 215)
				return UIInterfaceOrientationPortrait;
			else
				return UIInterfaceOrientationLandscapeLeft;

		case UIInterfaceOrientationPortrait:
		default:
			break;
	}

	if (currentRotation >= 315 || currentRotation <= 45)
	{
		return UIInterfaceOrientationPortrait;
	}
	else if (currentRotation > 45 && currentRotation <= 135)
	{
		return UIInterfaceOrientationLandscapeLeft;
	}
	else if (currentRotation > 135 && currentRotation <= 215)
	{
		return UIInterfaceOrientationPortraitUpsideDown;
	}
	else
	{
		return UIInterfaceOrientationLandscapeRight;
	}
}

-(void) loadInfo:(NSInteger)index
{
	if ([RAWindowStatePreservationSystemManager.sharedInstance hasDesktopInformationAtIndex:index] == NO)
		return;
	RAPreservedDesktopInformation info = [RAWindowStatePreservationSystemManager.sharedInstance desktopInformationForIndex:index];
	for (NSString *bundleIdentifier in info.openApps)
		[self createAppWindowWithIdentifier:bundleIdentifier animated:YES];
}

-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    NSEnumerator *objects = [self.subviews reverseObjectEnumerator];
    UIView *subview;
    while ((subview = [objects nextObject])) 
    {
    	if (self.rootViewController && [self.rootViewController.view isEqual:subview])
    		continue;
    	if (subview.hidden)
    		continue;
        UIView *success = [subview hitTest:[self convertPoint:point toView:subview] withEvent:event];
        if (success)
            return success;
    }
    return [super hitTest:point withEvent:event];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event 
{
	BOOL isContained = NO;
	for (UIView *view in self.subviews)
	{
    	if (self.rootViewController && [self.rootViewController.view isEqual:view])
    		continue;
    	if (view.hidden)
    		continue;
		if (CGRectContainsPoint(view.frame, point) || CGRectContainsPoint(view.frame, [view convertPoint:point fromView:self])) // [self convertPoint:point toView:view]))
			isContained = YES;
	}
	return isContained;
}
@end