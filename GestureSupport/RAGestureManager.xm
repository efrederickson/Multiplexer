#import "headers.h"
#import "RAGestureManager.h"
#import "RASwipeOverManager.h"
#import "RAGestureCallback.h"

@implementation RAGestureManager
+(id) sharedInstance
{
	SHARED_INSTANCE2(RAGestureManager, 
		sharedInstance->gestures = [NSMutableArray array]; 
		sharedInstance->ignoredAreas = [NSMutableDictionary dictionary];
	);
}

-(void) sortGestureRecognizers
{
	[gestures sortUsingComparator:^NSComparisonResult(RAGestureCallback *a, RAGestureCallback *b) {
		if (a.priority > b.priority)
			return NSOrderedAscending;
		else if (a.priority < b.priority)
			return NSOrderedDescending;
		return NSOrderedSame;
	}];
}

-(void) addGestureRecognizer:(RAGestureCallbackBlock)callbackBlock withCondition:(RAGestureConditionBlock)conditionBlock forEdge:(UIRectEdge)screenEdge identifier:(NSString*)identifier
{
	[self addGestureRecognizer:callbackBlock withCondition:conditionBlock forEdge:screenEdge identifier:identifier priority:RAGesturePriorityDefault];
}

-(void) addGesture:(RAGestureCallback*)callback
{
	[gestures addObject:callback];
	[self sortGestureRecognizers];
}

-(void) addGestureRecognizer:(RAGestureCallbackBlock)callbackBlock withCondition:(RAGestureConditionBlock)conditionBlock forEdge:(UIRectEdge)screenEdge identifier:(NSString*)identifier priority:(NSUInteger)priority
{
	RAGestureCallback *callback = [[RAGestureCallback alloc] init];
	callback.callbackBlock = [callbackBlock copy];
	callback.conditionBlock = [conditionBlock copy];
	callback.screenEdge = screenEdge;
	callback.identifier = identifier;
	callback.priority = priority;

	[self addGesture:callback];
}

-(void) addGestureRecognizerWithTarget:(NSObject<RAGestureCallbackProtocol>*)target forEdge:(UIRectEdge)screenEdge identifier:(NSString*)identifier
{
	[self addGestureRecognizerWithTarget:target forEdge:screenEdge identifier:identifier priority:RAGesturePriorityDefault];
}

-(void) addGestureRecognizerWithTarget:(NSObject<RAGestureCallbackProtocol>*)target forEdge:(UIRectEdge)screenEdge identifier:(NSString*)identifier priority:(NSUInteger)priority
{
	RAGestureCallback *callback = [[RAGestureCallback alloc] init];
	callback.target = target;
	callback.screenEdge = screenEdge;
	callback.identifier = identifier;
	callback.priority = priority;

	[self addGesture:callback];
}

-(void) removeGestureWithIdentifier:(NSString*)identifier
{
	for (int i = 0; i < gestures.count; i++)
	{
		RAGestureCallback *callback = [self callbackAtIndex:i];
		if ([callback.identifier isEqual:identifier])
		{
			[gestures removeObjectAtIndex:i];
			i--; // offset for the change
		}
	}
}

-(RAGestureCallback*) callbackAtIndex:(NSUInteger)index
{
	RAGestureCallback *ret = gestures[index];
	//[gestures[index] getValue:&ret];
	return ret;
}

-(BOOL) canHandleMovementWithPoint:(CGPoint)point forEdge:(UIRectEdge)edge
{
	for (int i = 0; i < gestures.count; i++)
	{
		RAGestureCallback *callback = [self callbackAtIndex:i];
		if (callback.screenEdge == edge)
		{
			if (callback.conditionBlock)
			{
				if (callback.conditionBlock(point))
					return YES;
			}
			else if (callback.target && [callback.target respondsToSelector:@selector(RAGestureCallback_canHandle:)])
				if ([callback.target RAGestureCallback_canHandle:point])
					return YES;
		}
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
		RAGestureCallback *callback = [self callbackAtIndex:i];
		if (callback.screenEdge == edge)
		{
			if (callback.callbackBlock)
			{
				RAGestureCallbackResult result = callback.callbackBlock(state, point);
				ret = YES;
				if (result == RAGestureCallbackResultSuccessAndStop)
					break;
			}
			else if (callback.target && [callback.target respondsToSelector:@selector(RAGestureCallback_handle:withPoint:forEdge:)])
			{
				RAGestureCallbackResult result = [callback.target RAGestureCallback_handle:state withPoint:point forEdge:edge];
				ret = YES;
				if (result == RAGestureCallbackResultSuccessAndStop)
					break;
			}
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
