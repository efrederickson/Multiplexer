#import "RAAppSliderProviderView.h"
#import "RAHostedAppView.h"
#import "RAGestureManager.h"
#import "RAAppSliderProvider.h"
#include <execinfo.h>

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

	[RAGestureManager.sharedInstance removeGestureWithIdentifier:currentView.bundleIdentifier];
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

		[RAGestureManager.sharedInstance addGestureRecognizerWithTarget:self forEdge:UIRectEdgeLeft | UIRectEdgeRight identifier:currentView.bundleIdentifier priority:RAGesturePriorityHigh];
		//[RAGestureManager.sharedInstance addGestureRecognizerWithTarget:self forEdge:UIRectEdgeRight identifier:currentView.bundleIdentifier priority:RAGesturePriorityHigh];

    	currentView.frame = CGRectMake(0, 0, self.frame.size.width - 0, self.frame.size.height);
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

-(BOOL) RAGestureCallback_canHandle:(CGPoint)point velocity:(CGPoint)velocity
{
	return point.y <= [self convertPoint:self.frame.origin toView:nil].y + self.frame.size.height;
}

-(RAGestureCallbackResult) RAGestureCallback_handle:(UIGestureRecognizerState)state withPoint:(CGPoint)location velocity:(CGPoint)velocity forEdge:(UIRectEdge)edge
{
	static BOOL didHandle = NO;
	if (state == UIGestureRecognizerStateEnded)
	{
		didHandle = NO;
		return RAGestureCallbackResultSuccessAndStop;
	}
	if (didHandle) return RAGestureCallbackResultSuccessAndStop;

	if (edge == UIRectEdgeLeft)
	{
		didHandle = YES;
		if (self.swipeProvider.canGoLeft)
		{
			[self unload];
			[self goToTheLeft];
		}
		return RAGestureCallbackResultSuccessAndStop;
	}
	else if (edge == UIRectEdgeRight)
	{
		didHandle = YES;
		if (self.swipeProvider.canGoRight)
		{
			[self unload];
			[self goToTheRight];
		}
		return RAGestureCallbackResultSuccessAndStop;
	}
	return RAGestureCallbackResultFailure;
}
@end