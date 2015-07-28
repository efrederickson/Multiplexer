#import "headers.h"

@interface RAResourceImageProvider : NSObject
+(UIImage*) imageForFilename:(NSString*)filename;
+(UIImage*) imageForFilename:(NSString*)filename constrainedToSize:(CGSize)size;
@end