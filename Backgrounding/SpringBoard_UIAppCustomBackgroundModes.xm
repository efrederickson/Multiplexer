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
	BOOL override = [RABackgrounder.sharedInstance application:self.bundleIdentifier overrideBackgroundMode:mode];
	return override ?: %orig;
}
%end

//BOOL enableSBApp = NO;

%hook BKSProcessAssertion
- (id)initWithPID:(int)arg1 flags:(unsigned int)arg2 reason:(unsigned int)arg3 name:(unsafe_id)arg4 withHandler:(unsafe_id)arg5
{
    if ([arg4 isEqualToString:@"com.apple.viewservice.session"] == NO && // whitelist this to allow share menu to work
        [arg4 isEqualToString:@"Called by iOS6_iCleaner, from unknown method"] == NO &&
        [NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.springboard"] == NO) // TODO: this is a hack that prevents SpringBoard from not starting
    {
        NSString *identifier = /*enableSBApp == NO || */objc_getClass("SBApplicationController") == nil ? NSBundle.mainBundle.bundleIdentifier : [[%c(SBApplicationController) sharedInstance] applicationWithPid:arg1].bundleIdentifier;
        
        NSLog(@"[ReachApp] BKSProcessAssertion initWithPID:'%d' flags:'%d' reason:'%d' name:'%@' withHandler:'%@' process identifier:'%@'", arg1, arg2, arg3, arg4, arg5, identifier);

        if ([RABackgrounder.sharedInstance shouldSuspendImmediately:identifier])
        {
            //NSLog(@"[ReachApp] shouldSuspendImmediately: %@", identifier);
            if ((arg3 >= kProcessAssertionReasonAudio && arg3 <= kProcessAssertionReasonVOiP)) // In most cases arg3 == 4 (finish task)
            {
                NSLog(@"[ReachApp] blocking BKSProcessAssertion");
                arg2 = ProcessAssertionFlagAllowIdleSleep;
                arg3 = kProcessAssertionReasonSuspend;
                if (arg5)
                {
                    //void (^arg5fix)() = arg5;
                    //arg5fix();
                    // ^^ causes crashes with share menu
                }
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

/*
%hook SBLockStateAggregator
-(void) _updateLockState
{
    %orig;
    
    if (![self hasAnyLockState])
        enableSBApp = YES;
}
%end
*/