#import "headers.h"
#import "RAGestureManager.h"
#import "RASwipeOverManager.h"

@implementation RAGestureManager
+(id) sharedInstance
{
	SHARED_INSTANCE2(RAGestureManager, 
		sharedInstance->gestures = [NSMutableArray array]; 
		sharedInstance->ignoredAreas = [NSMutableDictionary dictionary];
	);
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
	// If we don't do this check here, but in canHandleMovementWithPoint:forEdge:, the recognizer hooks will not begin tracking the swipe
	// This is an issue if someone calls stopIgnoringSwipesForIdentifier: while a swipe is going on. 
	for (NSValue *value in ignoredAreas.allValues)
	{
		CGRect rect = [value CGRectValue];
		if (CGRectContainsPoint(rect, point))
			return NO; // IGNORED
	}

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


-(void) ignoreSwipesBeginningInRect:(CGRect)area forIdentifier:(NSString*)identifier
{
	[ignoredAreas setObject:[NSValue valueWithCGRect:area] forKey:identifier];
}

-(void) stopIgnoringSwipesForIdentifier:(NSString*)identifier
{
	[ignoredAreas removeObjectForKey:identifier];
}

-(void) ignoreSwipesBeginningOnSide:(UIRectEdge)side aboveYAxis:(NSUInteger)axis forIdentifier:(NSString*)identifier
{
	if (side != UIRectEdgeLeft && side != UIRectEdgeRight)
		@throw [NSException exceptionWithName:@"InvalidRectEdgeException" reason:@"Expected UIRectEdgeLeft or UIRectEdgeRight" userInfo:nil];
	CGRect r = CGRectMake(side == UIRectEdgeLeft ? 0 : UIScreen.mainScreen.bounds.size.width / 2.0 , 0, UIScreen.mainScreen.bounds.size.width / 2.0, axis);
	[self ignoreSwipesBeginningInRect:r forIdentifier:identifier];
}

-(void) ignoreSwipesBeginningOnSide:(UIRectEdge)side belowYAxis:(NSUInteger)axis forIdentifier:(NSString*)identifier
{
	if (side != UIRectEdgeLeft && side != UIRectEdgeRight)
		@throw [NSException exceptionWithName:@"InvalidRectEdgeException" reason:@"Expected UIRectEdgeLeft or UIRectEdgeRight" userInfo:nil];
	CGRect r = CGRectMake(side == UIRectEdgeLeft ? 0 : UIScreen.mainScreen.bounds.size.width / 2.0 , axis, UIScreen.mainScreen.bounds.size.width / 2.0, UIScreen.mainScreen.bounds.size.height - axis);
	[self ignoreSwipesBeginningInRect:r forIdentifier:identifier];
}
@end
