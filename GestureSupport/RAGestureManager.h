 #import "headers.h"

typedef BOOL(^RAGestureConditionBlock)(CGPoint location);
typedef void(^RAGestureCallbackBlock)(UIGestureRecognizerState state, CGPoint location);

typedef struct {
	RAGestureCallbackBlock callback;
	RAGestureConditionBlock conditionBlock;
	UIRectEdge screenEdge;
} RAGestureCallback;

@interface RAGestureManager : NSObject {
	NSMutableArray *gestures;
	NSMutableDictionary *ignoredAreas;
}
+(id) sharedInstance;

-(void) addGestureRecognizer:(RAGestureCallbackBlock)callbackBlock withCondition:(RAGestureConditionBlock)conditionBlock forEdge:(UIRectEdge)screenEdge;
-(void) addGesture:(RAGestureCallback)callback;

-(BOOL) canHandleMovementWithPoint:(CGPoint)point forEdge:(UIRectEdge)edge;
-(BOOL) handleMovementOrStateUpdate:(UIGestureRecognizerState)state withPoint:(CGPoint)point forEdge:(UIRectEdge)edge;

-(void) ignoreSwipesBeginningInRect:(CGRect)area forIdentifier:(NSString*)identifier;
-(void) stopIgnoringSwipesForIdentifier:(NSString*)identifier;
-(void) ignoreSwipesBeginningOnSide:(UIRectEdge)side aboveYAxis:(NSUInteger)axis forIdentifier:(NSString*)identifier;
-(void) ignoreSwipesBeginningOnSide:(UIRectEdge)side belowYAxis:(NSUInteger)axis forIdentifier:(NSString*)identifier;
@end