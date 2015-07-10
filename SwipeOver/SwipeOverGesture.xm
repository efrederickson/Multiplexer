#import "RAGestureManager.h"
#import "RASwipeOverManager.h"
#import "RAKeyboardStateListener.h"
#import "RAMissionControlManager.h"

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
        if (RAKeyboardStateListener.sharedInstance.visible)
        {
            CGRect realKBFrame = CGRectMake(0, UIScreen.mainScreen.bounds.size.height, RAKeyboardStateListener.sharedInstance.size.width, RAKeyboardStateListener.sharedInstance.size.height);
            realKBFrame = CGRectOffset(realKBFrame, 0, -realKBFrame.size.height);

            if (CGRectContainsPoint(realKBFrame, location))
                return NO;
        }
        
        return ![[%c(SBLockScreenManager) sharedInstance] isUILocked] && !RAMissionControlManager.sharedInstance.isShowingMissionControl;
    } forEdge:UIRectEdgeRight identifier:@"com.efrederickson.reachapp.swipeover.systemgesture" priority:RAGesturePriorityDefault];
}