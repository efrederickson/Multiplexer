#import "RAAppSliderProviderView.h"
#import "RAHostedAppView.h"
#import "RAGestureManager.h"
#import "RAAppSliderProvider.h"

@interface RAAppSliderProviderView () {
	RAHostedAppView *currentView;
}
@end

@implementation RAAppSliderProviderView
@synthesize swipeProvider;

-(void) goToTheLeft
{
	[swipeProvider goToTheLeft];
	[self updateCurrentView];
}

-(void) goToTheRight
{
	[swipeProvider goToTheRight];
	[self updateCurrentView];
}

-(void) load
{
	[currentView loadApp];
}

-(void) unload
{
	if (!currentView || !currentView.bundleIdentifier)
		return;

    CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.endresizing"), NULL, (__bridge CFDictionaryRef)@{ @"bundleIdentifier": currentView.bundleIdentifier }, NO);

	[RAGestureManager.sharedInstance stopIgnoringSwipesForIdentifier:currentView.bundleIdentifier];
	[currentView unloadApp];
}

-(void) updateCurrentView
{
	[self unload];
	if (currentView)
		[currentView removeFromSuperview];
	currentView = [swipeProvider viewAtCurrentIndex];

	if (self.isSwipeable && self.swipeProvider)
    {
    	self.backgroundColor = [UIColor clearColor]; // redColor];
    	self.userInteractionEnabled = YES;

    	if (!leftSwipeGestureRecognizer)
    	{
	    	leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
			leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
			[self addGestureRecognizer:leftSwipeGestureRecognizer];	
    	}
		
		if (!rightSwipeGestureRecognizer)
		{
			rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
			rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
			[self addGestureRecognizer:rightSwipeGestureRecognizer];
		}

		[RAGestureManager.sharedInstance ignoreSwipesBeginningInRect:CGRectMake(self.frame.origin.x, [self convertPoint:CGPointMake(0, 0) toView:nil].y, self.frame.size.width, self.frame.size.height) forIdentifier:currentView.bundleIdentifier];

    	currentView.frame = CGRectMake(6, 0, self.frame.size.width - 12, self.frame.size.height);
    }
    else
    	currentView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    [self addSubview:currentView];
    [self load];
}

-(CGRect) clientFrame
{
	if (!currentView) return CGRectZero;

	CGRect frame = currentView.frame;
	frame.size.height = self.frame.size.height;
	return frame;
}

-(NSString*) currentBundleIdentifier
{
	return currentView ? currentView.bundleIdentifier : nil;
}

-(void) handleSwipe:(UISwipeGestureRecognizer*)gesture
{
	//NSLog(@"[ReachApp] swipe: %@", gesture);
	if (gesture.direction == UISwipeGestureRecognizerDirectionLeft && swipeProvider.canGoRight)
	{
		[self unload];
		[self goToTheRight];
	}
	if (gesture.direction == UISwipeGestureRecognizerDirectionRight && swipeProvider.canGoLeft)
	{
		[self unload];
		[self goToTheLeft];
	}
}
@end