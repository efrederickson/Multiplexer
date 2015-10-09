#import "headers.h"
#import "RARunningAppsProvider.h"

@interface RAAppKiller : NSObject <RARunningAppsProviderDelegate>
+(void) killAppWithIdentifier:(NSString*)identifier;
+(void) killAppWithIdentifier:(NSString*)identifier completion:(void(^)())handler;
+(void) killAppWithSBApplication:(SBApplication*)app;
+(void) killAppWithSBApplication:(SBApplication*)app completion:(void(^)())handler;
@end

