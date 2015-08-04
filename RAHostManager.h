#import "headers.h"

@interface RAHostManager : NSObject
+(UIView*) systemHostViewForApplication:(SBApplication*)app;
+(UIView*) enabledHostViewForApplication:(SBApplication*)app;
+(NSObject*) hostManagerForApp:(SBApplication*)app;
@end