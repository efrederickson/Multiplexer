#import "RADesktopWindow.h"
#import "RAWindowBar.h"
#import "RAWindowStatePreservationSystemManager.h"
#import "RADesktopManager.h"
#import "RASnapshotProvider.h"

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

	view.frame = CGRectMake(0, 100, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
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

	[view loadApp];
	view.hideStatusBar = YES;
	windowBar.transform = CGAffineTransformMakeScale(0.5, 0.5);

	if ([RAWindowStatePreservationSystemManager.sharedInstance hasWindowInformationForIdentifier:view.app.bundleIdentifier])
	{
		RAPreservedWindowInformation info = [RAWindowStatePreservationSystemManager.sharedInstance windowInformationForAppIdentifier:view.app.bundleIdentifier];

		[UIView animateWithDuration:0.3 animations:^{
			windowBar.center = info.center;
			windowBar.transform = info.transform;
		}];
	}

	//[self saveInfo];

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
	return [self createAppWindowWithIdentifier:app.bundleIdentifier animated:(BOOL)animated];
}

-(RAWindowBar*) createAppWindowWithIdentifier:(NSString*)identifier animated:(BOOL)animated
{
	RAHostedAppView *view = [[RAHostedAppView alloc] initWithBundleIdentifier:identifier];
	return [self addAppWithView:view animated:(BOOL)animated];
}

-(void) removeAppWithIdentifier:(NSString*)identifier animated:(BOOL)animated
{
	for (RAHostedAppView *view in appViews)
	{
		if ([view.bundleIdentifier isEqual:identifier])
		{
			void (^destructor)() = ^{
				[view unloadApp];
				[view.superview removeFromSuperview];
				[view removeFromSuperview];
				[appViews removeObject:view];
				[self saveInfo];
			};
			if (animated)
				[UIView animateWithDuration:0.3 animations:^{
					view.superview.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1);
					view.superview.layer.position = CGPointMake(UIScreen.mainScreen.bounds.size.width / 2, UIScreen.mainScreen.bounds.size.height);
					view.superview.layer.opacity = 0.0f;
				//view.superview.alpha = 0; 
				} completion:^(BOOL _) { destructor(); }];
			else
				destructor();

			return;
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

-(BOOL) isAppOpened:(NSString*)identifier
{
	for (RAHostedAppView *app in appViews)
		if ([app.app.bundleIdentifier isEqual:identifier])
			return YES;
	return NO;
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
		if (CGRectContainsPoint(view.frame, point) || CGRectContainsPoint(view.frame, [view convertPoint:point fromView:self])) // [self convertPoint:point toView:view]))
			isContained = YES;
	}
	return isContained;
}
@end