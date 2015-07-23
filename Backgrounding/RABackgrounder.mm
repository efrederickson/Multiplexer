#import "RABackgrounder.h"
#import "RASettings.h"

@implementation RABackgrounder
+(id) sharedInstance
{
	SHARED_INSTANCE2(RABackgrounder, sharedInstance->backgroundStateInfo = [NSMutableDictionary dictionary]);
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

-(void) setBackgroundStateIconInfo:(NSString*)info forIdentifier:(NSString*)identifier
{
	if (info)
		backgroundStateInfo[identifier] = info;
	else
		[backgroundStateInfo removeObjectForKey:identifier];
}

-(BOOL) hasBackgroundStateIconInfoForIdentifier:(NSString*)identifier
{
	return [backgroundStateInfo objectForKey:identifier] != nil;
}

-(NSString*) descriptionForBackgroundStateInfoWithIdentifier:(NSString*)identifier
{
	return backgroundStateInfo[identifier];
}

-(BOOL) application:(NSString*)identifier overrideBackgroundMode:(NSString*)mode
{
	NSDictionary *dict = [RASettings.sharedInstance rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	id val = dict[@"backgroundModes"][mode];
	return enabled && [val boolValue];
}
@end