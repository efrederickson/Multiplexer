#import "headers.h"

/*
%hook UIWindow
- (id) initWithFrame:(CGRect)frame
{
	id o = %orig;

	UIScreenEdgePanGestureRecognizer *gesture = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(RA_handleEdgeSwipe:)];
	gesture.edges = UIRectEdgeRight;
	[self addGestureRecognizer:gesture];

	return o;
}

%new -(void) RA_handleEdgeSwipe:(UIScreenEdgePanGestureRecognizer*)gesture
{
	CGPoint translation = [gesture translationInView:gesture.view];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.resize.edgeswipeview"), NULL, (__bridge CFDictionaryRef) @{
	    @"point": NSStringFromCGPoint(translation),
	    @"state": @(gesture.state),
	}, true);
}
%end

%ctor
{
	//if ([NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"] == NO)
	{
		%init;
	}
}
*/