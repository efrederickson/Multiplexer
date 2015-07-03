#import "RAGestureManager.h"
#import "RASwipeOverManager.h"

%ctor
{
    [[RAGestureManager sharedInstance] addGestureRecognizer:^(UIGestureRecognizerState state, CGPoint location) {
        static CGPoint startingPoint, lastPoint;
        CGPoint translation;
        switch (state) {
            case UIGestureRecognizerStateBegan:
                startingPoint = location;
                break;
            case UIGestureRecognizerStateChanged:
                translation = CGPointMake(location.x - startingPoint.x, location.y - startingPoint.y);
                break;
            case UIGestureRecognizerStateEnded:
                startingPoint = CGPointZero;
                break;
        }

        if (![RASwipeOverManager.sharedInstance isUsingSwipeOver])
            [RASwipeOverManager.sharedInstance startUsingSwipeOver];
        [RASwipeOverManager.sharedInstance sizeViewForTranslation:translation state:state];
        lastPoint = location;
    } withCondition:^BOOL(CGPoint location) {
        return YES; 
        //return [[UIApplication sharedApplication] _accessibilityFrontMostApplication] != nil;
    } forEdge:UIRectEdgeRight];
}

/*
    RegisterEdgeObserverBlock(UIRectEdgeRight, ^BOOL(CGPoint location) { return [[UIApplication sharedApplication] _accessibilityFrontMostApplication] != nil; }, ^(UIGestureRecognizerState state, CGPoint location, CGPoint velocity){
    	NSLog(@"[ReachApp] Right Edge Swipe: %@ %@ %@", @(state), NSStringFromCGPoint(location), NSStringFromCGPoint(velocity));
        static CGPoint startingPoint, lastPoint;
        CGPoint translation;
        switch (state) {
            case UIGestureRecognizerStateBegan:
                startingPoint = location;
                break;
            case UIGestureRecognizerStateChanged:
            	translation = CGPointMake(location.x - startingPoint.x, location.y - startingPoint.y);
                break;
            case UIGestureRecognizerStateEnded:
            	startingPoint = CGPointZero;
                break;
        }
        NSLog(@"[ReachApp] translation: %@", NSStringFromCGPoint(translation));

		if (![RASwipeOverManager.sharedInstance isUsingSwipeOver])
			[RASwipeOverManager.sharedInstance startUsingSwipeOver];
		[RASwipeOverManager.sharedInstance sizeViewForTranslation:translation state:state];
		lastPoint = location;
    });
*/