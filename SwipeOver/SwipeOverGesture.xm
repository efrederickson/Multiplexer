#import "RAGestureManager.h"
#import "RASwipeOverManager.h"

%ctor
{
    [[RAGestureManager sharedInstance] addGestureRecognizer:^RAGestureCallbackResult(UIGestureRecognizerState state, CGPoint location) {
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

        return RAGestureCallbackResultSuccess;
    } withCondition:^BOOL(CGPoint location) {
        return [[%c(SBLockScreenManager) sharedInstance] isUILocked]; 
        //return [[UIApplication sharedApplication] _accessibilityFrontMostApplication] != nil;
    } forEdge:UIRectEdgeRight identifier:@"com.efrederickson.reachapp.swipeover.systemgesture" priority:RAGesturePriorityDefault];
}