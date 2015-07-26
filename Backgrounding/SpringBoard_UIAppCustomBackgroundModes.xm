#import "headers.h"
#import "RABackgrounder.h"
#include <execinfo.h>
#include <stdio.h>
#include <stdlib.h>

@interface FBApplicationInfo : NSObject
@property (nonatomic, copy) NSString *bundleIdentifier;
-(BOOL) isExitsOnSuspend;
@end

%hook FBApplicationInfo
- (BOOL)supportsBackgroundMode:(NSString *)mode
{
	BOOL override = [RABackgrounder.sharedInstance application:self.bundleIdentifier overrideBackgroundMode:mode];
	return override ?: %orig;
}
%end

%hook BKSProcessAssertion
- (id)initWithPID:(int)arg1 flags:(unsigned int)arg2 reason:(unsigned int)arg3 name:(unsafe_id)arg4 withHandler:(unsafe_id)arg5
{
    if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.springboard"] == NO) // TODO: this is a hack that prevents SpringBoard from not starting
    {
        NSLog(@"[ReachApp] BKSProcessAssertion initWithPID:%d flags:%d reason:%d name:%@ withHandler:%@", arg1, arg2, arg3, arg4, arg5);

        NSString *identifier = objc_getClass("SBApplicationController") == nil ? NSBundle.mainBundle.bundleIdentifier : [[%c(SBApplicationController) sharedInstance] applicationWithPid:arg1].bundleIdentifier;
        if ([RABackgrounder.sharedInstance shouldSuspendImmediately:identifier])
        {
            if (arg3 >= kProcessAssertionReasonAudio && arg3 <= kProcessAssertionReasonVOiP) // In most cases arg3 == 4 (finish task)
            {
                //NSLog(@"[ReachApp] blocking BKSProcessAssertion");
                return nil;
            }
        }
    }
    return %orig(arg1, arg2, arg3, arg4, arg5);
}
%end