#import "RAGestureManager.h"

@interface RAGestureCallback : NSObject

@property (nonatomic, copy) RAGestureCallbackBlock callbackBlock;
@property (nonatomic, copy) RAGestureConditionBlock conditionBlock;
// OR
@property (nonatomic, strong) NSObject<RAGestureCallbackProtocol> *target;

@property (nonatomic) UIRectEdge screenEdge;
@property (nonatomic) NSUInteger priority;
@property (nonatomic, retain) NSString *identifier;

@end