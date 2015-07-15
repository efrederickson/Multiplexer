#import "RADesktopWindow.h"
#import "RAWindowBar.h"

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
	view.frame = CGRectMake(0, 100, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
	view.center = self.center;

	RAWindowBar *windowBar = [[RAWindowBar alloc] init];
	[windowBar attachView:view];
	[appViews addObject:view];

	if (animated)
		windowBar.alpha = 0;
	[self addSubview:windowBar];
	if (animated)
		[UIView animateWithDuration:0.5 animations:^{ windowBar.alpha = 1; }];

	[view loadApp];
	windowBar.transform = CGAffineTransformMakeScale(0.5, 0.5);

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
	while (appViews.count > 0)
	{
		[self removeAppWithIdentifier:((RAHostedAppView*)appViews[0]).bundleIdentifier animated:YES];
	}	
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event 
{
	BOOL isContained = NO;
	for (UIView *view in self.subviews)
	{
		if (CGRectContainsPoint(view.frame, point)) // [self convertPoint:point toView:view]))
			isContained = YES;
	}
	return isContained;
}
@end