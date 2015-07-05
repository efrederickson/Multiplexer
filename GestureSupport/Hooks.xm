#import "headers.h"
#import "RAGestureManager.h"

/*
Some code modified or adapted or based off of MultitaskingGestures by HamzaSood. 
MultitaskingGestures source code: https://github.com/hamzasood/MultitaskingGestures/
License (GPL): https://github.com/hamzasood/MultitaskingGestures/blob/master/License.md
*/

static BOOL isTracking = NO;
static NSMutableSet *gestureRecognizers;
BOOL shouldBeOverridingForRecognizer;
UIRectEdge currentEdge;

%hook SBHandMotionExtractor
-(id) init 
{
    if ((self = %orig))
    {
        for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers)
            [recognizer setDelegate:(id<_UIScreenEdgePanRecognizerDelegate>)self];
    }
    return self;
}

-(void) extractHandMotionForActiveTouches:(SBActiveTouch *)activeTouches count:(NSUInteger)count centroid:(CGPoint)centroid 
{
    %orig;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (count) {
            SBActiveTouch touch = activeTouches[0];
            if (touch.type == 0) // Begin
            {
                for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers)
                    [recognizer incorporateTouchSampleAtLocation:touch.unrotatedLocation timestamp:CACurrentMediaTime() modifier:touch.modifier interfaceOrientation:touch.interfaceOrientation];
                isTracking = YES;
            }
            else if (isTracking) // Move
            {
                for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers)
                    [recognizer incorporateTouchSampleAtLocation:touch.unrotatedLocation timestamp:CACurrentMediaTime() modifier:touch.modifier interfaceOrientation:touch.interfaceOrientation];
                [RAGestureManager.sharedInstance handleMovementOrStateUpdate:UIGestureRecognizerStateChanged withPoint:touch.location forEdge:currentEdge];
            }
        }
    });
}

%new -(void) screenEdgePanRecognizerStateDidChange:(_UIScreenEdgePanRecognizer *)screenEdgePanRecognizer 
{
    if (screenEdgePanRecognizer.state == 1) 
    {
        CGPoint location = MSHookIvar<CGPoint>(screenEdgePanRecognizer, "_lastTouchLocation");
        if (shouldBeOverridingForRecognizer == NO)
            shouldBeOverridingForRecognizer = [RAGestureManager.sharedInstance canHandleMovementWithPoint:location forEdge:screenEdgePanRecognizer.targetEdges];
        if (shouldBeOverridingForRecognizer) 
        {
            if ([RAGestureManager.sharedInstance handleMovementOrStateUpdate:UIGestureRecognizerStateBegan withPoint:location forEdge:screenEdgePanRecognizer.targetEdges])
            {
                currentEdge = screenEdgePanRecognizer.targetEdges;
                BKSHIDServicesCancelTouchesOnMainDisplay(); // Don't send to the app, or anywhere else
            }
        }
    }
}

-(void) clear {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (isTracking) // Ended
        {
            [RAGestureManager.sharedInstance handleMovementOrStateUpdate:UIGestureRecognizerStateEnded withPoint:CGPointZero forEdge:currentEdge];
            for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers)
                [recognizer reset]; // remove current touches it's "incorporated"
            shouldBeOverridingForRecognizer = NO;
            currentEdge = UIRectEdgeNone;
            isTracking = NO;
        }
    });
    %orig;
}

%end

%ctor 
{
    class_addProtocol(objc_getClass("SBHandMotionExtractor"), @protocol(_UIScreenEdgePanRecognizerDelegate));
    
    UIRectEdge edgesToWatch[] = { UIRectEdgeBottom, UIRectEdgeLeft, UIRectEdgeRight, UIRectEdgeTop };
    int edgeCount = sizeof(edgesToWatch) / sizeof(UIRectEdge);
    gestureRecognizers = [[NSMutableSet alloc] initWithCapacity:edgeCount];
    for (int i = 0; i < edgeCount; i++) 
    {
        _UIScreenEdgePanRecognizer *recognizer = [[_UIScreenEdgePanRecognizer alloc] initWithType:2];
        [recognizer setTargetEdges:edgesToWatch[i]];
        [recognizer setScreenBounds:[[UIScreen mainScreen] bounds]];
        [gestureRecognizers addObject:recognizer];
    }

    %init;
}