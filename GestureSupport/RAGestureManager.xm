#import "headers.h"
#import "RAGestureManager.h"
#import "RASwipeOverManager.h"

@implementation RAGestureManager
+(id) sharedInstance
{
	SHARED_INSTANCE2(RAGestureManager, sharedInstance->gestures = [NSMutableArray array]);
}

-(void) addGestureRecognizer:(RAGestureCallbackBlock)callbackBlock withCondition:(RAGestureConditionBlock)conditionBlock forEdge:(UIRectEdge)screenEdge
{
	[self addGesture:(RAGestureCallback) {
		callbackBlock, 
		conditionBlock, 
		screenEdge
	}];
}

-(void) addGesture:(RAGestureCallback)callback
{
	[gestures addObject:[NSValue valueWithBytes:&callback objCType:@encode(RAGestureCallback)]];
}

-(RAGestureCallback) callbackAtIndex:(NSUInteger)index
{
	RAGestureCallback ret;
	[gestures[index] getValue:&ret];
	return ret;
}

-(BOOL) canHandleMovementWithPoint:(CGPoint)point forEdge:(UIRectEdge)edge
{
	for (int i = 0; i < gestures.count; i++)
	{
		RAGestureCallback callback = [self callbackAtIndex:i];
		if (callback.screenEdge == edge)
			if (callback.conditionBlock(point))
				return YES;
	}
	return NO;
}

-(BOOL) handleMovementOrStateUpdate:(UIGestureRecognizerState)state withPoint:(CGPoint)point forEdge:(UIRectEdge)edge
{
	BOOL ret = NO;
	for (int i = 0; i < gestures.count; i++)
	{
		RAGestureCallback callback = [self callbackAtIndex:i];
		if (callback.screenEdge == edge)
		{
			callback.callback(state, point);
			ret = YES;
		}
	}
	return ret;
}
@end
