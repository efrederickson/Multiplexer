#import "RAWindowOverlayView.h"
#import "RAResourceImageProvider.h"
#import "SKBounceAnimation.h"
#import "RASettings.h"

@interface RAWindowOverlayView () {
	UIButton *rotationLockButton, *minimizeButton, *maximizeButton, *closeButton;
	CGFloat buttonSize, imageSize;

	BOOL probablyAnimating;
}
@end

@implementation RAWindowOverlayView
-(void) show
{
	probablyAnimating = NO;

	_UIBackdropView *blurView = [[%c(_UIBackdropView) alloc] initWithStyle:2];
	blurView.frame = self.frame;
	blurView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
	[blurView setBlurRadiusSetOnce:NO];
	[blurView setBlurRadius:12.0];

	UITapGestureRecognizer *dismissGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss_)];
	[blurView addGestureRecognizer:dismissGesture];
	blurView.userInteractionEnabled = YES;

	[self addSubview:blurView];

	buttonSize = 100.0;
	imageSize = buttonSize * (60.0/160.0);

	closeButton = [[UIButton alloc] init];
	closeButton.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.2];
	closeButton.titleLabel.textColor = [UIColor whiteColor];
	closeButton.frame = CGRectMake(0, 0, buttonSize, buttonSize);
	closeButton.center = CGPointMake(self.center.x, self.center.y + (closeButton.frame.size.height / 2));
	[closeButton setImage:[RAResourceImageProvider imageForFilename:@"Close" size:CGSizeMake(imageSize, imageSize) tintedTo:[UIColor colorWithRed:255/255.0f green:112/255.0f blue:112/255.0f alpha:1.0f]] forState:UIControlStateNormal];
	closeButton.titleLabel.font = [UIFont systemFontOfSize:36];
	[closeButton addTarget:self action:@selector(buttonPress:) forControlEvents:UIControlEventTouchDown];
	[closeButton addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpInside];
	[closeButton addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpOutside];
	[closeButton addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchCancel];
	[closeButton addTarget:self action:@selector(closeButtonTap) forControlEvents:UIControlEventTouchUpInside];

	closeButton.layer.cornerRadius = buttonSize/2;
	[self addSubview:closeButton];

	maximizeButton = [[UIButton alloc] init];
	maximizeButton.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.2];
	maximizeButton.titleLabel.textColor = [UIColor whiteColor];
	maximizeButton.frame = CGRectMake(0, 0, buttonSize, buttonSize);
	maximizeButton.center = CGPointMake(self.center.x - maximizeButton.frame.size.width, self.center.y - (maximizeButton.frame.size.height / 2));
	[maximizeButton setImage:[RAResourceImageProvider imageForFilename:@"Plus" size:CGSizeMake(imageSize, imageSize) tintedTo:[UIColor colorWithRed:115/255.0f green:232/255.0f blue:166/255.0f alpha:1.0f]] forState:UIControlStateNormal];
	maximizeButton.titleLabel.font = [UIFont systemFontOfSize:36];
	[maximizeButton addTarget:self action:@selector(buttonPress:) forControlEvents:UIControlEventTouchDown];
	[maximizeButton addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpInside];
	[maximizeButton addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpOutside];
	[maximizeButton addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchCancel];
	[maximizeButton addTarget:self action:@selector(maximizeButtonTap) forControlEvents:UIControlEventTouchUpInside];
	maximizeButton.layer.cornerRadius = buttonSize/2;
	[self addSubview:maximizeButton];

	minimizeButton = [[UIButton alloc] init];
	minimizeButton.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.2];
	minimizeButton.titleLabel.textColor = [UIColor whiteColor];
	minimizeButton.frame = CGRectMake(0, 0, buttonSize, buttonSize);
	minimizeButton.center = CGPointMake(self.center.x + minimizeButton.frame.size.width, self.center.y - (minimizeButton.frame.size.height / 2));
	[minimizeButton setImage:[RAResourceImageProvider imageForFilename:@"Minus" size:CGSizeMake(imageSize, imageSize) tintedTo:[UIColor colorWithRed:90/255.0f green:191/255.0f blue:255/255.0f alpha:1.0f]] forState:UIControlStateNormal];
	minimizeButton.titleLabel.font = [UIFont systemFontOfSize:36];
	[minimizeButton addTarget:self action:@selector(buttonPress:) forControlEvents:UIControlEventTouchDown];
	[minimizeButton addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpInside];
	[minimizeButton addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpOutside];
	[minimizeButton addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchCancel];
	[minimizeButton addTarget:self action:@selector(minimizeButtonTap) forControlEvents:UIControlEventTouchUpInside];
	minimizeButton.layer.cornerRadius = buttonSize/2;
	[self addSubview:minimizeButton];

	rotationLockButton = [[UIButton alloc] init];
	rotationLockButton.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.2];
	rotationLockButton.titleLabel.textColor = [UIColor whiteColor];
	rotationLockButton.frame = CGRectMake(0, 0, buttonSize, buttonSize);
	rotationLockButton.center = CGPointMake(self.center.x, self.center.y - (buttonSize * 1.5));
	[rotationLockButton setImage:[RAResourceImageProvider imageForFilename:@"Unlocked" size:CGSizeMake(imageSize, imageSize) tintedTo:[UIColor colorWithRed:185/255.0f green:116/255.0f blue:245/255.0f alpha:1.0f]] forState:UIControlStateNormal];
	rotationLockButton.titleLabel.font = [UIFont systemFontOfSize:36];
	[rotationLockButton addTarget:self action:@selector(buttonPress:) forControlEvents:UIControlEventTouchDown];
	[rotationLockButton addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpInside];
	[rotationLockButton addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpOutside];
	[rotationLockButton addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchCancel];
	[rotationLockButton addTarget:self action:@selector(rotationLockButtonTap) forControlEvents:UIControlEventTouchUpInside];
	rotationLockButton.layer.cornerRadius = buttonSize/2;
	[self addSubview:rotationLockButton];

	if (self.appWindow.isLocked)
	{
		[rotationLockButton setImage:[RAResourceImageProvider imageForFilename:@"Lock" size:CGSizeMake(imageSize, imageSize) tintedTo:[UIColor colorWithRed:185/255.0f green:116/255.0f blue:245/255.0f alpha:1.0f]] forState:UIControlStateNormal];
	}
	else
	{
		[rotationLockButton setImage:[RAResourceImageProvider imageForFilename:@"Unlocked" size:CGSizeMake(imageSize, imageSize) tintedTo:[UIColor colorWithRed:185/255.0f green:116/255.0f blue:245/255.0f alpha:1.0f]] forState:UIControlStateNormal];
	}
}

- (void) buttonPress:(UIButton*)button 
{
	if ([RASettings.sharedInstance windowedMultitaskingCompleteAnimations])
		probablyAnimating = YES;
	//[UIView animateWithDuration:0.2 animations:^{
	//    button.transform = CGAffineTransformMakeScale(1.1, 1.1);
	//}];

	button.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.2];

	[self.appWindow disableLongPress];

	SKBounceAnimation *sizeAnimation = [SKBounceAnimation animationWithKeyPath:@"transform"];
	sizeAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)];
	sizeAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.1, 1.1, 1.0)];
	sizeAnimation.duration = 0.5f;
	sizeAnimation.numberOfBounces = 2;
	sizeAnimation.shouldOvershoot = YES;
	
	[button.layer addAnimation:sizeAnimation forKey:@"bliss"];
	[button.layer setValue:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.1, 1.1, 1.0)] forKeyPath:@"transform"];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		probablyAnimating = NO;
	});
}

- (void) buttonRelease:(UIButton*)button
{
	if ([RASettings.sharedInstance windowedMultitaskingCompleteAnimations])
		probablyAnimating = YES;
	//[UIView animateWithDuration:0.2 animations:^{
	//    button.transform = CGAffineTransformMakeScale(1, 1);
	//}];

	button.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.2];

	SKBounceAnimation *sizeAnimation = [SKBounceAnimation animationWithKeyPath:@"transform"];
	sizeAnimation.fromValue = [NSValue valueWithCATransform3D:button.layer.transform];
	sizeAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1, 1, 1)];
	sizeAnimation.duration = 0.3f;
	sizeAnimation.numberOfBounces = 2;
	sizeAnimation.shouldOvershoot = YES;
	
	[button.layer addAnimation:sizeAnimation forKey:@"bliss"];
	[button.layer setValue:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1, 1, 1)] forKeyPath:@"transform"];

	[self.appWindow performSelector:@selector(enableLongPress) withObject:nil afterDelay:0.3];

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		probablyAnimating = NO;
	});
}

-(void) dismiss_
{
	[self.appWindow hideOverlay];
}

-(void) dismiss
{
	[UIView animateWithDuration:0.5 animations:^{
		self.alpha = 0;
	} completion:^(BOOL _) {
		[self removeFromSuperview];
	}];
}

-(void) closeButtonTap
{
	if (probablyAnimating)
		[self performSelector:@selector(closeButtonTap) withObject:nil afterDelay:0.1];
	else
		[self.appWindow close];
}

-(void) maximizeButtonTap
{
	if (probablyAnimating)
		[self performSelector:@selector(maximizeButtonTap) withObject:nil afterDelay:0.1];
	else
		[self.appWindow maximize];
}

-(void) minimizeButtonTap
{
	if (probablyAnimating)
		[self performSelector:@selector(minimizeButtonTap) withObject:nil afterDelay:0.1];
	else
		[self.appWindow minimize];
}

-(void) rotationLockButtonTap
{
	[self.appWindow sizingLockButtonTap:nil];

	if (self.appWindow.isLocked)
	{
		[rotationLockButton setImage:[RAResourceImageProvider imageForFilename:@"Lock" size:CGSizeMake(imageSize, imageSize) tintedTo:[UIColor colorWithRed:185/255.0f green:116/255.0f blue:245/255.0f alpha:1.0f]] forState:UIControlStateNormal];
	}
	else
	{
		[rotationLockButton setImage:[RAResourceImageProvider imageForFilename:@"Unlocked" size:CGSizeMake(imageSize, imageSize) tintedTo:[UIColor colorWithRed:185/255.0f green:116/255.0f blue:245/255.0f alpha:1.0f]] forState:UIControlStateNormal];
	}
}
@end
