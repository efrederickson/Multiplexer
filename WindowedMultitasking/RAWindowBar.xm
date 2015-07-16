#import "RAWindowBar.h"
#import "RADesktopManager.h"
#import "RAWindowOverlayView.h"
#import "RAWindowSnapDataProvider.h"

@interface RAWindowBar () {
	CGPoint initialPoint;
	BOOL enableDrag, enableLongPress;
	BOOL sizingLocked;

	UIPanGestureRecognizer *panGesture;
	UIPinchGestureRecognizer *scaleGesture;
	UILongPressGestureRecognizer *longPressGesture;
	UITapGestureRecognizer *tapGesture, *doubleTapGesture;
	UIRotationGestureRecognizer *rotateGesture;

	UILabel *titleLabel;
	UIButton *closeButton, *maximizeButton, *minimizeButton, *swapOrientationButton, *sizingLockButton;
}
@end

@implementation RAWindowBar
-(void) attachView:(RAHostedAppView*)view
{
	self.backgroundColor = UIColor.lightGrayColor;
	attachedView = view;

	CGRect myFrame = view.frame;
	self.frame = myFrame;
	view.frame = CGRectMake(0, 30, self.frame.size.width, self.frame.size.height);
	myFrame.size.height += 30;
	self.frame = myFrame;
	[self addSubview:view];

    panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panGesture.delegate = self;
    [self addGestureRecognizer:panGesture];

	scaleGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
	scaleGesture.delegate = self;
	[self addGestureRecognizer:scaleGesture];

	longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
	longPressGesture.delegate = self;
	longPressGesture.minimumPressDuration = 0.7;
	[self addGestureRecognizer:longPressGesture];

	rotateGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotate:)];
	rotateGesture.delegate = self;
	[self addGestureRecognizer:rotateGesture];

	tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
	tapGesture.numberOfTapsRequired = 1;
	//tapGesture.delegate = self;
	[self addGestureRecognizer:tapGesture];

	doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(handleDoubleTap:)];
	doubleTapGesture.numberOfTapsRequired = 2; 
	doubleTapGesture.delegate = self;
	[self addGestureRecognizer:doubleTapGesture];

	[tapGesture requireGestureRecognizerToFail:doubleTapGesture];
	[tapGesture requireGestureRecognizerToFail:scaleGesture];
	[tapGesture requireGestureRecognizerToFail:rotateGesture];

    self.userInteractionEnabled = YES;
    enableDrag = YES;
    enableLongPress = YES;

    titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, myFrame.size.width, 30)];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:18];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.text = [view displayName];
    [self addSubview:titleLabel];

	closeButton = [[UIButton alloc] init];
	closeButton.frame = CGRectMake(5, 5, 20, 20);
	[closeButton setTitle:@"×" forState:UIControlStateNormal];
	[closeButton addTarget:self action:@selector(closeButtonTap:) forControlEvents:UIControlEventTouchUpInside];
	closeButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
	closeButton.layer.cornerRadius = closeButton.frame.size.width / 2;
	closeButton.titleLabel.textAlignment = NSTextAlignmentCenter;
	closeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	closeButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	[self addSubview:closeButton];

	maximizeButton = [[UIButton alloc] init];
	maximizeButton.frame = CGRectMake(30, 5, 20, 20);
	[maximizeButton setTitle:@"+" forState:UIControlStateNormal];
	[maximizeButton addTarget:self action:@selector(maximizeButtonTap:) forControlEvents:UIControlEventTouchUpInside];
	maximizeButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
	maximizeButton.layer.cornerRadius = maximizeButton.frame.size.width / 2;
	maximizeButton.titleLabel.textAlignment = NSTextAlignmentCenter;
	maximizeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	[self addSubview:maximizeButton];

	minimizeButton = [[UIButton alloc] init];
	minimizeButton.frame = CGRectMake(55, 5, 20, 20);
	[minimizeButton setTitle:@"-" forState:UIControlStateNormal];
	[minimizeButton addTarget:self action:@selector(minimizeButtonTap:) forControlEvents:UIControlEventTouchUpInside];
	minimizeButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
	minimizeButton.layer.cornerRadius = minimizeButton.frame.size.width / 2;
	minimizeButton.titleLabel.textAlignment = NSTextAlignmentCenter;
	minimizeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	[self addSubview:minimizeButton];

	swapOrientationButton = [[UIButton alloc] init];
	swapOrientationButton.frame = CGRectMake(self.frame.size.width - 25, 5, 20, 20);
	[swapOrientationButton setTitle:@"↺" forState:UIControlStateNormal];
	[swapOrientationButton addTarget:self action:@selector(swapOrientationButtonTap:) forControlEvents:UIControlEventTouchUpInside];
	swapOrientationButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
	swapOrientationButton.layer.cornerRadius = swapOrientationButton.frame.size.width / 2;
	swapOrientationButton.titleLabel.textAlignment = NSTextAlignmentCenter;
	swapOrientationButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	[self addSubview:swapOrientationButton];

	sizingLocked = YES;
	sizingLockButton = [[UIButton alloc] init];
	sizingLockButton.frame = CGRectMake(swapOrientationButton.frame.origin.x - 25, 5, 20, 20);
	[sizingLockButton setTitle:@"🔒" forState:UIControlStateNormal];
	[sizingLockButton addTarget:self action:@selector(sizingLockButtonTap:) forControlEvents:UIControlEventTouchUpInside];
	sizingLockButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
	sizingLockButton.layer.cornerRadius = sizingLockButton.frame.size.width / 2;
	sizingLockButton.titleLabel.textAlignment = NSTextAlignmentCenter;
	sizingLockButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	[self addSubview:sizingLockButton];
}

-(void) close
{
	[RADesktopManager.sharedInstance removeAppWithIdentifier:self.attachedView.bundleIdentifier animated:YES];
}

-(void) maximize
{
	[[%c(SBUIController) sharedInstance] activateApplicationAnimated:attachedView.app];
}

-(void) minimize
{
	[attachedView rotateToOrientation:UIInterfaceOrientationPortrait];
	[UIView animateWithDuration:0.7 animations:^{
		self.transform = CGAffineTransformMakeScale(0.25, 0.25);
	}];
}

-(void) closeButtonTap:(id)arg1
{
	[self close];
}

-(void) maximizeButtonTap:(id)arg1
{
	[self maximize];
}

-(void) minimizeButtonTap:(id)arg1
{
	[self minimize];
}

-(void) sizingLockButtonTap:(id)arg1
{
	sizingLocked = !sizingLocked;

	if (sizingLocked)
		[sizingLockButton setTitle:@"🔒" forState:UIControlStateNormal];
	else
		[sizingLockButton setTitle:@"🔓" forState:UIControlStateNormal];
}

-(void) addRotation:(CGFloat)rads updateApp:(BOOL)update
{
	if (rads != 0)
		self.transform = CGAffineTransformRotate(self.transform, rads);

    if (update)
	{
    	CGFloat currentRotation = RADIANS_TO_DEGREES(atan2(self.transform.b, self.transform.a));

    	if (currentRotation < 0) currentRotation = 360 + currentRotation;

    	UIInterfaceOrientation o = UIInterfaceOrientationPortrait;
    	if (currentRotation >= 315 || currentRotation <= 45)
    		o = UIInterfaceOrientationPortrait;
    	else if (currentRotation > 45 && currentRotation <= 135)
    		o = UIInterfaceOrientationLandscapeLeft;
    	else if (currentRotation > 135 && currentRotation <= 215)
    		o = UIInterfaceOrientationPortraitUpsideDown;
    	else
    		o = UIInterfaceOrientationLandscapeRight;

    	[attachedView rotateToOrientation:o];
    }
}

-(void) swapOrientationButtonTap:(id)arg1
{
	[self addRotation:DEGREES_TO_RADIANS(90) updateApp:YES];
}

- (void)handleRotate:(UIRotationGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateChanged)
    {
    	[self addRotation:gesture.rotation updateApp:NO];
        //[self setTransform:CGAffineTransformRotate(self.transform, gesture.rotation)];
        gesture.rotation = 0.0;
    }
    else if (gesture.state == UIGestureRecognizerStateEnded)
	{
    	[self addRotation:0 updateApp:YES];
    }
}

-(void) handleLongPress:(UILongPressGestureRecognizer*)sender
{
	if (!enableLongPress)
		return;

	[self close];
}

-(void) showOverlay
{
	RAWindowOverlayView *overlay = [[RAWindowOverlayView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
	overlay.alpha = 0;
	overlay.tag = 465982;
	[self addSubview:overlay];
	overlay.appWindow = self;
	[overlay show];
	[UIView animateWithDuration:0.4 animations:^{
		overlay.alpha = 1;
	}];
}

-(void) hideOverlay
{
	[(RAWindowOverlayView*)[self viewWithTag:465982] dismiss];
}

-(BOOL) isOverlayShowing { return [self viewWithTag:465982] != nil; }

-(void) handleTap:(UITapGestureRecognizer*)tap
{
	[self showOverlay];
}

-(void) handleDoubleTap:(UITapGestureRecognizer*)tap
{
	[attachedView rotateToOrientation:UIInterfaceOrientationPortrait];
	[UIView animateWithDuration:0.7 animations:^{
		self.transform = CGAffineTransformMakeScale(0.6, 0.6);
	}];
}

-(void) handlePan:(UIPanGestureRecognizer*)sender
{
	if (!enableDrag)
		return;

	if (sender.state == UIGestureRecognizerStateBegan)
		initialPoint = sender.view.center;
	else if (sender.state == UIGestureRecognizerStateChanged)
	{
		enableLongPress = NO;
	}
	else if (sender.state == UIGestureRecognizerStateEnded)
	{
		enableLongPress = YES;

		if ([RAWindowSnapDataProvider shouldSnapWindowAtLocation:self.frame])
		{
			[RAWindowSnapDataProvider snapWindow:self toLocation:[RAWindowSnapDataProvider snapLocationForWindowLocation:self.frame] animated:YES];
			// Force tap to fail
			tapGesture.enabled = NO;
			tapGesture.enabled = YES;
			return;
		}
	}

    UIView *view = sender.view;
    CGPoint point = [sender translationInView:self.superview];

    CGPoint translatedPoint = CGPointMake(initialPoint.x + point.x, initialPoint.y + point.y);
    view.center = translatedPoint;
}

- (void)handlePinch:(UIPinchGestureRecognizer *)gesture
{
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
        	enableDrag = NO; enableLongPress = NO;
            break;
        case UIGestureRecognizerStateChanged:
            //self.bounds = (CGRect){ self.bounds.origin, {self.bounds.size.width * gesture.scale, self.bounds.size.height * gesture.scale} };
            [self setTransform:CGAffineTransformScale(self.transform, gesture.scale, gesture.scale)];
            gesture.scale = 1.0;
            break;
        case UIGestureRecognizerStateEnded:
        	enableDrag = YES; enableLongPress = YES;
            break;
        default:
            break;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer { return YES; }
-(RAHostedAppView*) attachedView { return attachedView; }
@end