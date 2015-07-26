#import "headers.h"
#import "RAMissionControlWindow.h"
#import "RAMissionControlManager.h"
#import "RAMissionControlPreviewView.h"
#import "RADesktopWindow.h"
#import "RADesktopManager.h"
#import "RAWindowBar.h"
#import "RAHostedAppView.h"
#import "RASnapshotProvider.h"
#import "RAAppKiller.h"
#import "RAGestureManager.h"

extern BOOL overrideCC;

@interface RAMissionControlManager () {
	UIScrollView *desktopScrollView, *windowedAppScrollView, *otherRunningAppsScrollView;
	UILabel *desktopLabel, *windowedLabel, *otherLabel;
	
	UIImageView *trashImageView;
	UIImage *trashIcon;

	NSMutableArray *appsWithoutWindows;
	CGFloat width, height;
}
@end

@implementation RAMissionControlManager
+(instancetype) sharedInstance
{
	SHARED_INSTANCE2(RAMissionControlManager, 
		sharedInstance->runningApplications = [NSMutableArray array];
		sharedInstance->width = UIScreen.mainScreen.bounds.size.width / 4.5714;
		sharedInstance->height = UIScreen.mainScreen.bounds.size.height / 4.36;
		sharedInstance->trashIcon = [UIImage imageWithContentsOfFile:@"/Library/ReachApp/Trash.png"]
	);
}

-(UIImage*) renderPreviewForDesktop:(RADesktopWindow*)desktop
{
	UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, YES, [UIScreen mainScreen].scale);
	CGContextRef c = UIGraphicsGetCurrentContext();
	[MSHookIvar<UIWindow*>([%c(SBWallpaperController) sharedInstance], "_wallpaperWindow").layer renderInContext:c]; // Wallpaper
	[[[[%c(SBUIController) sharedInstance] window] layer] renderInContext:c]; // Icons
	[desktop.layer renderInContext:c]; // Desktop windows
	for (UIView *view in desktop.subviews) // Application views
	{
		if ([view isKindOfClass:[RAWindowBar class]])
		{
			RAHostedAppView *hostedView = [((RAWindowBar*)view) attachedView];

			UIImage *image = [RASnapshotProvider.sharedInstance snapshotForIdentifier:hostedView.bundleIdentifier];
			[image drawInRect:CGRectMake(view.frame.origin.x, [hostedView convertPoint:hostedView.frame.origin toView:nil].y, view.frame.size.width, view.frame.size.height)];

			/*SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:hostedView.bundleIdentifier];
			FBScene *scene = [app mainScene];
    		FBWindowContextHostManager *contextHostManager = [scene contextHostManager];
    		UIView *snapshotView = [contextHostManager snapshotViewWithFrame:hostedView.frame excludingContexts:@[] opaque:NO];
    		
			UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, YES, [UIScreen mainScreen].scale);
			CGContextRef c2 = UIGraphicsGetCurrentContext();
			//CGContextSetRGBFillColor(c2, 0, 0, 0, 0); // CGContextSetGrayFillColor
    		//snapshotView.layer.frame = (CGRect) { [desktop convertPoint:view.frame.origin toView:nil], view.frame.size };
    		//snapshotView.transform = view.transform;
    		[snapshotView.layer renderInContext:c2];
    		UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    		UIGraphicsEndImageContext();

    		// TODO: needs to be improved, no status bar + it's slightly off
			//CGContextDrawImage(c, CGRectMake(view.frame.origin.x + hostedView.frame.origin.x, view.frame.origin.y + hostedView.frame.origin.y, hostedView.frame.size.width, hostedView.frame.size.height), image.CGImage);
			[image drawInRect:CGRectMake(view.frame.origin.x, [hostedView convertPoint:hostedView.frame.origin toView:nil].y, view.frame.size.width, view.frame.size.height)];
			*/
		}
	}

	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}

-(void) showMissionControl:(BOOL)animated
{
	_isShowingMissionControl = YES;

	if (window)
		window = nil;

	[self createWindow];

	if (animated)
		window.alpha = 0;
	[window makeKeyAndVisible];
	if (animated)
		[UIView animateWithDuration:0.5 animations:^{ window.alpha = 1; }];

	overrideCC = YES;
}

-(void) createWindow
{
	window = [[RAMissionControlWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];

	_UIBackdropView *blurView = [[%c(_UIBackdropView) alloc] initWithStyle:0];
	blurView.frame = window.frame;
	[window addSubview:blurView];

	// DESKTOPS
	[self reloadDesktopSection];

	// APPS WITH PANES
	[self reloadWindowedAppsSection];

	// APPS WITHOUT PANES
	[self reloadOtherAppsSection];
}

-(void) reloadDesktopSection
{
	// DESKTOP
	if (desktopScrollView)
	{
		[desktopScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	}
	else
	{
		desktopScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 20, window.frame.size.width, height * 1.2)];
		[window addSubview:desktopScrollView];
		desktopScrollView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.1];
	}

	CGFloat x = 20;
	int desktopIndex = 0;
	for (RADesktopWindow *desktop in RADesktopManager.sharedInstance.availableDesktops)
	{
		RAMissionControlPreviewView *preview = [[RAMissionControlPreviewView alloc] initWithFrame:CGRectMake(x, 20, width, height)];
		x += 20 + preview.frame.size.width;

		[desktopScrollView addSubview:preview];
		preview.image = [self renderPreviewForDesktop:desktop];

		if (desktop == RADesktopManager.sharedInstance.currentDesktop)
		{
			preview.backgroundColor = [UIColor clearColor];
			preview.clipsToBounds = YES;
			preview.layer.borderWidth = 2;
			preview.layer.cornerRadius = 10;
			preview.layer.borderColor = [UIColor whiteColor].CGColor;
		}

		UITapGestureRecognizer *g = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleDesktopTap:)];
		g.numberOfTapsRequired = 1;
		[preview addGestureRecognizer:g];

		UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(handleDoubleDesktopTap:)];
		doubleTap.numberOfTapsRequired = 2; 
		[preview addGestureRecognizer:doubleTap];

		[g requireGestureRecognizerToFail:doubleTap];

		UIPanGestureRecognizer *swipeGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDesktopPan:)];
		[preview addGestureRecognizer:swipeGesture];

		preview.tag = desktopIndex++;
		preview.userInteractionEnabled = YES;
	}

	UIButton *newDesktopButton = [[UIButton alloc] init];
	newDesktopButton.frame = CGRectMake(x, 20, width, height);
	newDesktopButton.backgroundColor = [UIColor darkGrayColor];
	[newDesktopButton setTitle:@"+" forState:UIControlStateNormal];
	newDesktopButton.titleLabel.font = [UIFont systemFontOfSize:36];
	[newDesktopButton addTarget:self action:@selector(createNewDesktop) forControlEvents:UIControlEventTouchUpInside];
	[desktopScrollView addSubview:newDesktopButton];
	x += 20 + newDesktopButton.frame.size.width;

	desktopScrollView.contentSize = CGSizeMake(MAX(x, UIScreen.mainScreen.bounds.size.width + 1), height * 1.2); // make slightly scrollable

	// We do this AFTER rendering the desktop
	[RADesktopManager.sharedInstance hideDesktop];
}

-(void) reloadWindowedAppsSection
{
	appsWithoutWindows = [runningApplications mutableCopy];

	CGFloat x = 20;
	CGFloat y = desktopScrollView.frame.origin.y + desktopScrollView.frame.size.height + 20;

	if (windowedAppScrollView)
	{
		[windowedAppScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	}
	else
	{
		windowedLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, window.frame.size.width - 20, 20)];
		windowedLabel.font = [UIFont systemFontOfSize:18];
		windowedLabel.textColor = UIColor.whiteColor;
		windowedLabel.text = @"On This Desktop";
		[window addSubview:windowedLabel];

		windowedAppScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, y + 30, window.frame.size.width, height * 1.2)];
		[window addSubview:windowedAppScrollView];
		windowedAppScrollView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.1];
	}

	for (RAHostedAppView *app in RADesktopManager.sharedInstance.currentDesktop.hostedWindows)
	{
		SBApplication *sbapp = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:app.bundleIdentifier];
		[appsWithoutWindows removeObject:sbapp];
		RAMissionControlPreviewView *preview = [[RAMissionControlPreviewView alloc] initWithFrame:CGRectMake(x, 0, width, height)];
		x += 20 + preview.frame.size.width;

		preview.application = sbapp;
		[windowedAppScrollView addSubview:preview];
		[preview generatePreview];

		UITapGestureRecognizer *g = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(topIconViewTap:)];
		[preview addGestureRecognizer:g];

		UIPanGestureRecognizer *swipeGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleAppPreviewPan:)];
		[preview addGestureRecognizer:swipeGesture];

		preview.userInteractionEnabled = YES;
	}
	windowedAppScrollView.contentSize = CGSizeMake(MAX(x, UIScreen.mainScreen.bounds.size.width + 1), height * 1.2); // make slightly scrollable
}

-(void) reloadOtherAppsSection
{
	CGFloat x = 20;
	CGFloat y = windowedAppScrollView.frame.origin.y + windowedAppScrollView.frame.size.height + 20;

	if (otherRunningAppsScrollView)
	{
		[otherRunningAppsScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	}
	else
	{
		otherLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, window.frame.size.width - 20, 20)];
		otherLabel.font = [UIFont systemFontOfSize:18];
		otherLabel.textColor = UIColor.whiteColor;
		otherLabel.text = @"Running Elsewhere";
		[window addSubview:otherLabel];

		otherRunningAppsScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, y + 30, window.frame.size.width, height * 1.2)];
		[window addSubview:otherRunningAppsScrollView];
		otherRunningAppsScrollView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.1];
	}

	for (SBApplication *app in appsWithoutWindows)
	{
		RAMissionControlPreviewView *preview = [[RAMissionControlPreviewView alloc] initWithFrame:CGRectMake(x, 0, width, height)];
		x += 20 + preview.frame.size.width;

		preview.application = app;
		[otherRunningAppsScrollView addSubview:preview];
		[preview generatePreview];

		UITapGestureRecognizer *g = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(topIconViewTap:)];
		[preview addGestureRecognizer:g];

		UIPanGestureRecognizer *swipeGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleAppPreviewPan:)];
		[preview addGestureRecognizer:swipeGesture];

		preview.userInteractionEnabled = YES;
	}
	otherRunningAppsScrollView.contentSize = CGSizeMake(MAX(x, UIScreen.mainScreen.bounds.size.width + 1), height * 1.2); // make slightly scrollable
}

-(void) hideMissionControl:(BOOL)animated
{
	void (^destructor)() = ^{
		_isShowingMissionControl = NO;
		window.hidden = YES;
		window = nil;
		desktopScrollView = nil;
		otherRunningAppsScrollView = nil;
		windowedAppScrollView = nil;
	};

	if (animated)
		[UIView animateWithDuration:0.5 animations:^{ window.frame = CGRectMake(0, -window.frame.size.height, window.frame.size.width, window.frame.size.height); } completion:^(BOOL _) { destructor(); }];
	else
		destructor();

	[RADesktopManager.sharedInstance reshowDesktop];
	[RADesktopManager.sharedInstance.currentDesktop loadApps];
	overrideCC = NO;
}

-(void) toggleMissionControl:(BOOL)animated
{
	if (_isShowingMissionControl)
		[self hideMissionControl:animated];
	else
		[self showMissionControl:animated];
}

-(void) createNewDesktop
{
	[RADesktopManager.sharedInstance addDesktop:NO];
	[self reloadDesktopSection];
}

-(void) handleAppPreviewPan:(UIPanGestureRecognizer*)gesture
{
	static CGPoint initialCenter;
	static UIView *draggedView;

	if (gesture.state == UIGestureRecognizerStateBegan)
	{
		if (!trashImageView || trashImageView.superview == nil /* new window perhaps */)
		{
			trashImageView = [[UIImageView alloc] initWithFrame:CGRectMake((UIScreen.mainScreen.bounds.size.width / 2) - (75/2), window.frame.size.height + 75, 75, 75)];
			trashImageView.image = trashIcon;
			[window addSubview:trashImageView];
		}
		[UIView animateWithDuration:0.4 animations:^{
			trashImageView.alpha = 1;
			trashImageView.frame = CGRectMake((UIScreen.mainScreen.bounds.size.width / 2) - (75/2), window.frame.size.height - (75+50), 75, 75);
		}];

		draggedView = [gesture.view snapshotViewAfterScreenUpdates:YES];
		draggedView.frame = gesture.view.frame;
		draggedView.center = [gesture.view.superview convertPoint:gesture.view.center toView:window];
		initialCenter = draggedView.center;
		[window addSubview:draggedView];
		gesture.view.alpha = 0.6;
	}
	else if (gesture.state == UIGestureRecognizerStateChanged)
	{
		CGPoint newCenter = [gesture translationInView:draggedView];
		newCenter.x += initialCenter.x;
		newCenter.y += initialCenter.y;

		draggedView.center = newCenter;
	}
	else
	{
		gesture.view.alpha = 1;

		CGPoint center = [gesture translationInView:draggedView];
		center.x += initialCenter.x;
		center.y += initialCenter.y;

		BOOL didKill = NO;

		if (CGRectContainsPoint(trashImageView.frame, center))
		{
			SBApplication *app = ((RAMissionControlPreviewView*)gesture.view).application;
			[RADesktopManager.sharedInstance removeAppWithIdentifier:app.bundleIdentifier animated:NO];
			[RAAppKiller killAppWithSBApplication:app completion:^{
				[runningApplications removeObject:app];

				//NSLog(@"[ReachApp] killer of %@, %d", app.bundleIdentifier, app.pid);

				[self performSelectorOnMainThread:@selector(reloadDesktopSection) withObject:nil waitUntilDone:YES];
				[self performSelectorOnMainThread:@selector(reloadWindowedAppsSection) withObject:nil waitUntilDone:YES];
				[self performSelectorOnMainThread:@selector(reloadOtherAppsSection) withObject:nil waitUntilDone:YES];
			}];

			didKill = YES;
		}
		[UIView animateWithDuration:0.4 animations:^{
			trashImageView.alpha = 0;
			trashImageView.frame = CGRectMake((UIScreen.mainScreen.bounds.size.width / 2) - (75/2), window.frame.size.height + 75, 75, 75);
		}];

		if (!didKill)
		{
			for (UIView *subview in desktopScrollView.subviews)
			{
				if ([subview isKindOfClass:[RAMissionControlPreviewView class]])
				{
					if (CGRectContainsPoint((CGRect){ [desktopScrollView convertPoint:subview.frame.origin toView:window], subview.frame.size }, center))
					{
						RADesktopWindow *desktop = [RADesktopManager.sharedInstance desktopAtIndex:subview.tag];
						SBApplication *app = ((RAMissionControlPreviewView*)gesture.view).application;

						BOOL useOldData = NO;
						CGRect frame;
						CGAffineTransform transform;
						for (UIView *subview in RADesktopManager.sharedInstance.currentDesktop.subviews)
							if ([subview isKindOfClass:[RAWindowBar class]])
								if (((RAWindowBar*)subview).attachedView.app == app)
								{
									useOldData = YES;
									transform = subview.transform;
									subview.transform = CGAffineTransformIdentity;
									frame = subview.frame;
								}

						[RADesktopManager.sharedInstance.currentDesktop removeAppWithIdentifier:app.bundleIdentifier animated:NO];
						
						RAWindowBar *bar = [desktop createAppWindowForSBApplication:app animated:NO];
						if (useOldData)
						{
							bar.transform = CGAffineTransformIdentity;
							bar.frame = frame;
							bar.transform = transform;
						}

						[self reloadDesktopSection];
						[self reloadWindowedAppsSection];
						[self reloadOtherAppsSection];
					}
				}
			}
		}

		[UIView animateWithDuration:0.4 animations:^{ 
			if (!didKill)
				draggedView.center = initialCenter; 
		} completion:^(BOOL _) {
			[draggedView removeFromSuperview];
			draggedView = nil;
		}];
	}
}

-(void) handleDesktopPan:(UIPanGestureRecognizer*)gesture
{
	static CGPoint initialCenter;

	if (gesture.state == UIGestureRecognizerStateBegan)
	{
		initialCenter = gesture.view.center;
	}
	else if (gesture.state == UIGestureRecognizerStateChanged)
	{
		CGPoint newCenter = [gesture translationInView:gesture.view];
		//newCenter.x += initialCenter.x;
		newCenter.x = initialCenter.x;
		if (newCenter.y > 0)
			newCenter.y = initialCenter.y + (newCenter.y / 5); //initialCenter.y;
		else
			newCenter.y += initialCenter.y;

		gesture.view.center = newCenter;
	}
	else
	{
		if (gesture.view.center.y - initialCenter.y < -80 && gesture.view.tag > 0)
		{
			[RADesktopManager.sharedInstance removeDesktopAtIndex:gesture.view.tag];
			[UIView animateWithDuration:0.4 animations:^{
				gesture.view.center = CGPointMake(gesture.view.center.x, -gesture.view.frame.size.height);
			} completion:^(BOOL _) {
				[self reloadDesktopSection];
			}];
		}
		else
			[UIView animateWithDuration:0.4 animations:^{ gesture.view.center = initialCenter; }];
	}
}

-(void) activateDesktop:(UITapGestureRecognizer*)gesture
{
	int desktop = gesture.view.tag;
	[self hideMissionControl:YES];
	[RADesktopManager.sharedInstance switchToDesktop:desktop];
}

-(void) handleSingleDesktopTap:(UITapGestureRecognizer*)gesture
{
	int desktop = gesture.view.tag;
	[RADesktopManager.sharedInstance switchToDesktop:desktop actuallyShow:NO];
	[self reloadDesktopSection];
	[self reloadWindowedAppsSection];
	[self reloadOtherAppsSection];
}

-(void) handleDoubleDesktopTap:(UITapGestureRecognizer*)gesture
{
	[self activateDesktop:gesture];
}

-(void) topIconViewTap:(UITapGestureRecognizer*)gesture
{
	[self hideMissionControl:YES];
	[UIApplication.sharedApplication launchApplicationWithIdentifier:[[[gesture view] performSelector:@selector(application)] bundleIdentifier] suspended:NO];
}

-(RAMissionControlWindow*) missionControlWindow { if (!window) [self createWindow]; return window; }
-(NSMutableArray*) runningApplications { return runningApplications; }
@end


%hook SBApplication
- (void)updateProcessState:(id)arg1
{
	%orig;

	if (self.isRunning && [RAMissionControlManager.sharedInstance.runningApplications containsObject:self] == NO)
		[RAMissionControlManager.sharedInstance.runningApplications addObject:self];
	else if (!self.isRunning && [RAMissionControlManager.sharedInstance.runningApplications containsObject:self])
		[RAMissionControlManager.sharedInstance.runningApplications removeObject:self];
}
%end