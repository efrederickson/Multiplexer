#import "headers.h"
#import "RAGestureManager.h"
#import "RAMissionControlManager.h"
#import "RAMissionControlWindow.h"
#import "RASettings.h"

%hook SBAppSwitcherController
- (void)forceDismissAnimated:(_Bool)arg1
{
	%orig;
	[UIView animateWithDuration:0.3 animations:^{
		[[[%c(SBUIController) sharedInstance] switcherWindow] viewWithTag:999].alpha = 0;
	}];
}
- (void)animateDismissalToDisplayLayout:(id)arg1 withCompletion:(__unsafe_unretained id)arg2
{
	%orig;
	[UIView animateWithDuration:0.3 animations:^{
		[[[%c(SBUIController) sharedInstance] switcherWindow] viewWithTag:999].alpha = 0;
	}];
}
%end

%hook SBUIController
- (void)_showNotificationsGestureBeganWithLocation:(CGPoint)arg1
{
	if ([[[%c(SBUIController) sharedInstance] switcherWindow] isKeyWindow] && CGRectContainsPoint([[[%c(SBUIController) sharedInstance] switcherWindow] viewWithTag:999].frame, arg1))
		return;
	%orig;
}

- (_Bool)_activateAppSwitcher
{
	if ([RASettings.sharedInstance replaceAppSwitcherWithMC])
	{
		[RAMissionControlManager.sharedInstance showMissionControl:YES];
		
        FBWorkspaceEvent *event = [%c(FBWorkspaceEvent) eventWithName:@"ActivateSpringBoard" handler:^{
            SBAppToAppWorkspaceTransaction *transaction = [[%c(SBAppExitedWorkspaceTransaction) alloc] initWithAlertManager:nil exitedApp:UIApplication.sharedApplication._accessibilityFrontMostApplication];
            [transaction begin];
        }];
        [[%c(FBWorkspaceEventQueue) sharedInstance] executeOrAppendEvent:event];

		return YES;
	}

	BOOL s = %orig;
	if (s && [RASettings.sharedInstance missionControlEnabled])
	{
		[UIView animateWithDuration:0.3 animations:^{
			[[[%c(SBUIController) sharedInstance] switcherWindow] viewWithTag:999].alpha = 1;
		}];
	}
	return s;
}
%end

%hook SBAppSwitcherWindow
-(void) addSubview:(UIView*)view
{
	%orig;

	if ([self viewWithTag:999] == nil && ([RASettings.sharedInstance missionControlEnabled] && ![RASettings.sharedInstance replaceAppSwitcherWithMC]))
	{
		SBControlCenterGrabberView *grabber = [[%c(SBControlCenterGrabberView) alloc] initWithFrame:CGRectMake(0, 0, 50, 30)];
		grabber.center = CGPointMake(self.frame.size.width / 2, 20/2);
		
		[grabber.chevronView setState:1 animated:YES];

		grabber.backgroundColor = [UIColor whiteColor];
		grabber.layer.cornerRadius = 5;

		//[grabber.chevronView setState:1 animated:YES];
		grabber.tag = 999;
		[self addSubview:grabber];

		[RAGestureManager.sharedInstance addGestureRecognizerWithTarget:(NSObject<RAGestureCallbackProtocol> *)self forEdge:UIRectEdgeTop identifier:@"com.efrederickson.reachapp.appswitchergrabber"];
	}
}

%new -(BOOL) RAGestureCallback_canHandle:(CGPoint)point velocity:(CGPoint)velocity
{
	return self.isKeyWindow;
}

%new -(RAGestureCallbackResult) RAGestureCallback_handle:(UIGestureRecognizerState)state withPoint:(CGPoint)location velocity:(CGPoint)velocity forEdge:(UIRectEdge)edge
{
	[[%c(SBUIController) sharedInstance] performSelector:@selector(_showNotificationsGestureFailed)];
	[[%c(SBUIController) sharedInstance] performSelector:@selector(_showNotificationsGestureCancelled)];

	static CGFloat origY = -1;
	static UIView *fakeView;

	if (!fakeView)
	{
		fakeView = [[UIView alloc] initWithFrame:self.frame];

		CGFloat width = UIScreen.mainScreen.bounds.size.width / 4.5714;
		CGFloat height = UIScreen.mainScreen.bounds.size.height / 4.36;

		_UIBackdropView *blurView = [[%c(_UIBackdropView) alloc] initWithStyle:0];
		blurView.frame = fakeView.frame;
		[fakeView addSubview:blurView];

		UIScrollView *desktopScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 20, fakeView.frame.size.width, height * 1.2)];
		[fakeView addSubview:desktopScrollView];
		desktopScrollView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.1];

		CGFloat x = 20;

		UIButton *newDesktopButton = [[UIButton alloc] init];
		newDesktopButton.frame = CGRectMake(x, 20, width, height);
		newDesktopButton.backgroundColor = [UIColor darkGrayColor];
		[newDesktopButton setTitle:@"+" forState:UIControlStateNormal];
		newDesktopButton.titleLabel.font = [UIFont systemFontOfSize:36];
		[newDesktopButton addTarget:self action:@selector(createNewDesktop) forControlEvents:UIControlEventTouchUpInside];
		[desktopScrollView addSubview:newDesktopButton];
		x += 20 + newDesktopButton.frame.size.width;

		desktopScrollView.contentSize = CGSizeMake(MAX(x, UIScreen.mainScreen.bounds.size.width + 1), height * 1.2); // make slightly scrollable
	
		x = 20;
		CGFloat y = desktopScrollView.frame.origin.y + desktopScrollView.frame.size.height + 20;

		UILabel *windowedLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, fakeView.frame.size.width - 20, 20)];
		windowedLabel.font = [UIFont systemFontOfSize:18];
		windowedLabel.textColor = UIColor.whiteColor;
		windowedLabel.text = @"On This Desktop";
		[fakeView addSubview:windowedLabel];

		UIScrollView *windowedAppScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, y + 30, fakeView.frame.size.width, height * 1.2)];
		[fakeView addSubview:windowedAppScrollView];
		windowedAppScrollView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.1];

		windowedAppScrollView.contentSize = CGSizeMake(MAX(x, UIScreen.mainScreen.bounds.size.width + 1), height * 1.2); // make slightly scrollable

		x = 20;
		y = windowedAppScrollView.frame.origin.y + windowedAppScrollView.frame.size.height + 20;

		UILabel *otherLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, fakeView.frame.size.width - 20, 20)];
		otherLabel.font = [UIFont systemFontOfSize:18];
		otherLabel.textColor = UIColor.whiteColor;
		otherLabel.text = @"Running Elsewhere";
		[fakeView addSubview:otherLabel];

		UIScrollView *otherRunningAppsScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, y + 30, fakeView.frame.size.width, height * 1.2)];
		[fakeView addSubview:otherRunningAppsScrollView];
		otherRunningAppsScrollView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.1];
	
		otherRunningAppsScrollView.contentSize = CGSizeMake(MAX(x, UIScreen.mainScreen.bounds.size.width + 1), height * 1.2); // make slightly scrollable

		[self addSubview:fakeView];
	}

	if (origY == -1)
	{
		CGRect f = fakeView.frame;
		f.origin.y = -f.size.height;
		fakeView.frame = f;
		origY = fakeView.center.y;
	}

	if (state == UIGestureRecognizerStateChanged)	
		fakeView.center = (CGPoint) { fakeView.center.x, origY + location.y };
	
	if (state == UIGestureRecognizerStateEnded)
	{
		//NSLog(@"[ReachApp] %@ + %@ = %@ > %@", NSStringFromCGPoint(fakeView.frame.origin), NSStringFromCGPoint(velocity), @(fakeView.frame.origin.y + velocity.y), @(-(UIScreen.mainScreen.bounds.size.height / 2)));

		if (fakeView.frame.origin.y + velocity.y > -(UIScreen.mainScreen.bounds.size.height / 2))
		{			
			CGFloat distance = UIScreen.mainScreen.bounds.size.height - (fakeView.frame.origin.y + fakeView.frame.size.height);
			CGFloat duration = MIN(distance / velocity.y, 0.3);

			//NSLog(@"[ReachApp] dist %f, dur %f", distance, duration);

			[UIView animateWithDuration:duration animations:^{
				fakeView.frame = UIScreen.mainScreen.bounds;
			} completion:^(BOOL _) {
	            FBWorkspaceEvent *event = [%c(FBWorkspaceEvent) eventWithName:@"ActivateSpringBoard" handler:^{
	                SBAppToAppWorkspaceTransaction *transaction = [[%c(SBAppToAppWorkspaceTransaction) alloc] initWithAlertManager:nil exitedApp:UIApplication.sharedApplication._accessibilityFrontMostApplication];
	                [transaction begin];
	            }];
	            [(FBWorkspaceEventQueue*)[%c(FBWorkspaceEventQueue) sharedInstance] executeOrAppendEvent:event];

				[[[%c(SBUIController) sharedInstance] _appSwitcherController] forceDismissAnimated:NO];
				[[%c(SBUIController) sharedInstance] restoreContentUpdatingStatusBar:YES];
				[RAMissionControlManager.sharedInstance showMissionControl:NO];
				[fakeView removeFromSuperview];
				fakeView = nil;
			}];
		}
		else
		{
			CGFloat distance = fakeView.frame.size.height + fakeView.frame.origin.y /* origin.y is less than 0 so the + is actually a - operation */;
			CGFloat duration = MIN(distance / velocity.y, 0.3);

			//NSLog(@"[ReachApp] dist %f, dur %f", distance, duration);

			[UIView animateWithDuration:duration animations:^{
				fakeView.frame = CGRectMake(fakeView.frame.origin.x, -fakeView.frame.size.height, fakeView.frame.size.width, fakeView.frame.size.height);
			} completion:^(BOOL _) {
				[fakeView removeFromSuperview];
				fakeView = nil;
			}];
		}
	}

	return RAGestureCallbackResultSuccess;
}
%end
