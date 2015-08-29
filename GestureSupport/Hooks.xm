#import "headers.h"
#import "RAGestureManager.h"

/*
Some code modified/adapted/based off of MultitaskingGestures by HamzaSood. 
MultitaskingGestures source code: https://github.com/hamzasood/MultitaskingGestures/
License (GPL): https://github.com/hamzasood/MultitaskingGestures/blob/master/License.md
*/

@interface _UIScreenEdgePanRecognizer (Velocity)
-(CGPoint) RA_velocity;
@end

static BOOL isTracking = NO;
static NSMutableSet *gestureRecognizers;
BOOL shouldBeOverridingForRecognizer;
UIRectEdge currentEdge;

struct VelocityData {
    CGPoint velocity;
    double timestamp;
    CGPoint location;
};

%hook _UIScreenEdgePanRecognizer
- (void)incorporateTouchSampleAtLocation:(CGPoint)location timestamp:(double)timestamp modifier:(NSInteger)modifier interfaceOrientation:(UIInterfaceOrientation)orientation 
{
    %orig;

    VelocityData newData;
    VelocityData oldData;

    [objc_getAssociatedObject(self, @selector(RA_velocityData)) getValue:&oldData];
    
    // this is really quite simple, it calculates a velocity based off of
    // (current location - last location) / (time taken to move from last location to current location)
    // which effectively gives you a CGPoint of where it would end if the user continued the gesture.
    CGPoint velocity = CGPointMake((location.x - oldData.location.x) / (timestamp - oldData.timestamp), (location.y - oldData.location.y) / (timestamp - oldData.timestamp));
    newData.velocity = velocity;
    newData.location = location;
    newData.timestamp = timestamp;

    objc_setAssociatedObject(self, @selector(RA_velocityData), [NSValue valueWithBytes:&newData objCType:@encode(VelocityData)], OBJC_ASSOCIATION_RETAIN);
}

%new
- (CGPoint)RA_velocity 
{
    VelocityData data;
    [objc_getAssociatedObject(self, @selector(RA_velocityData)) getValue:&data];

    return data.velocity;
}
%end

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

-(void) extractHandMotionForActiveTouches:(SBActiveTouch*) activeTouches count:(NSUInteger)count centroid:(CGPoint)centroid 
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
                _UIScreenEdgePanRecognizer *targetRecognizer = nil;

                for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers)
                {
                    [recognizer incorporateTouchSampleAtLocation:touch.unrotatedLocation timestamp:CACurrentMediaTime() modifier:touch.modifier interfaceOrientation:touch.interfaceOrientation];

                    if (recognizer.targetEdges & currentEdge)
                        targetRecognizer = recognizer;
                }
                [RAGestureManager.sharedInstance handleMovementOrStateUpdate:UIGestureRecognizerStateChanged withPoint:touch.location velocity:targetRecognizer.RA_velocity forEdge:currentEdge];
            }
        }
    });
}

%new -(void) screenEdgePanRecognizerStateDidChange:(_UIScreenEdgePanRecognizer*) screenEdgePanRecognizer 
{
    if (screenEdgePanRecognizer.state == 1)
    {
        CGPoint location = MSHookIvar<CGPoint>(screenEdgePanRecognizer, "_lastTouchLocation");

        // Adjust for the two unsupported orientations... what...
        if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeLeft && (location.x != 0 && location.y != 0))
        {
            location.x = UIScreen.mainScreen.bounds.size.width - location.x;
        }
        else if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown && (location.x != 0 && location.y != 0))
        {
            location.x = UIScreen.mainScreen.bounds.size.width - location.x;
        }
        else if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeRight)
        {
            CGFloat t = location.y;
            location.y = location.x;
            location.x = t;
        }

        if (shouldBeOverridingForRecognizer == NO)
            shouldBeOverridingForRecognizer = [RAGestureManager.sharedInstance canHandleMovementWithPoint:location velocity:screenEdgePanRecognizer.RA_velocity forEdge:screenEdgePanRecognizer.targetEdges];

        if (shouldBeOverridingForRecognizer) 
        {
            if ([RAGestureManager.sharedInstance handleMovementOrStateUpdate:UIGestureRecognizerStateBegan withPoint:location velocity:screenEdgePanRecognizer.RA_velocity forEdge:screenEdgePanRecognizer.targetEdges])
            {
                currentEdge = screenEdgePanRecognizer.targetEdges;
                BKSHIDServicesCancelTouchesOnMainDisplay(); // This is needed or open apps, etc will still get touch events. For example open settings app + swipeover without this line and you can still scroll up/down through the settings
            }
        }
    }
}

-(void) clear {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (isTracking) // Ended
        {
            _UIScreenEdgePanRecognizer *targetRecognizer = nil;
            for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers)
            {
                if (recognizer.targetEdges & currentEdge)
                    targetRecognizer = recognizer;
            }

            [RAGestureManager.sharedInstance handleMovementOrStateUpdate:UIGestureRecognizerStateEnded withPoint:CGPointZero velocity:targetRecognizer.RA_velocity forEdge:currentEdge];
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
    IF_SPRINGBOARD
    {
        class_addProtocol(objc_getClass("SBHandMotionExtractor"), @protocol(_UIScreenEdgePanRecognizerDelegate));
        
        UIRectEdge edgesToWatch[] = { UIRectEdgeBottom, UIRectEdgeLeft, UIRectEdgeRight, UIRectEdgeTop };
        int edgeCount = sizeof(edgesToWatch) / sizeof(UIRectEdge);
        gestureRecognizers = [[NSMutableSet alloc] initWithCapacity:edgeCount];
        for (int i = 0; i < edgeCount; i++) 
        {
            _UIScreenEdgePanRecognizer *recognizer = [[_UIScreenEdgePanRecognizer alloc] initWithType:2];
            recognizer.targetEdges = edgesToWatch[i];
            recognizer.screenBounds = UIScreen.mainScreen.bounds;
            [gestureRecognizers addObject:recognizer];
        }

        %init;
    }
}