#import "headers.h"

// iPad only.

@interface RAFakePhoneMode : NSObject

// Hook this to change the faked size when using Phone Mode.
+(CGSize) fakedSize;

// Whether this process is currently forcing "phone mode" or not.
+(BOOL) shouldFakeForThisProcess;

// Use in SpringBoard. Checks whether or not a certain application should be forcing phone mode. Also available by checking RAMessagingServer.
+(BOOL) shouldFakeForAppWithIdentifier:(NSString*)identifier;

// Use in SpringBoard. if you hook +[RAFakePhoneMode fakedSize], hook this too.
+(CGSize) fakeSizeForAppWithIdentifier:(NSString*)identifier;
@end