#import "RABackgrounder.h"
#import "RASettings.h"

@interface SBIconView (ReachApp)
-(void) RA_updateIndicatorView:(RAIconIndicatorViewInfo)info;
@end

@implementation RABackgrounder
+(id) sharedInstance
{
	SHARED_INSTANCE(RABackgrounder);
}

-(BOOL) shouldAutoLaunchApplication:(NSString*)identifier
{
	if (!identifier || ![RASettings.sharedInstance backgrounderEnabled]) return NO;
	
	NSDictionary *dict = [RASettings.sharedInstance rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	return enabled && ([dict objectForKey:@"autoLaunch"] == nil ? NO : [dict[@"autoLaunch"] boolValue]);
}

-(BOOL) shouldAutoRelaunchApplication:(NSString*)identifier
{
	if (!identifier || ![RASettings.sharedInstance backgrounderEnabled]) return NO;
	
	NSDictionary *dict = [RASettings.sharedInstance rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	return enabled && ([dict objectForKey:@"autoRelaunch"] == nil ? NO : [dict[@"autoRelaunch"] boolValue]);
}

-(BOOL) shouldKeepInForeground:(NSString*)identifier
{
	if (!identifier || ![RASettings.sharedInstance backgrounderEnabled]) return NO;
	
	NSDictionary *dict = [RASettings.sharedInstance rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;

	return enabled && ([dict objectForKey:@"backgroundMode"] == nil ? NO : [dict[@"backgroundMode"] intValue] == RABackgroundModeForcedForeground);
}

-(BOOL) shouldSuspendImmediately:(NSString*)identifier
{
	if (!identifier || ![RASettings.sharedInstance backgrounderEnabled]) return NO;
	
	NSDictionary *dict = [RASettings.sharedInstance rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;

	return enabled && ([dict objectForKey:@"backgroundMode"] == nil ? NO : [dict[@"backgroundMode"] intValue] == RABackgroundModeSuspendImmediately);
}

-(BOOL) preventKillingOfIdentifier:(NSString*)identifier
{
	if (!identifier || ![RASettings.sharedInstance backgrounderEnabled]) return NO;
	
	NSDictionary *dict = [RASettings.sharedInstance rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	return enabled && ([dict objectForKey:@"preventDeath"] == nil ? NO : [dict[@"preventDeath"] boolValue]);
}

-(NSInteger) backgroundModeForIdentifier:(NSString*)identifier
{
	return [[RASettings.sharedInstance rawCompiledBackgrounderSettingsForIdentifier:identifier][@"backgroundMode"] intValue];
}

-(BOOL) hasUnlimitedBackgroundTime:(NSString*)identifier
{
	if (!identifier || ![RASettings.sharedInstance backgrounderEnabled]) return NO;
	
	NSDictionary *dict = [RASettings.sharedInstance rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	return enabled && ([dict objectForKey:@"unlimitedBackgrounding"] == nil ? NO : [dict[@"unlimitedBackgrounding"] boolValue]);
}

-(BOOL) killProcessOnExit:(NSString*)identifier
{
	if (!identifier || ![RASettings.sharedInstance backgrounderEnabled]) return NO;
	
	NSDictionary *dict = [RASettings.sharedInstance rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	return enabled && ([dict objectForKey:@"backgroundMode"] == nil ? NO : [dict[@"backgroundMode"] intValue] == RABackgroundModeForceNone);
}

-(BOOL) application:(NSString*)identifier overrideBackgroundMode:(NSString*)mode
{
	NSDictionary *dict = [RASettings.sharedInstance rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	id val = dict[@"backgroundModes"][mode];
	return enabled && [val boolValue];
}

-(RAIconIndicatorViewInfo) allAggregatedIndicatorInfoForIdentifier:(NSString*)identifier
{
	int info = RAIconIndicatorViewInfoNone;

	if ([self backgroundModeForIdentifier:identifier] == RABackgroundModeNative)
		info |= RAIconIndicatorViewInfoNative;

	if ([self backgroundModeForIdentifier:identifier] == RABackgroundModeForcedForeground)
		info |= RAIconIndicatorViewInfoForced;

	if ([self killProcessOnExit:identifier])
		info |= RAIconIndicatorViewInfoForceDeath;

	if ([self preventKillingOfIdentifier:identifier])
		info |= RAIconIndicatorViewInfoUnkillable;

	if ([self hasUnlimitedBackgroundTime:identifier])
		info |= RAIconIndicatorViewInfoUnlimitedBackgroundTime;

	if ([self shouldSuspendImmediately:identifier])
		info |= RAIconIndicatorViewInfoSuspendImmediately;

	return (RAIconIndicatorViewInfo)info;
}

-(void) updateIconIndicatorForIdentifier:(NSString*)identifier withInfo:(RAIconIndicatorViewInfo)info
{
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

-(BOOL) shouldShowIndicatorForIdentifier:(NSString*)identifier
{
	NSDictionary *dct = [RASettings.sharedInstance rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL globalSetting = [RASettings.sharedInstance shouldShowIconIndicatorsGlobally];
	return globalSetting ?: ([dct objectForKey:@"showIndicatorOnIcon"] == nil ? YES : [dct[@"showIndicatorOnIcon"] boolValue]);
}
@end