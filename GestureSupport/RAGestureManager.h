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
}
+(id) sharedInstance;

-(void) addGestureRecognizer:(RAGestureCallbackBlock)callbackBlock withCondition:(RAGestureConditionBlock)conditionBlock forEdge:(UIRectEdge)screenEdge;
-(void) addGesture:(RAGestureCallback)callback;

-(BOOL) canHandleMovementWithPoint:(CGPoint)point forEdge:(UIRectEdge)edge;
-(BOOL) handleMovementOrStateUpdate:(UIGestureRecognizerState)state withPoint:(CGPoint)point forEdge:(UIRectEdge)edge;
@end