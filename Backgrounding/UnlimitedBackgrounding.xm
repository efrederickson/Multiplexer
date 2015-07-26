#import "headers.h"
#import "RABackgrounder.h"

extern const char *__progname;

NSMutableDictionary *processAssertions = [NSMutableDictionary dictionary];

BKSProcessAssertion *keepAlive$temp;

%hook FBUIApplicationWorkspaceScene
// ah, the old arc-causes-eventual-memory-crashes-because-we-accidentally-retained-objects-in-hooked-functions issue... 
-(void) host:(__unsafe_unretained FBScene*)arg1 didUpdateSettings:(__unsafe_unretained FBSSceneSettings*)arg2 withDiff:(unsafe_id)arg3 transitionContext:(unsafe_id)arg4 completion:(unsafe_id)arg5
{
    if ([RABackgrounder.sharedInstance hasUnlimitedBackgroundTime:arg1.identifier] && arg2.backgrounded == YES && [processAssertions objectForKey:arg1.identifier] == nil)
    {
    	SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:arg1.identifier];

		keepAlive$temp = [[%c(BKSProcessAssertion) alloc] initWithPID:[app pid]
			flags:(ProcessAssertionFlagPreventSuspend | ProcessAssertionFlagAllowIdleSleep | ProcessAssertionFlagPreventThrottleDownCPU | ProcessAssertionFlagWantsForegroundResourcePriority)
            reason:kProcessAssertionReasonBackgroundUI
            name:@"reachapp"
			withHandler:^{
				NSLog(@"ReachApp: %d kept alive: %@", [app pid], [keepAlive$temp valid] ? @"TRUE" : @"FALSE");
				if (keepAlive$temp.valid)
					processAssertions[arg1.identifier] = keepAlive$temp;
			}];
    }
    %orig(arg1, arg2, arg3, arg4, arg5);
}
%end

%hook FBApplicationProcess
- (void)killForReason:(int)arg1 andReport:(BOOL)arg2 withDescription:(unsafe_id)arg3 completion:(unsafe_id/*block*/)arg4
{
    if ([RABackgrounder.sharedInstance preventKillingOfIdentifier:self.bundleIdentifier] == NO && [processAssertions objectForKey:self.bundleIdentifier])
    {
    	[processAssertions[self.bundleIdentifier] invalidate];
    	[processAssertions removeObjectForKey:self.bundleIdentifier];
    }
    %orig;
}
%end

static int (*orig_BSAuditTokenTaskHasEntitlement)(id connection, NSString *entitlement);
static int hax_BSAuditTokenTaskHasEntitlement(unsafe_id connection, __unsafe_unretained NSString *entitlement) 
{
    if ([entitlement isEqualToString:@"com.apple.multitasking.unlimitedassertions"])
    {
        return true;
    }

    return orig_BSAuditTokenTaskHasEntitlement(connection, entitlement);
}

%ctor
{
	if (strcmp(__progname, "assertiond") == 0) 
	{
        dlopen("/System/Library/PrivateFrameworks/XPCObjects.framework/XPCObjects", RTLD_LAZY);
        void *xpcFunction = MSFindSymbol(NULL, "_BSAuditTokenTaskHasEntitlement");
        MSHookFunction(xpcFunction, (void *)hax_BSAuditTokenTaskHasEntitlement, (void **)&orig_BSAuditTokenTaskHasEntitlement);
    }
}