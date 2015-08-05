#import "headers.h"

@interface RAKeyboardStateListener : NSObject
+(instancetype) sharedInstance;
@property (nonatomic, readonly) BOOL visible;
@property (nonatomic, readonly) CGSize size;
@end

