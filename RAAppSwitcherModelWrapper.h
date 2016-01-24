#import "headers.h"

@interface RAAppSwitcherModelWrapper : NSObject
+(void) addToFront:(SBApplication*)app;
+(void) addIdentifierToFront:(NSString*)ident;
+(NSArray*) appSwitcherAppIdentiferList;

+(void) removeItemWithIdentifier:(NSString*)ident;
@end