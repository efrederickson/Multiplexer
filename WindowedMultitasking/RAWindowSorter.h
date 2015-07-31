#import "RADesktopWindow.h"

@interface RAWindowSorter : NSObject
+(void) sortWindowsOnDesktop:(RADesktopWindow*)desktop resizeIfNecessary:(BOOL)resize;
@end