#import "RABackgrounder.h"
#import "RASettings.h"

NSString *FriendlyNameForBackgroundMode(RABackgroundMode mode)
{
	switch (mode)
	{
		case RABackgroundModeNative:
			return LOCALIZE(@"NATIVE");
		case RABackgroundModeForcedForeground:
			return LOCALIZE(@"FORCE_FOREGROUND");
		case RABackgroundModeForceNone:
			return LOCALIZE(@"DISABLE");
		case RABackgroundModeSuspendImmediately:
			return LOCALIZE(@"SUSPEND_IMMEDIATELY");
		case RABackgroundModeUnlimitedBackgroundingTime:
			return LOCALIZE(@"UNLIMITED_BACKGROUNDING_TIME");
		default:
			return @"Unknown";
	}
}

NSMutableDictionary *temporaryOverrides = [NSMutableDictionary dictionary];
NSMutableDictionary *temporaryShouldPop = [NSMutableDictionary dictionary];

@implementation RABackgrounder
+(id) sharedInstance
{
	SHARED_INSTANCE(RABackgrounder);
}

-(BOOL) shouldAutoLaunchApplication:(NSString*)identifier
{
	if (!identifier || ![[%c(RASettings) sharedInstance] backgrounderEnabled]) return NO;
	
	NSDictionary *dict = [[%c(RASettings) sharedInstance] rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	return [[%c(RASettings) sharedInstance] backgrounderEnabled] && enabled && ([dict objectForKey:@"autoLaunch"] == nil ? NO : [dict[@"autoLaunch"] boolValue]);
}

-(BOOL) shouldAutoRelaunchApplication:(NSString*)identifier
{
	if (!identifier || ![[%c(RASettings) sharedInstance] backgrounderEnabled]) return NO;
	
	NSDictionary *dict = [[%c(RASettings) sharedInstance] rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	return [self killProcessOnExit:identifier] == NO && [[%c(RASettings) sharedInstance] backgrounderEnabled] && enabled && ([dict objectForKey:@"autoRelaunch"] == nil ? NO : [dict[@"autoRelaunch"] boolValue]);
}

-(NSInteger) popTemporaryOverrideForApplication:(NSString*)identifier
{
	if (![temporaryOverrides objectForKey:identifier])
		return -1;
	RABackgroundMode override = (RABackgroundMode)[temporaryOverrides[identifier] intValue];
	return override;
}

-(void) queueRemoveTemporaryOverrideForIdentifier:(NSString*)identifier
{
	temporaryShouldPop[identifier] = @YES;
}

-(void) removeTemporaryOverrideForIdentifier:(NSString*)identifier
{
	if ([temporaryShouldPop objectForKey:identifier] != nil && [[temporaryShouldPop objectForKey:identifier] boolValue])
	{
		[temporaryShouldPop removeObjectForKey:identifier];
		[temporaryOverrides removeObjectForKey:identifier];	
	}
}

-(NSInteger) popTemporaryOverrideForApplication:(NSString*)identifier is:(RABackgroundMode)mode
{
	NSInteger popped = [self popTemporaryOverrideForApplication:identifier];
	return popped == -1 ? -1 : (popped == mode ? 1 : 0);
}

-(RABackgroundMode) globalBackgroundMode
{
	return (RABackgroundMode)[(RASettings*)[%c(RASettings) sharedInstance] globalBackgroundMode];
}

-(BOOL) shouldKeepInForeground:(NSString*)identifier
{
	return [self backgroundModeForIdentifier:identifier] == RABackgroundModeForcedForeground;
}

-(BOOL) shouldSuspendImmediately:(NSString*)identifier
{
	return [self backgroundModeForIdentifier:identifier] == RABackgroundModeSuspendImmediately;
}

-(BOOL) preventKillingOfIdentifier:(NSString*)identifier
{
	if (!identifier || ![[%c(RASettings) sharedInstance] backgrounderEnabled]) return NO;
	
	NSDictionary *dict = [[%c(RASettings) sharedInstance] rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	return [[%c(RASettings) sharedInstance] backgrounderEnabled] && enabled && ([dict objectForKey:@"preventDeath"] == nil ? NO : [dict[@"preventDeath"] boolValue]);
}

-(BOOL) shouldRemoveFromSwitcherWhenKilledOnExit:(NSString*)identifier
{
	if (!identifier || ![[%c(RASettings) sharedInstance] backgrounderEnabled]) return NO;
	
	NSDictionary *dict = [[%c(RASettings) sharedInstance] rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"removeFromSwitcher"] ? [dict[@"removeFromSwitcher"] boolValue] : NO;
	return [[%c(RASettings) sharedInstance] backgrounderEnabled] && enabled && ([dict objectForKey:@"removeFromSwitcher"] == nil ? NO : [dict[@"removeFromSwitcher"] boolValue]);
}

-(NSInteger) backgroundModeForIdentifier:(NSString*)identifier
{
	@autoreleasepool {
		if (!identifier || [[%c(RASettings) sharedInstance] backgrounderEnabled] == NO)
			return RABackgroundModeNative;

		NSInteger temporaryOverride = [self popTemporaryOverrideForApplication:identifier];
		if (temporaryOverride != -1)
			return temporaryOverride;

#if __has_feature(objc_arc)
		__weak // dictionary is cached by RASettings anyway
#endif
		NSDictionary *dict = [[%c(RASettings) sharedInstance] rawCompiledBackgrounderSettingsForIdentifier:identifier];
		BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
		if (!enabled)
			return [self globalBackgroundMode];
		return [dict[@"backgroundMode"] intValue];
	}
}

-(BOOL) hasUnlimitedBackgroundTime:(NSString*)identifier
{
	return [self backgroundModeForIdentifier:identifier] == RABackgroundModeUnlimitedBackgroundingTime;
}

-(BOOL) killProcessOnExit:(NSString*)identifier
{
	return [self backgroundModeForIdentifier:identifier] == RABackgroundModeForceNone;
}

-(void) temporarilyApplyBackgroundingMode:(RABackgroundMode)mode forApplication:(SBApplication*)app andCloseForegroundApp:(BOOL)close
{
	temporaryOverrides[app.bundleIdentifier] = @(mode);

	if (close)
	{
        FBWorkspaceEvent *event = [objc_getClass("FBWorkspaceEvent") eventWithName:@"ActivateSpringBoard" handler:^{
            SBAppToAppWorkspaceTransaction *transaction = [[objc_getClass("SBAppExitedWorkspaceTransaction") alloc] initWithAlertManager:nil exitedApp:app];
            [transaction begin];
        }];
        [(FBWorkspaceEventQueue*)[objc_getClass("FBWorkspaceEventQueue") sharedInstance] executeOrAppendEvent:event];
	}
}

-(NSInteger) application:(NSString*)identifier overrideBackgroundMode:(NSString*)mode
{
	NSDictionary *dict = [[%c(RASettings) sharedInstance] rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	id val = dict[@"backgroundModes"][mode];
	return [[%c(RASettings) sharedInstance] backgrounderEnabled] && enabled ? (val ? [val boolValue] : -1) : -1;
}

-(RAIconIndicatorViewInfo) allAggregatedIndicatorInfoForIdentifier:(NSString*)identifier
{
	int info = RAIconIndicatorViewInfoNone;

	if ([self backgroundModeForIdentifier:identifier] == RABackgroundModeNative)
		info |= RAIconIndicatorViewInfoNative;
	else if ([self backgroundModeForIdentifier:identifier] == RABackgroundModeForcedForeground)
		info |= RAIconIndicatorViewInfoForced;
	else if ([self shouldSuspendImmediately:identifier])
		info |= RAIconIndicatorViewInfoSuspendImmediately;
	else if ([self hasUnlimitedBackgroundTime:identifier])
		info |= RAIconIndicatorViewInfoUnlimitedBackgroundTime;

	if ([self killProcessOnExit:identifier])
		info |= RAIconIndicatorViewInfoForceDeath;

	if ([self preventKillingOfIdentifier:identifier])
		info |= RAIconIndicatorViewInfoUnkillable;

	return (RAIconIndicatorViewInfo)info;
}

-(void) updateIconIndicatorForIdentifier:(NSString*)identifier withInfo:(RAIconIndicatorViewInfo)info
{
	@autoreleasepool {
		SBIconView *ret = nil;
	    if ([[[objc_getClass("SBIconViewMap") homescreenMap] iconModel] respondsToSelector:@selector(applicationIconForBundleIdentifier:)])
	    {
	        // iOS 8.0+

	        SBIcon *icon = [[[objc_getClass("SBIconViewMap") homescreenMap] iconModel] applicationIconForBundleIdentifier:identifier];
	        ret = [[objc_getClass("SBIconViewMap") homescreenMap] mappedIconViewForIcon:icon];
	    }
	    else
	    {
	        // iOS 7.X
	        SBIcon *icon = [[[objc_getClass("SBIconViewMap") homescreenMap] iconModel] applicationIconForDisplayIdentifier:identifier];
	        ret = [[objc_getClass("SBIconViewMap") homescreenMap] mappedIconViewForIcon:icon];
	    }

	    [ret RA_updateIndicatorView:info];
	}
}

-(BOOL) shouldShowIndicatorForIdentifier:(NSString*)identifier
{
	NSDictionary *dct = [[%c(RASettings) sharedInstance] rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL globalSetting = [[%c(RASettings) sharedInstance] shouldShowIconIndicatorsGlobally];
	return globalSetting ? ([dct objectForKey:@"showIndicatorOnIcon"] == nil ? YES : [dct[@"showIndicatorOnIcon"] boolValue]) : NO;
}

-(BOOL) shouldShowStatusBarIconForIdentifier:(NSString*)identifier
{
	NSDictionary *dct = [[%c(RASettings) sharedInstance] rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL globalSetting = [[%c(RASettings) sharedInstance] shouldShowStatusBarIcons];
	return globalSetting ? ([dct objectForKey:@"showStatusBarIcon"] == nil ? YES : [dct[@"showStatusBarIcon"] boolValue]) : NO;
}
@end