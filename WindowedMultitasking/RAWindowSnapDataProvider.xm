#import "RAWindowSnapDataProvider.h"

@implementation RAWindowSnapDataProvider
+(BOOL) shouldSnapWindow:(RAWindowBar*)bar
{
	return [RAWindowSnapDataProvider snapLocationForWindow:bar] != RAWindowSnapLocationInvalid;
}

+(RAWindowSnapLocation) snapLocationForWindow:(RAWindowBar*)windowBar
{
	CGRect location = windowBar.frame;

	// Convienence values
	CGFloat width = UIScreen.mainScreen._referenceBounds.size.width;
	CGFloat height = UIScreen.mainScreen._referenceBounds.size.height;
	//CGFloat oneThirdsHeight = height / 4;
	CGFloat twoThirdsHeight = (height / 4) * 3;

	CGFloat leftXBuffer = 25;
	CGFloat rightXBuffer = width - 25;
	CGFloat bottomBuffer = height - 25;

	CGPoint topLeft = windowBar.center;
	topLeft.x -= location.size.width / 2;
	topLeft.y -= location.size.height / 2;
	topLeft = CGPointApplyAffineTransform(topLeft, windowBar.transform);

	CGPoint topRight = windowBar.center;
	topRight.x += location.size.width / 2;
	topRight.y -= location.size.height / 2;
	topRight = CGPointApplyAffineTransform(topRight, windowBar.transform);

	CGPoint bottomLeft = windowBar.center;
	bottomLeft.x -= location.size.width / 2;
	bottomLeft.y += location.size.height / 2;
	bottomLeft = CGPointApplyAffineTransform(bottomLeft, windowBar.transform);

	CGPoint bottomRight = windowBar.center;
	bottomRight.x += location.size.width / 2;
	bottomRight.y += location.size.height / 2;
	//bottomRight = CGPointApplyAffineTransform(bottomRight, theView.transform);
	
	// I am not proud of the below jumps, however i do believe it is the best solution to the problem apart from making weird blocks, which would be a considerable amount of work.

	BOOL didLeft = NO;
	BOOL didRight = NO;

	if (topLeft.x > bottomLeft.x)
		goto try_right;

	if (topLeft.y > bottomLeft.y)
		goto try_bottom;

try_left:
	didLeft = YES;
	// Left
	if (location.origin.x < leftXBuffer && location.origin.y < height / 8)
		return RAWindowSnapLocationLeftTop;
	if (location.origin.x < leftXBuffer && (location.origin.y >= twoThirdsHeight || location.origin.y + location.size.height > height))
		return RAWindowSnapLocationLeftBottom;
	if (location.origin.x < leftXBuffer && location.origin.y >= height / 8 && location.origin.y < twoThirdsHeight)
		return RAWindowSnapLocationLeftMiddle;

try_right:
	didRight = YES;
	// Right
	if (location.origin.x + location.size.width > rightXBuffer && location.origin.y < height / 8)
		return RAWindowSnapLocationRightTop;
	if (location.origin.x + location.size.width > rightXBuffer && (location.origin.y >= twoThirdsHeight || location.origin.y + location.size.height > height))
		return RAWindowSnapLocationRightBottom;
	if (location.origin.x + location.size.width > rightXBuffer && location.origin.y >= height / 8 && location.origin.y < twoThirdsHeight)
		return RAWindowSnapLocationRightMiddle;

	if (!didLeft)
		goto try_left;
	else if (!didRight)
		goto try_right;

try_bottom:

	// Jumps through this off slightly, so we re-check (which may or may not actually be needed, depending on the path it takes)
	if (location.origin.x + location.size.width > rightXBuffer && (location.origin.y >= twoThirdsHeight || location.origin.y + location.size.height > height))
		return RAWindowSnapLocationRightBottom;
	if (location.origin.x < leftXBuffer && (location.origin.y >= twoThirdsHeight || location.origin.y + location.size.height > height))
		return RAWindowSnapLocationLeftBottom;

	if (location.origin.y + location.size.height > bottomBuffer)
		return RAWindowSnapLocationBottom;

//try_top:

	if (location.origin.y < 20 + 25)
		return RAWindowSnapLocationTop;

	// Second time possible verify
	if (!didLeft)
		goto try_left;
	else if (!didRight)
		goto try_right;

	return RAWindowSnapLocationNone;
}

+(CGPoint) snapCenterForWindow:(RAWindowBar*)window toLocation:(RAWindowSnapLocation)location
{
	// Convienence values
	CGFloat width = UIScreen.mainScreen._referenceBounds.size.width;
	CGFloat height = UIScreen.mainScreen._referenceBounds.size.height;

	// Target frame values
	CGRect frame = window.frame;
	CGPoint newCenter = window.center;

	BOOL adjustStatusBar = NO;

	switch (location)
	{
		case RAWindowSnapLocationLeftTop:
			newCenter = CGPointMake(frame.size.width / 2, (frame.size.height / 2) + 20);
			adjustStatusBar = YES;
			break;
		case RAWindowSnapLocationLeftMiddle:
			newCenter.x = frame.size.width / 2;
			break;
		case RAWindowSnapLocationLeftBottom:
			newCenter = CGPointMake(frame.size.width / 2, height - (frame.size.height / 2));
			break;

		case RAWindowSnapLocationRightTop:
			newCenter = CGPointMake(width - (frame.size.width / 2), (frame.size.height / 2) + 20);
			adjustStatusBar = YES;
			break;
		case RAWindowSnapLocationRightMiddle:
			newCenter.x = width - (frame.size.width / 2);
			break;
		case RAWindowSnapLocationRightBottom:
			newCenter = CGPointMake(width - (frame.size.width / 2), height - (frame.size.height / 2));
			break;

		case RAWindowSnapLocationTop:
			newCenter.y = (frame.size.height / 2) + 20;
			adjustStatusBar = YES;
			break;
		case RAWindowSnapLocationBottom:
			newCenter.y = height - (frame.size.height / 2);
			break;

		case RAWindowSnapLocationBottomCenter:
			newCenter.x = width / 2.0;
			newCenter.y = height - (frame.size.height / 2);
			break;

		case RAWindowSnapLocationInvalid:
		default:
			break;
	}

	if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeRight && adjustStatusBar)
	{
		newCenter.y -= 20;
	}
	if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeRight && (location == RAWindowSnapLocationRightMiddle || location == RAWindowSnapLocationRightBottom || location == RAWindowSnapLocationRightTop))
	{
		newCenter.x -= 20;
	}
	else if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeLeft && adjustStatusBar)
	{
		newCenter.y -= 20;
	}
	if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeLeft && (location == RAWindowSnapLocationLeftMiddle || location == RAWindowSnapLocationLeftBottom || location == RAWindowSnapLocationLeftTop))
	{
		newCenter.x += 20;
	}

	return newCenter;
}

+(void) snapWindow:(RAWindowBar*)window toLocation:(RAWindowSnapLocation)location animated:(BOOL)animated
{
	/*
	// Convienence values
	CGFloat width = UIScreen.mainScreen.bounds.size.width;
	CGFloat height = UIScreen.mainScreen.bounds.size.height;

	// Target frame values
	CGRect frame = window.frame;
	CGPoint adjustedOrigin = window.frame.origin;

	switch (location)
	{
		case RAWindowSnapLocationLeftTop:
			adjustedOrigin = CGPointMake(0, 20);
			break;
		case RAWindowSnapLocationLeftMiddle:
			adjustedOrigin.x = 0;
			break;
		case RAWindowSnapLocationLeftBottom:
			adjustedOrigin = CGPointMake(0, height - frame.size.height);
			break;

		case RAWindowSnapLocationRightTop:
			adjustedOrigin = CGPointMake(width - frame.size.width, 20);
			break;
		case RAWindowSnapLocationRightMiddle:
			adjustedOrigin.x = width - frame.size.width;
			break;
		case RAWindowSnapLocationRightBottom:
			adjustedOrigin = CGPointMake(width - frame.size.width, height - frame.size.height);
			break;

		case RAWindowSnapLocationTop:
			adjustedOrigin.y = 20;
			break;
		case RAWindowSnapLocationBottom:
			adjustedOrigin.y = height - frame.size.height;
			break;

		case RAWindowSnapLocationInvalid:
		default:
			break;
	}

	if (animated)
	{
		[UIView animateWithDuration:0.2 animations:^{
			window.frame = (CGRect) { adjustedOrigin, frame.size };
		}];
	}
	else
		window.frame = (CGRect) { adjustedOrigin, frame.size };
	*/

	[self snapWindow:window toLocation:location animated:animated completion:nil];
}

+(void) snapWindow:(RAWindowBar*)window toLocation:(RAWindowSnapLocation)location animated:(BOOL)animated completion:(dispatch_block_t)completionBlock
{
	CGPoint newCenter = [RAWindowSnapDataProvider snapCenterForWindow:window toLocation:location];

	if (animated)
	{
		[UIView animateWithDuration:0.2 animations:^{
			window.center = newCenter;
		} completion:^(BOOL _) {
			if (completionBlock)
				completionBlock();
		}];
	}
	else
	{
		window.center = newCenter;
		if (completionBlock)
			completionBlock();
	}
}
@end

RAWindowSnapLocation RAWindowSnapLocationGetLeftOfScreen()
{
	switch (UIApplication.sharedApplication.statusBarOrientation)
	{
		case UIInterfaceOrientationPortrait:
			return RAWindowSnapLocationLeft;
		case UIInterfaceOrientationLandscapeRight:
			return RAWindowSnapLocationTop;
		case UIInterfaceOrientationLandscapeLeft:
			return RAWindowSnapLocationBottom;
		case UIInterfaceOrientationPortraitUpsideDown:
			return RAWindowSnapLocationRight;
	}
	return RAWindowSnapLocationLeft;
}

RAWindowSnapLocation RAWindowSnapLocationGetRightOfScreen()
{
	switch (UIApplication.sharedApplication.statusBarOrientation)
	{
		case UIInterfaceOrientationPortrait:
			return RAWindowSnapLocationRight;
		case UIInterfaceOrientationLandscapeRight:
			return RAWindowSnapLocationBottom;
		case UIInterfaceOrientationLandscapeLeft:
			return RAWindowSnapLocationTop;
		case UIInterfaceOrientationPortraitUpsideDown:
			return RAWindowSnapLocationLeft;
	}
	return RAWindowSnapLocationRight;
}

