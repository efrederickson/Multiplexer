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
- (BOOL)supportsBackgroundMode:(__unsafe_unretained NSString *)mode
{
	int override = [RABackgrounder.sharedInstance application:self.bundleIdentifier overrideBackgroundMode:mode];
    if (override == -1)
        return %orig;
	return override;
}
%end

%hook BKSProcessAssertion
- (id)initWithPID:(int)arg1 flags:(unsigned int)arg2 reason:(unsigned int)arg3 name:(unsafe_id)arg4 withHandler:(unsafe_id)arg5
{
    if ((arg3 == kProcessAssertionReasonViewServices) == NO && // whitelist this to allow share menu to work
        [arg4 isEqualToString:@"Called by iOS6_iCleaner, from unknown method"] == NO && // whitelist iCleaner to prevent crash on open
        [arg4 isEqualToString:@"Called by Filza_main, from -[AppDelegate applicationDidEnterBackground:]"] == NO && // Whitelist filza to prevent iOS hang (?!)
        [NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.springboard"] == NO) // FIXME: this is a hack that prevents SpringBoard from not starting
    {
        NSString *identifier = NSBundle.mainBundle.bundleIdentifier;
        
        //NSLog(@"[ReachApp] BKSProcessAssertion initWithPID:'%d' flags:'%d' reason:'%d' name:'%@' withHandler:'%@' process identifier:'%@'", arg1, arg2, arg3, arg4, arg5, identifier);

        if ([RABackgrounder.sharedInstance shouldSuspendImmediately:identifier])
        {
            if ((arg3 >= kProcessAssertionReasonAudio && arg3 <= kProcessAssertionReasonVOiP)) // In most cases arg3 == 4 (finish task)
            {
                //NSLog(@"[ReachApp] blocking BKSProcessAssertion");

                //if (arg5)
                //{
                    //void (^arg5fix)() = arg5;
                    //arg5fix();
                    // ^^ causes crashes with share menu
                //}
                return nil;
            }
            //else if (arg3 == kProcessAssertionReasonActivation)
            //{
            //    arg2 = ProcessAssertionFlagAllowIdleSleep;
            //}
        }
    }
    return %orig(arg1, arg2, arg3, arg4, arg5);
}
%end
