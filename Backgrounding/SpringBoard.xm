#import "headers.h"
#import "RABackgrounder.h"
#include <execinfo.h>
#include <stdio.h>
#include <stdlib.h>

%hook SBApplication
-(BOOL) shouldAutoRelaunchAfterExit
{
    return [RABackgrounder.sharedInstance shouldAutoRelaunchApplication:self.bundleIdentifier] || %orig;
}

-(BOOL) shouldAutoLaunchOnBootOrInstall
{
    return [RABackgrounder.sharedInstance shouldAutoLaunchApplication:self.bundleIdentifier] || %orig;
}

-(BOOL) _shouldAutoLaunchOnBootOrInstall:(BOOL)arg1
{
    return [RABackgrounder.sharedInstance shouldAutoLaunchApplication:self.bundleIdentifier] || %orig;
}
%end

// STAY IN "FOREGROUND"
%hook FBUIApplicationResignActiveManager
-(void) _sendResignActiveForReason:(int)arg1 toProcess:(__unsafe_unretained FBApplicationProcess*)arg2
{
    if ([RABackgrounder.sharedInstance shouldSuspendImmediately:arg2.bundleIdentifier])
    {
        BKSProcess *bkProcess = MSHookIvar<BKSProcess*>(arg2, "_bksProcess");
        //[bkProcess _handleExpirationWarning:nil];
        [arg2 processWillExpire:bkProcess];
    }
    
    if ([RABackgrounder.sharedInstance shouldKeepInForeground:arg2.bundleIdentifier])
        return;

    %orig;
}
%end

%hook FBSSceneImpl
- (id)_initWithQueue:(unsafe_id)arg1 callOutQueue:(unsafe_id)arg2 identifier:(unsafe_id)arg3 display:(unsafe_id)arg4 settings:(__unsafe_unretained UIMutableApplicationSceneSettings*)arg5 clientSettings:(unsafe_id)arg6
{
    if ([RABackgrounder.sharedInstance shouldKeepInForeground:arg3])
    {
        // what?
        if (!arg5)
        {
            UIMutableApplicationSceneSettings *fakeSettings = [[%c(UIMutableApplicationSceneSettings) alloc] init];
            arg5 = fakeSettings;
        }
        SET_BACKGROUNDED(arg5, NO);
    }
    return %orig(arg1, arg2, arg3, arg4, arg5, arg6);
}
%end

%hook FBUIApplicationWorkspaceScene
-(void) host:(__unsafe_unretained FBScene*)arg1 didUpdateSettings:(__unsafe_unretained FBSSceneSettings*)arg2 withDiff:(unsafe_id)arg3 transitionContext:(unsafe_id)arg4 completion:(unsafe_id)arg5
{
    [RABackgrounder.sharedInstance removeTemporaryOverrideForIdentifier:arg1.identifier]; 
    if (arg1 && arg1.identifier && arg2 && arg1.clientProcess) // TODO: sanity check to prevent NC App crash. untested/not working.
    {
        if ([RABackgrounder.sharedInstance killProcessOnExit:arg1.identifier] && arg2.backgrounded == YES)
        {
            FBProcess *proc = arg1.clientProcess;

            if ([proc isKindOfClass:[%c(FBApplicationProcess) class]])
            {
                FBApplicationProcess *proc2 = (FBApplicationProcess*)proc;
                [proc2 killForReason:1 andReport:NO withDescription:@"ReachApp.Backgrounder.killOnExit" completion:nil];
                [RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:arg1.identifier withInfo:RAIconIndicatorViewInfoForceDeath];
                if ([RABackgrounder.sharedInstance shouldRemoveFromSwitcherWhenKilledOnExit:arg1.identifier])
                {
                    SBDisplayItem *item = [%c(SBDisplayItem) displayItemWithType:@"App" displayIdentifier:arg1.identifier];
                    [[%c(SBAppSwitcherModel) sharedInstance] removeDisplayItem:item];
                }
            }
            [RABackgrounder.sharedInstance queueRemoveTemporaryOverrideForIdentifier:arg1.identifier]; 
        }

        if ([RABackgrounder.sharedInstance shouldKeepInForeground:arg1.identifier] && arg2.backgrounded == YES)
        {
            [RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:arg1.identifier withInfo:[RABackgrounder.sharedInstance allAggregatedIndicatorInfoForIdentifier:arg1.identifier]];
            [RABackgrounder.sharedInstance queueRemoveTemporaryOverrideForIdentifier:arg1.identifier]; 
            return;
        }
        else if ([RABackgrounder.sharedInstance backgroundModeForIdentifier:arg1.identifier] == RABackgroundModeNative && arg2.backgrounded)
        {
            [RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:arg1.identifier withInfo:[RABackgrounder.sharedInstance allAggregatedIndicatorInfoForIdentifier:arg1.identifier]];
            [RABackgrounder.sharedInstance queueRemoveTemporaryOverrideForIdentifier:arg1.identifier]; 
        }
        else if ([RABackgrounder.sharedInstance shouldSuspendImmediately:arg1.identifier] && arg2.backgrounded)
        {
            [RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:arg1.identifier withInfo:[RABackgrounder.sharedInstance allAggregatedIndicatorInfoForIdentifier:arg1.identifier]];
            [RABackgrounder.sharedInstance queueRemoveTemporaryOverrideForIdentifier:arg1.identifier]; 
        }
        else if ([RABackgrounder.sharedInstance shouldSuspendImmediately:arg1.identifier] && arg2.backgrounded == NO)
        {
            [RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:arg1.identifier withInfo:[RABackgrounder.sharedInstance allAggregatedIndicatorInfoForIdentifier:arg1.identifier]];
        }
    }

    %orig(arg1, arg2, arg3, arg4, arg5);
}
%end

// PREVENT KILLING
%hook FBApplicationProcess
- (void)killForReason:(int)arg1 andReport:(BOOL)arg2 withDescription:(unsafe_id)arg3 completion:(unsafe_id/*block*/)arg4
{
    if ([RABackgrounder.sharedInstance preventKillingOfIdentifier:self.bundleIdentifier])
    {
        [RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:[RABackgrounder.sharedInstance allAggregatedIndicatorInfoForIdentifier:self.bundleIdentifier]];
        return;
    }
    %orig;
}
%end

%hook SBUIController
-(void) _noteAppDidActivate:(SBApplication*)application
{
    [application clearDeactivationSettings];
    %orig;
}
%end
