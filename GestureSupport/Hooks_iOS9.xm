#import "headers.h"
#import "RAGestureManager.h"

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>
#include <IOKit/hid/IOHIDEventSystem.h>
#include <IOKit/hid/IOHIDEventSystemClient.h>
#include <stdio.h>
#include <dlfcn.h>

int IOHIDEventSystemClientSetMatching(IOHIDEventSystemClientRef client, CFDictionaryRef match);
CFArrayRef IOHIDEventSystemClientCopyServices(IOHIDEventSystemClientRef, int);
typedef struct __IOHIDServiceClient * IOHIDServiceClientRef;
int IOHIDServiceClientSetProperty(IOHIDServiceClientRef, CFStringRef, CFNumberRef);
typedef void* (*clientCreatePointer)(const CFAllocatorRef);
extern "C" void BKSHIDServicesCancelTouchesOnMainDisplay();

@interface _UIScreenEdgePanRecognizer (Velocity)
-(CGPoint) RA_velocity;
@end

static BOOL isTracking = NO;
static NSMutableSet *gestureRecognizers;
UIRectEdge currentEdge9;

struct VelocityData {
    CGPoint velocity;
    double timestamp;
    CGPoint location;
};

%hook _UIScreenEdgePanRecognizer
- (void)incorporateTouchSampleAtLocation:(CGPoint)location timestamp:(double)timestamp modifier:(NSInteger)modifier interfaceOrientation:(UIInterfaceOrientation)orientation forceState:(int)arg5
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

@interface Hooks9$SBHandMotionExtractorReplacementByMultiplexer : NSObject

@end

@implementation Hooks9$SBHandMotionExtractorReplacementByMultiplexer
-(id) init 
{
    if (self = [super init])
    {
        for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers)
            [recognizer setDelegate:(id<_UIScreenEdgePanRecognizerDelegate>)self];
    }
    return self;
}

-(void) screenEdgePanRecognizerStateDidChange:(_UIScreenEdgePanRecognizer*) screenEdgePanRecognizer 
{
    if (screenEdgePanRecognizer.state == UIGestureRecognizerStateBegan)
    {
        CGPoint location = MSHookIvar<CGPoint>(screenEdgePanRecognizer, "_lastTouchLocation");

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
        NSLog(@"[ReachApp] _UIScreenEdgePanRecognizer location: %@", NSStringFromCGPoint(location));
        if ([RAGestureManager.sharedInstance handleMovementOrStateUpdate:UIGestureRecognizerStateBegan withPoint:location velocity:screenEdgePanRecognizer.RA_velocity forEdge:screenEdgePanRecognizer.targetEdges])
        {
            currentEdge9 = screenEdgePanRecognizer.targetEdges;
            BKSHIDServicesCancelTouchesOnMainDisplay(); // This is needed or open apps, etc will still get touch events. For example open settings app + swipeover without this line and you can still scroll up/down through the settings
        }
    }
}
@end

void touch_event(void *target, void *refcon, IOHIDServiceRef service, IOHIDEventRef event) 
{
    if (IOHIDEventGetType(event) == kIOHIDEventTypeDigitizer)
    {
        NSArray *children = (__bridge NSArray *)IOHIDEventGetChildren(event);
        if ([children count] == 1)
        {
            float density = IOHIDEventGetFloatValue((__bridge __IOHIDEvent *)children[0], (IOHIDEventField)kIOHIDEventFieldDigitizerDensity);

            float x = IOHIDEventGetFloatValue((__bridge __IOHIDEvent *)children[0], (IOHIDEventField)kIOHIDEventFieldDigitizerX) * UIScreen.mainScreen._referenceBounds.size.width;
            float y = IOHIDEventGetFloatValue((__bridge __IOHIDEvent *)children[0], (IOHIDEventField)kIOHIDEventFieldDigitizerY) * UIScreen.mainScreen._referenceBounds.size.height; 
            CGPoint location = (CGPoint) { x, y };

            UIInterfaceOrientation interfaceOrientation = GET_STATUSBAR_ORIENTATION;

            float rotatedX = x;
            float rotatedY = y;
            
            if (interfaceOrientation == UIInterfaceOrientationLandscapeRight)
            {
                rotatedX = y;
                rotatedY = UIScreen.mainScreen.bounds.size.height - x;
            }
            else if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft)
            {
                rotatedX = UIScreen.mainScreen._referenceBounds.size.height - y;
                rotatedY = x;
            }

            CGPoint rotatedLocation = (CGPoint) { rotatedX, rotatedY };

            NSLog(@"[ReachApp] (%f, %d) %@ -> %@", density, isTracking, NSStringFromCGPoint(location), NSStringFromCGPoint(rotatedLocation));

            if (isTracking == NO)
            {
                for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers)
                    [recognizer incorporateTouchSampleAtLocation:location timestamp:CACurrentMediaTime() modifier:1 interfaceOrientation:interfaceOrientation forceState:0];
                isTracking = YES;
            }
            else if (density == 0 && isTracking)
            {
                _UIScreenEdgePanRecognizer *targetRecognizer = nil;
                for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers)
                {
                    if (recognizer.targetEdges & currentEdge9)
                        targetRecognizer = recognizer;
                }

                [RAGestureManager.sharedInstance handleMovementOrStateUpdate:UIGestureRecognizerStateEnded withPoint:CGPointZero velocity:targetRecognizer.RA_velocity forEdge:currentEdge9];
                for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers)
                    [recognizer reset]; // remove current touches it's "incorporated"
                currentEdge9 = UIRectEdgeNone;
                isTracking = NO;

                NSLog(@"[ReachApp] touch ended.");
            }
            else
            {
                _UIScreenEdgePanRecognizer *targetRecognizer = nil;

                for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers)
                {
                    [recognizer incorporateTouchSampleAtLocation:location timestamp:CACurrentMediaTime() modifier:1 interfaceOrientation:interfaceOrientation forceState:0];

                    if (recognizer.targetEdges & currentEdge9)
                        targetRecognizer = recognizer;
                }
                [RAGestureManager.sharedInstance handleMovementOrStateUpdate:UIGestureRecognizerStateChanged withPoint:rotatedLocation velocity:targetRecognizer.RA_velocity forEdge:currentEdge9];
            }

        }
    }
}

__strong id __static$Hooks9$SBHandMotionExtractorReplacementByMultiplexer;

%ctor
{

    IF_SPRINGBOARD
    {
        if (SYSTEM_VERSION_LESS_THAN(@"9.0"))
            return;

        clientCreatePointer clientCreate;
        void *handle = dlopen(0, 9);
        *(void**)(&clientCreate) = dlsym(handle,"IOHIDEventSystemClientCreate");
        IOHIDEventSystemClientRef hidEventSystem = (__IOHIDEventSystemClient *)clientCreate(kCFAllocatorDefault);
        IOHIDEventSystemClientScheduleWithRunLoop(hidEventSystem, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        IOHIDEventSystemClientRegisterEventCallback(hidEventSystem, (IOHIDEventSystemClientEventCallback)touch_event, NULL, NULL);

        class_addProtocol(objc_getClass("Hooks9$SBHandMotionExtractorReplacementByMultiplexer"), @protocol(_UIScreenEdgePanRecognizerDelegate));
        
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

        __static$Hooks9$SBHandMotionExtractorReplacementByMultiplexer = [[Hooks9$SBHandMotionExtractorReplacementByMultiplexer alloc] init];
    }
    
}