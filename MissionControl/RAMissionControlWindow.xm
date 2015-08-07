#import "RAMissionControlWindow.h"
#import "RAMissionControlPreviewView.h"
#import "RAWindowStatePreservationSystemManager.h"
#import "RASnapshotProvider.h"
#import "RAWindowBar.h"
#import "RAAppKiller.h"
#import "RADesktopManager.h"
#import "RADesktopWindow.h"
#import "RAMissionControlManager.h"

@interface RAMissionControlWindow ()  {
	UIScrollView *desktopScrollView, *windowedAppScrollView, *otherRunningAppsScrollView;
	UILabel *desktopLabel, *windowedLabel, *otherLabel;
	
	UIImageView *trashImageView;
	UIImage *trashIcon;

	NSMutableArray *runningApplications;
	NSMutableArray *appsWithoutWindows;

	CGFloat width, height;
}
@end

@implementation RAMissionControlWindow
-(id) initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		trashIcon = [UIImage imageWithContentsOfFile:@"/Library/ReachApp/Trash.png"];
	}
	return self;
}

-(UIWindowLevel) windowLevel
{
	//return UIWindowLevelStatusBar + 1;
	return 99999999; 
}

- (BOOL)_shouldAutorotateToInterfaceOrientation:(int)arg1 checkForDismissal:(BOOL)arg2 isRotationDisabled:(BOOL*)arg3
{
	return YES;
}

-(void) reloadDesktopSection
{
	width = UIScreen.mainScreen._interfaceOrientedBounds.size.width / 4.5714;
	height = UIScreen.mainScreen._interfaceOrientedBounds.size.height / 4.36;
	/*if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		width = (UIScreen.mainScreen.bounds.size.width / 3) * 0.9;
	    height = (UIScreen.mainScreen.bounds.size.height / 4) * 0.9;
	}*/

	// DESKTOP
	CGFloat y = 25;

	if (desktopScrollView)
	{
		[desktopScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	}
	else
	{
		desktopLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, y, self.frame.size.width - 20, 20)];
		desktopLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:14];
		desktopLabel.textColor = UIColor.whiteColor;
		desktopLabel.text = LOCALIZE(@"DESKTOPS");
		[self addSubview:desktopLabel];

		y = y + desktopLabel.frame.size.height + 3;

		desktopScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, y, self.frame.size.width, height * 1.2)];
		desktopScrollView.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.3];

		[self addSubview:desktopScrollView];
	}

	CGFloat x = 15;
	int desktopIndex = 0;
	for (RADesktopWindow *desktop in RADesktopManager.sharedInstance.availableDesktops)
	{
		RAMissionControlPreviewView *preview = [[RAMissionControlPreviewView alloc] initWithFrame:CGRectMake(x, 20, width, height)];
		x += 7 + preview.frame.size.width;

		[desktopScrollView addSubview:preview];
		preview.image = [RASnapshotProvider.sharedInstance snapshotForDesktop:desktop];

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

	desktopScrollView.contentSize = CGSizeMake(MAX(x, self.frame.size.width + 1), height * 1.2); // make slightly scrollable

	// We do this AFTER rendering the desktop
	[RADesktopManager.sharedInstance hideDesktop];
}

-(void) reloadWindowedAppsSection
{
	[self reloadWindowedAppsSection:runningApplications];
}

-(void) reloadWindowedAppsSection:(NSArray*)runningApplicationsArg
{
	runningApplications = [runningApplicationsArg mutableCopy];
	appsWithoutWindows = [runningApplications mutableCopy];
	NSArray *visibleIcons = [[[%c(SBIconViewMap) homescreenMap] iconModel] visibleIconIdentifiers];
	for (SBApplication *app in runningApplications)
		if ([visibleIcons containsObject:app.bundleIdentifier] == NO)
			[appsWithoutWindows removeObject:app];

	CGFloat x = 15;
	CGFloat y = desktopScrollView.frame.origin.y + desktopScrollView.frame.size.height + 5;

	if (windowedAppScrollView)
	{
		[windowedAppScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	}
	else
	{
		windowedLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, y, self.frame.size.width - 20, 20)];
		windowedLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:14];
		windowedLabel.textColor = UIColor.whiteColor;
		windowedLabel.text = LOCALIZE(@"ON_THIS_DESKTOP");
		[self addSubview:windowedLabel];

		windowedAppScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, y + windowedLabel.frame.size.height + 3, self.frame.size.width, height * 1.2)];
		windowedAppScrollView.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.3];

		[self addSubview:windowedAppScrollView];
	}

	BOOL empty = YES;
	for (RAHostedAppView *app in RADesktopManager.sharedInstance.currentDesktop.hostedWindows)
	{
		SBApplication *sbapp = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:app.bundleIdentifier];
		[appsWithoutWindows removeObject:sbapp];
		RAMissionControlPreviewView *preview = [[RAMissionControlPreviewView alloc] initWithFrame:CGRectMake(x, (windowedAppScrollView.frame.size.height - height) / 2, width, height)];
		x += 7 + preview.frame.size.width;

		preview.application = sbapp;
		[windowedAppScrollView addSubview:preview];
		[preview generatePreview];

		UITapGestureRecognizer *g = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(topIconViewTap:)];
		[preview addGestureRecognizer:g];

		UILongPressGestureRecognizer *swipeGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleAppPreviewPan:)];
		swipeGesture.minimumPressDuration = 0.1;
		[preview addGestureRecognizer:swipeGesture];

		preview.userInteractionEnabled = YES;
		empty = NO;
	}

	if (empty)
	{
		UILabel *emptyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (windowedAppScrollView.frame.size.height - 30) / 2, windowedAppScrollView.frame.size.width, 30)];
		emptyLabel.textAlignment = NSTextAlignmentCenter;
		emptyLabel.font = [UIFont fontWithName:@"Helvetica" size:25];
		emptyLabel.text = LOCALIZE(@"NO_APPS");
		emptyLabel.textColor = [UIColor whiteColor];
		emptyLabel.alpha = 0.7;
		[windowedAppScrollView addSubview:emptyLabel];
	}

	windowedAppScrollView.contentSize = CGSizeMake(MAX(x, self.frame.size.width + (empty ? 0 : 1)), height * 1.2); // make slightly scrollable
}

-(void) reloadOtherAppsSection
{
	CGFloat x = 15;
	CGFloat y = windowedAppScrollView.frame.origin.y + windowedAppScrollView.frame.size.height + 5;

	if (otherRunningAppsScrollView)
	{
		[otherRunningAppsScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	}
	else
	{
		otherLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, y, self.frame.size.width - 20, 20)];
		otherLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:14];
		otherLabel.textColor = UIColor.whiteColor;
		otherLabel.text = LOCALIZE(@"RUNNING_ELSEWHERE");
		[self addSubview:otherLabel];

		otherRunningAppsScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, y + otherLabel.frame.size.height + 3, self.frame.size.width, height * 1.2)];
		otherRunningAppsScrollView.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.3];

		[self addSubview:otherRunningAppsScrollView];
	}

	BOOL empty = YES;
	for (SBApplication *app in appsWithoutWindows)
	{
		empty = NO;

		RAMissionControlPreviewView *preview = [[RAMissionControlPreviewView alloc] initWithFrame:CGRectMake(x, (otherRunningAppsScrollView.frame.size.height - height) / 2, width, height)];
		x += 6 + preview.frame.size.width;

		preview.application = app;
		[otherRunningAppsScrollView addSubview:preview];
		[preview generatePreview];

		UITapGestureRecognizer *g = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(topIconViewTap:)];
		[preview addGestureRecognizer:g];

		UILongPressGestureRecognizer *swipeGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleAppPreviewPan:)];
		swipeGesture.minimumPressDuration = 0.1;
		[preview addGestureRecognizer:swipeGesture];

		preview.userInteractionEnabled = YES;
	}

	if (empty)
	{
		UILabel *emptyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (windowedAppScrollView.frame.size.height - 30) / 2, windowedAppScrollView.frame.size.width, 30)];
		emptyLabel.textAlignment = NSTextAlignmentCenter;
		emptyLabel.font = [UIFont fontWithName:@"Helvetica" size:25];
		emptyLabel.text = LOCALIZE(@"NO_APPS");
		emptyLabel.textColor = [UIColor whiteColor];
		emptyLabel.alpha = 0.7;
		[windowedAppScrollView addSubview:emptyLabel];
	}

	otherRunningAppsScrollView.contentSize = CGSizeMake(MAX(x, self.frame.size.width + (empty ? 0 : 1)), height * 1.2); // make slightly scrollable
}

-(void) createNewDesktop
{
	[RADesktopManager.sharedInstance addDesktop:NO];
	[self reloadDesktopSection];
}

-(void) handleAppPreviewPan:(UILongPressGestureRecognizer*)gesture
{
	static CGPoint initialCenter;
	static UIView *draggedView;
	static CGPoint lastPoint;

	CGPoint point = [gesture locationInView:self];

	if (gesture.state == UIGestureRecognizerStateBegan)
	{
		if (!trashImageView || trashImageView.superview == nil /* new window perhaps */)
		{
			trashImageView = [[UIImageView alloc] initWithFrame:CGRectMake((UIScreen.mainScreen._interfaceOrientedBounds.size.width / 2) - (75/2), UIScreen.mainScreen._interfaceOrientedBounds.size.height + 75, 75, 75)];
			trashImageView.image = trashIcon;
			[self addSubview:trashImageView];
		}
		[UIView animateWithDuration:0.4 animations:^{
			trashImageView.alpha = 1;
			trashImageView.frame = CGRectMake((UIScreen.mainScreen._interfaceOrientedBounds.size.width / 2) - (75/2), UIScreen.mainScreen._interfaceOrientedBounds.size.height - (75+50), 75, 75);
		}];

		if (draggedView == nil)
		{
			draggedView = [gesture.view snapshotViewAfterScreenUpdates:YES];
			draggedView.frame = gesture.view.frame;
			draggedView.center = [gesture.view.superview convertPoint:gesture.view.center toView:self];
	
			[self addSubview:draggedView];
			gesture.view.alpha = 0.6;

			[UIView animateWithDuration:0.3 animations:^{
				draggedView.transform = CGAffineTransformMakeScale(1.1, 1.1);
			}];
		}
		initialCenter = draggedView.center;
	}
	else if (gesture.state == UIGestureRecognizerStateChanged)
	{
		//CGPoint newCenter = [gesture translationInView:draggedView];
		//newCenter.x += initialCenter.x;
		//newCenter.y += initialCenter.y;
		//draggedView.center = newCenter;

        CGPoint center = draggedView.center;
        center.x += point.x - lastPoint.x;
        center.y += point.y - lastPoint.y;
        draggedView.center = center;
	}
	else
	{
		gesture.view.alpha = 1;

		//CGPoint center = [gesture translationInView:draggedView];
		//center.x += initialCenter.x;
		//center.y += initialCenter.y;
        CGPoint center = draggedView.center;
        center.x += point.x - lastPoint.x;
        center.y += point.y - lastPoint.y;

		BOOL didKill = NO;

		if (CGRectContainsPoint(trashImageView.frame, center))
		{
			SBApplication *app = ((RAMissionControlPreviewView*)gesture.view).application;
			[RADesktopManager.sharedInstance removeAppWithIdentifier:app.bundleIdentifier animated:NO];
			[RAWindowStatePreservationSystemManager.sharedInstance removeWindowInformationForIdentifier:app.bundleIdentifier];
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
			trashImageView.frame = CGRectMake((UIScreen.mainScreen._interfaceOrientedBounds.size.width / 2) - (75/2), UIScreen.mainScreen._interfaceOrientedBounds.size.height + 75, 75, 75);
		}];

		if (!didKill)
		{
			for (UIView *subview in desktopScrollView.subviews)
			{
				if ([subview isKindOfClass:[RAMissionControlPreviewView class]])
				{
					if (CGRectContainsPoint((CGRect){ [desktopScrollView convertPoint:subview.frame.origin toView:self], subview.frame.size }, center))
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

						[RASnapshotProvider.sharedInstance forceReloadSnapshotOfDesktop:RADesktopManager.sharedInstance.currentDesktop];
						[RASnapshotProvider.sharedInstance forceReloadSnapshotOfDesktop:desktop];

						[self reloadDesktopSection];
						[self reloadWindowedAppsSection];
						[self reloadOtherAppsSection];
					}
				}
			}
		}

		[UIView animateWithDuration:0.4 animations:^{ 
			if (!didKill)
			{
				draggedView.transform = CGAffineTransformIdentity;
				draggedView.center = initialCenter; 
			}
		} completion:^(BOOL _) {
			[draggedView removeFromSuperview];
			draggedView = nil;
		}];
	}
	lastPoint = point;
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
	[self.manager hideMissionControl:YES];
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
	[self.manager hideMissionControl:YES];
	[UIApplication.sharedApplication launchApplicationWithIdentifier:[[[gesture view] performSelector:@selector(application)] bundleIdentifier] suspended:NO];
}

-(void) deconstructComponents
{
	desktopScrollView = nil;
	otherRunningAppsScrollView = nil;
	windowedAppScrollView = nil;
}
@end