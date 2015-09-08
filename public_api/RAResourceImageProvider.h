#import <UIKit/UIKit.h>

@interface RAResourceImageProvider : NSObject
+(UIImage*) imageForFilename:(NSString*)filename;
+(UIImage*) imageForFilename:(NSString*)filename size:(CGSize)size tintedTo:(UIColor*)tint;
+(UIImage*) imageForFilename:(NSString*)filename constrainedToSize:(CGSize)size;
@end