#import "RAWindowBar.h"
#import "RADesktopManager.h"
#import "RAWindowOverlayView.h"
#import "RAWindowSnapDataProvider.h"
#import "RASettings.h"
#import "RAWindowStatePreservationSystemManager.h"
#import "RAResourceImageProvider.h"

const int rightSizeViewTag = 987654321;
const int bottomSizeViewTag =  987654320;

@interface RAWindowBar () {
	CGPoint initialPoint;
	BOOL enableDrag, enableLongPress;
	BOOL sizingLocked, appRotationLocked;
	BOOL isSnapped;

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
	self.backgroundColor = [UIColor colorWithRed:229/255.0f green:228/255.0f blue:229/255.0f alpha:1.0f]; //UIColor.lightGrayColor;
	attachedView = view;

	CGRect myFrame = view.frame;
	self.frame = myFrame;
	view.frame = CGRectMake(0, 40, self.frame.size.width, self.frame.size.height);
	myFrame.size.height += 40;
	self.frame = myFrame;
	view.hideStatusBar = YES;
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

    titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, myFrame.size.width, 40)];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:18];
    titleLabel.textColor = [UIColor colorWithRed:115/255.0f green:114/255.0f blue:115/255.0f alpha:1.0f];
    titleLabel.text = [view displayName];
    [self addSubview:titleLabel];

	closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	closeButton.frame = CGRectMake(5, 2, 36, 36);
	[closeButton setImage:[RAResourceImageProvider imageForFilename:@"Close" size:CGSizeMake(16, 16) tintedTo:[UIColor.blackColor colorWithAlphaComponent:0.5]] forState:UIControlStateNormal];
	closeButton.clipsToBounds = YES;
	[closeButton addTarget:self action:@selector(closeButtonTap:) forControlEvents:UIControlEventTouchUpInside];
	closeButton.backgroundColor = [UIColor colorWithRed:255/255.0f green:112/255.0f blue:112/255.0f alpha:1.0f];
	closeButton.layer.cornerRadius = closeButton.frame.size.width / 2;
	[self addSubview:closeButton];

	maximizeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	maximizeButton.frame = CGRectMake(45, 2, 36, 36);
	[maximizeButton setImage:[RAResourceImageProvider imageForFilename:@"Plus" size:CGSizeMake(16, 16) tintedTo:[UIColor.blackColor colorWithAlphaComponent:0.5]] forState:UIControlStateNormal];
	maximizeButton.clipsToBounds = YES;
	[maximizeButton addTarget:self action:@selector(maximizeButtonTap:) forControlEvents:UIControlEventTouchUpInside];
	maximizeButton.backgroundColor = [UIColor colorWithRed:115/255.0f green:232/255.0f blue:166/255.0f alpha:1.0f];
	maximizeButton.layer.cornerRadius = maximizeButton.frame.size.width / 2;
	[self addSubview:maximizeButton];

	minimizeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	minimizeButton.frame = CGRectMake(85, 2, 36, 36);
	[minimizeButton setImage:[RAResourceImageProvider imageForFilename:@"Minus" size:CGSizeMake(16, 16) tintedTo:[UIColor.blackColor colorWithAlphaComponent:0.5]] forState:UIControlStateNormal];
	minimizeButton.clipsToBounds = YES;
	[minimizeButton addTarget:self action:@selector(minimizeButtonTap:) forControlEvents:UIControlEventTouchUpInside];
	minimizeButton.backgroundColor = [UIColor colorWithRed:90/255.0f green:191/255.0f blue:255/255.0f alpha:1.0f];
	minimizeButton.layer.cornerRadius = minimizeButton.frame.size.width / 2;
	[self addSubview:minimizeButton];

	swapOrientationButton = [UIButton buttonWithType:UIButtonTypeCustom];
	swapOrientationButton.frame = CGRectMake(self.frame.size.width - (36 + 5), 2, 36, 36);
	swapOrientationButton.clipsToBounds = YES;
	[swapOrientationButton setTitle:@"↺" forState:UIControlStateNormal];
	[swapOrientationButton addTarget:self action:@selector(swapOrientationButtonTap:) forControlEvents:UIControlEventTouchUpInside];
	swapOrientationButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
	swapOrientationButton.layer.cornerRadius = swapOrientationButton.frame.size.width / 2;
	//[self addSubview:swapOrientationButton];

	sizingLocked = NO;
	appRotationLocked = NO;
	sizingLockButton = [UIButton buttonWithType:UIButtonTypeCustom];
	sizingLockButton.frame = swapOrientationButton.frame;
	sizingLockButton.titleLabel.font = [UIFont systemFontOfSize:13];
	[sizingLockButton setImage:[RAResourceImageProvider imageForFilename:@"Unlocked" size:CGSizeMake(16, 16) tintedTo:[UIColor.blackColor colorWithAlphaComponent:0.5]] forState:UIControlStateNormal];
	sizingLockButton.clipsToBounds = YES;
	[sizingLockButton addTarget:self action:@selector(sizingLockButtonTap:) forControlEvents:UIControlEventTouchUpInside];
	sizingLockButton.backgroundColor = [UIColor colorWithRed:185/255.0f green:116/255.0f blue:245/255.0f alpha:1.0f];
	sizingLockButton.layer.cornerRadius = sizingLockButton.frame.size.width / 2;
	[self addSubview:sizingLockButton];

	CAShapeLayer * maskLayer = [CAShapeLayer layer];
	maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners: UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii: (CGSize){6.0, 6.0}].CGPath;
	self.layer.mask = maskLayer;
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

-(void) saveWindowInfo
{
	[RAWindowStatePreservationSystemManager.sharedInstance saveWindowInformation:self];
	if (self.desktop)
	{
		[self.desktop saveInfo];
	}
}

-(BOOL) isLocked
{
	if ([RASettings.sharedInstance windowRotationLockMode] == 0)
	{
		return sizingLocked;
	}
	else
	{
		return appRotationLocked;
	}
}

-(void) sizingLockButtonTap:(id)arg1
{
	if ([RASettings.sharedInstance windowRotationLockMode] == 0)
	{
		sizingLocked = !sizingLocked;
	}
	else
	{
		appRotationLocked = !appRotationLocked;
	}

	if (sizingLocked || appRotationLocked)
	{
		[sizingLockButton setImage:[RAResourceImageProvider imageForFilename:@"Lock" size:CGSizeMake(16, 16) tintedTo:[UIColor.blackColor colorWithAlphaComponent:0.5]] forState:UIControlStateNormal];
	}
	else
	{
		[sizingLockButton setImage:[RAResourceImageProvider imageForFilename:@"Unlocked" size:CGSizeMake(16, 16) tintedTo:[UIColor.blackColor colorWithAlphaComponent:0.5]] forState:UIControlStateNormal];
	}
}


-(void) scaleTo:(CGFloat)scale animated:(BOOL)animate
{
	CGFloat rotation = atan2(self.transform.b, self.transform.a);

	if (animate)
		[UIView animateWithDuration:0.2 animations:^{
	    	[self setTransform:CGAffineTransformRotate(CGAffineTransformMakeScale(scale, scale), rotation)];
	    }];
	else 
		[self setTransform:CGAffineTransformRotate(CGAffineTransformMakeScale(scale, scale), rotation)];
}

-(void) addRotation:(CGFloat)rads updateApp:(BOOL)update
{
	if (sizingLocked)
		return;
	
	if (rads != 0)
		self.transform = CGAffineTransformRotate(self.transform, rads);

    if (update)
	{
    	CGFloat currentRotation = RADIANS_TO_DEGREES(atan2(self.transform.b, self.transform.a));
    	CGFloat rotateSnapDegrees = 0;

    	if (currentRotation < 0) currentRotation = 360 + currentRotation;

    	UIInterfaceOrientation o = UIInterfaceOrientationPortrait;
    	if (currentRotation >= 315 || currentRotation <= 45)
    	{
    		o = UIInterfaceOrientationPortrait;
    		rotateSnapDegrees = 360 - currentRotation;
    	}
    	else if (currentRotation > 45 && currentRotation <= 135)
    	{
    		o = UIInterfaceOrientationLandscapeLeft;
    		rotateSnapDegrees = 90 - currentRotation;
    	}
    	else if (currentRotation > 135 && currentRotation <= 215)
    	{
    		o = UIInterfaceOrientationPortraitUpsideDown;
    		rotateSnapDegrees = 180 - currentRotation;
    	}
    	else
    	{
    		o = UIInterfaceOrientationLandscapeRight;
    		rotateSnapDegrees = 270 - currentRotation;
    	}

    	if ([RASettings.sharedInstance snapRotation])
	    	[UIView animateWithDuration:0.2 animations:^{
		    	self.transform = CGAffineTransformRotate(self.transform, DEGREES_TO_RADIANS(rotateSnapDegrees));
		    }];

		if (!appRotationLocked)
	    	[attachedView rotateToOrientation:o];

		if ([RASettings.sharedInstance snapWindows] && [RAWindowSnapDataProvider shouldSnapWindowAtLocation:self.frame])
		{
			[RAWindowSnapDataProvider snapWindow:self toLocation:[RAWindowSnapDataProvider snapLocationForWindowLocation:self.frame] animated:YES];
			isSnapped = YES;
		}
    }
}

-(void) disableLongPress
{
	enableLongPress = NO;
	longPressGesture.enabled = NO;
	longPressGesture.enabled = YES;
}

-(void) enableLongPress
{
	enableLongPress = YES;
}

-(void) swapOrientationButtonTap:(id)arg1
{
	[self addRotation:DEGREES_TO_RADIANS(90) updateApp:YES];
}

- (void)handleRotate:(UIRotationGestureRecognizer *)gesture
{
	if ([RASettings.sharedInstance alwaysEnableGestures] == NO && self.isOverlayShowing == NO)
		return;

    if (gesture.state == UIGestureRecognizerStateChanged)
    {
    	[self addRotation:gesture.rotation updateApp:NO];
        //[self setTransform:CGAffineTransformRotate(self.transform, gesture.rotation)];
        gesture.rotation = 0.0;
    }
    else if (gesture.state == UIGestureRecognizerStateEnded)
	{
    	[self addRotation:0 updateApp:YES];
		[self saveWindowInfo];
    }
}

-(void) handleLongPress:(UILongPressGestureRecognizer*)sender
{
	if (!enableLongPress)
	{
		return;
	}

	[self close];
}

-(void) showOverlay
{
	RAWindowOverlayView *overlay = [[RAWindowOverlayView alloc] initWithFrame:CGRectMake(0, 40, self.bounds.size.width, self.bounds.size.height - 40)];
	overlay.alpha = 0;
	overlay.tag = 465982;
	overlay.appWindow = self;
	[overlay show];
	[self addSubview:overlay];

	[UIView animateWithDuration:0.4 animations:^{
		closeButton.alpha = 0;
		maximizeButton.alpha = 0;
		minimizeButton.alpha = 0;
		sizingLockButton.alpha = 0;
		overlay.alpha = 1;
	}];
}

-(void) hideOverlay
{
	[(RAWindowOverlayView*)[self viewWithTag:465982] dismiss];
	[UIView animateWithDuration:0.5 animations:^{
		closeButton.alpha = 1;
		maximizeButton.alpha = 1;
		minimizeButton.alpha = 1;
		sizingLockButton.alpha = 1;
	}];
}

-(BOOL) isOverlayShowing { return [self viewWithTag:465982] != nil; }

-(void) handleTap:(UITapGestureRecognizer*)tap
{
	if (!self.isOverlayShowing)
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
	static void (^adjustFrames)(CGRect selfTarget) = ^(CGRect selfTarget) {
		self.bounds = selfTarget;
		[self viewWithTag:bottomSizeViewTag].bounds = CGRectMake(0, self.bounds.size.height, self.bounds.size.width, 20);
		[self viewWithTag:rightSizeViewTag].bounds = CGRectMake(self.bounds.size.width, 30, 20, self.bounds.size.height - 20);
		self.attachedView.bounds = CGRectMake(0, 30, self.bounds.size.width, self.bounds.size.height - 30);
	};

	BOOL didSize = NO;

	if (sender.view.tag == bottomSizeViewTag)
	{
		static CGFloat orig;

		if (sender.state == UIGestureRecognizerStateBegan)
		{
			orig = self.bounds.size.height;
		}
		else if (sender.state == UIGestureRecognizerStateChanged)
		{
			CGRect f = self.bounds;
			f.size.height = orig + [sender translationInView:self].y;
			adjustFrames(f);
		}
		didSize = YES;
	}
	if (sender.view.tag == rightSizeViewTag)
	{
		static CGFloat orig;

		if (sender.state == UIGestureRecognizerStateBegan)
		{
			orig = self.bounds.size.width;
		}
		else if (sender.state == UIGestureRecognizerStateChanged)
		{
			CGRect f = self.bounds;
			f.size.width = orig + [sender translationInView:self].x;
			adjustFrames(f);
		}
		didSize = YES;
	}

	if (!enableDrag || didSize)
		return;

	if (sender.state == UIGestureRecognizerStateBegan)
	{
		[self.superview bringSubviewToFront:self];
		initialPoint = sender.view.center;
	}
	else if (sender.state == UIGestureRecognizerStateChanged)
	{
		enableLongPress = NO;
	}
	else if (sender.state == UIGestureRecognizerStateEnded)
	{
		enableLongPress = YES;
		[self saveWindowInfo];

		if ([RASettings.sharedInstance snapWindows] && [RAWindowSnapDataProvider shouldSnapWindowAtLocation:self.frame])
		{
			[RAWindowSnapDataProvider snapWindow:self toLocation:[RAWindowSnapDataProvider snapLocationForWindowLocation:self.frame] animated:YES];
			isSnapped = YES;
			// Force tap to fail
			tapGesture.enabled = NO;
			tapGesture.enabled = YES;
			return;
		}
	}

	isSnapped = NO;
    UIView *view = sender.view;
    CGPoint point = [sender translationInView:self.superview];

    CGPoint translatedPoint = CGPointMake(initialPoint.x + point.x, initialPoint.y + point.y);
    view.center = translatedPoint;
}

- (void)handlePinch:(UIPinchGestureRecognizer *)gesture
{
	if ([RASettings.sharedInstance alwaysEnableGestures] == NO && self.isOverlayShowing == NO)
		return;

	//CGFloat oldScale = sqrt(self.transform.a * self.transform.a + self.transform.c * self.transform.c);
	//CGFloat newScale = (oldScale + gesture.scale);
	//newScale = MIN(MAX(newScale, 0.1), 0.98);
	//newScale -= oldScale;

	CGFloat scale;
	CGFloat rotation = atan2(self.transform.b, self.transform.a);

    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
        	enableDrag = NO; enableLongPress = NO;
            break;
        case UIGestureRecognizerStateChanged:
            [self setTransform:CGAffineTransformScale(self.transform, gesture.scale, gesture.scale)];
            
            scale = sqrt(self.transform.a * self.transform.a + self.transform.c * self.transform.c);
            if (scale > 1.0)
            {
            	[self setTransform:CGAffineTransformRotate(CGAffineTransformMakeScale(1, 1), rotation)];
            }
            else if (scale < 0.15)
            {
            	[self setTransform:CGAffineTransformRotate(CGAffineTransformMakeScale(0.15, 0.15), rotation)];
            }

            gesture.scale = 1.0;
            break;
        case UIGestureRecognizerStateEnded:
        	enableDrag = YES; enableLongPress = YES;
			
			if (isSnapped && [RAWindowSnapDataProvider shouldSnapWindowAtLocation:self.frame])
			{
				[RAWindowSnapDataProvider snapWindow:self toLocation:[RAWindowSnapDataProvider snapLocationForWindowLocation:self.frame] animated:YES];
				isSnapped = YES;
				// Force tap to fail
				tapGesture.enabled = NO;
				tapGesture.enabled = YES;
				return;
			}
			[self saveWindowInfo];

            break;
        default:
            break;
    }
}

-(void) setTransform:(CGAffineTransform)trans
{
	CGPoint center = self.center;
	[super setTransform:trans];
	self.center = center;

	/*if (self.frame.origin.x < 0 || self.frame.origin.x + self.frame.size.width > UIScreen.mainScreen.bounds.size.width)
		[UIView animateWithDuration:0.1 animations:^{
			CGFloat oldScale = sqrt(self.transform.a * self.transform.a + self.transform.c * self.transform.c);
			CGFloat scale = UIScreen.mainScreen.bounds.size.width / (self.frame.origin.x + self.frame.size.width);
			self.transform = CGAffineTransformScale(self.transform, fabs(oldScale - scale), fabs(oldScale - scale));
		}];*/
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
	return isContained || [super pointInside:point withEvent:event];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer 
{
	if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
		return NO;
	return YES; 
}
-(RAHostedAppView*) attachedView { return attachedView; }
@end