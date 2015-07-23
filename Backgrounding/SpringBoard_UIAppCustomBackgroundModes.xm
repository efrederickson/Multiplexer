#import "headers.h"
#import "RABackgrounder.h"

@interface FBApplicationInfo
@property (nonatomic, copy) NSString *bundleIdentifier;
@end

%hook FBApplicationInfo
- (BOOL)supportsBackgroundMode:(NSString *)mode
{
	BOOL override = [RABackgrounder.sharedInstance application:self.bundleIdentifier overrideBackgroundMode:mode];
	return override ?: %orig;
}
%end