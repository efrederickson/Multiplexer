 #import "headers.h"

@class RAGestureCallback;

typedef enum {
	RAGestureCallbackResultSuccessAndContinue,
	RAGestureCallbackResultFailure,
	RAGestureCallbackResultSuccessAndStop,

	RAGestureCallbackResultSuccess = RAGestureCallbackResultSuccessAndContinue,
} RAGestureCallbackResult;

@protocol RAGestureCallbackProtocol
-(BOOL) RAGestureCallback_canHandle:(CGPoint)point;
-(RAGestureCallbackResult) RAGestureCallback_handle:(UIGestureRecognizerState)state withPoint:(CGPoint)location forEdge:(UIRectEdge)edge;
@end

typedef BOOL(^RAGestureConditionBlock)(CGPoint location);
typedef RAGestureCallbackResult(^RAGestureCallbackBlock)(UIGestureRecognizerState state, CGPoint location);

const NSUInteger RAGesturePriorityLow = 0;
const NSUInteger RAGesturePriorityHigh = 10;
const NSUInteger RAGesturePriorityDefault = RAGesturePriorityLow;

@interface RAGestureManager : NSObject {
	NSMutableArray *gestures;
	NSMutableDictionary *ignoredAreas;
}
+(id) sharedInstance;

-(void) addGestureRecognizer:(RAGestureCallbackBlock)callbackBlock withCondition:(RAGestureConditionBlock)conditionBlock forEdge:(UIRectEdge)screenEdge identifier:(NSString*)identifier priority:(NSUInteger)priority;
-(void) addGestureRecognizer:(RAGestureCallbackBlock)callbackBlock withCondition:(RAGestureConditionBlock)conditionBlock forEdge:(UIRectEdge)screenEdge identifier:(NSString*)identifier;
-(void) addGestureRecognizerWithTarget:(NSObject<RAGestureCallbackProtocol>*)target forEdge:(UIRectEdge)screenEdge identifier:(NSString*)identifier;
-(void) addGestureRecognizerWithTarget:(NSObject<RAGestureCallbackProtocol>*)target forEdge:(UIRectEdge)screenEdge identifier:(NSString*)identifier priority:(NSUInteger)priority;
-(void) addGesture:(RAGestureCallback*)callback;
-(void) removeGestureWithIdentifier:(NSString*)identifier;

-(BOOL) canHandleMovementWithPoint:(CGPoint)point forEdge:(UIRectEdge)edge;
-(BOOL) handleMovementOrStateUpdate:(UIGestureRecognizerState)state withPoint:(CGPoint)point forEdge:(UIRectEdge)edge;

-(void) ignoreSwipesBeginningInRect:(CGRect)area forIdentifier:(NSString*)identifier;
-(void) stopIgnoringSwipesForIdentifier:(NSString*)identifier;
-(void) ignoreSwipesBeginningOnSide:(UIRectEdge)side aboveYAxis:(NSUInteger)axis forIdentifier:(NSString*)identifier;
-(void) ignoreSwipesBeginningOnSide:(UIRectEdge)side belowYAxis:(NSUInteger)axis forIdentifier:(NSString*)identifier;
@end