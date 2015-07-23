#import "BackgroundPerAppDetailsController.h"
#import <AppList/AppList.h>
#import "RABackgrounder.h"
#import "headers.h"

extern void RA_BGAppsControllerNeedsToReload();

@implementation RABGPerAppDetailsController
-(id)initWithAppName:(NSString*)appName identifier:(NSString*)identifier
{
	_appName = appName;
	_identifier = identifier;
	return [self init];
}

-(NSString*) customTitle { return _appName; }
-(BOOL) showHeartImage { return NO; }

-(id) isBackgroundModeActive:(NSString*)mode withAppInfo:(NSArray*)info
{
    return [info containsObject:mode] ? @YES : @NO;
}

-(NSArray*) customSpecifiers
{
    LSApplicationProxy *appInfo = [%c(LSApplicationProxy) applicationProxyForIdentifier:_identifier];
    NSArray *bgModes = appInfo.UIBackgroundModes;

    BOOL exitsOnSuspend = [[NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/Info.plist",appInfo.bundleURL.absoluteString]]][@"UIApplicationExitsOnSuspend"] boolValue];

    return @[
             @{
                 @"cell": @"PSSwitchCell",
                 @"label": @"Enabled",
                 @"key": @"enabled",
                 @"default": @NO,
                 },

             @{ @"label": @""},
             @{
             	@"cell": @"PSLinkListCell",
             	@"label": @"Background Mode",
             	@"key": @"backgroundMode",
             	@"validTitles": @[ @"Native",                 /*@"Forced Native (old apps) [broken]",*/     @"Force Foreground",                 @"Disabled (Kill on exit)" ],
             	@"validValues": @[ @(RABackgroundModeNative), /*@(RABackgroundModeForceNativeForOldApps),*/ @(RABackgroundModeForcedForeground), @(RABackgroundModeForceNone), ],
                @"shortTitles": @[ @"Native",                 /*@"Native+ [broken]",*/                      @"Forced",                           @"Disabled" ],
             	@"default": @"1",
             	@"detail": @"PSListItemsController"
             	},
             @{
                @"cell": @"PSSwitchCell",
                @"label": @"Unlimited Backgrounding Time",
                @"key": @"unlimitedBackgrounding",
                @"default": @NO,
                },
             @{
             	@"cell": @"PSSwitchCell",
             	@"label": @"Auto Launch",
             	@"key": @"autoLaunch",
                 @"default": @NO,
             	},
         	 @{
         	 	@"cell": @"PSSwitchCell",
         	 	@"label": @"Auto Relaunch",
         	 	@"key": @"autoRelaunch",
                 @"default": @NO,
         		},
            @{ @"footerText": @"This will prevent most cases of the app being terminated (app switcher, low memory, etc). Please note that using if you enable this option, and your system runs low on memory or some other situation, it may yield unpredictable results." },
            @{
                @"cell": @"PSSwitchCell",
                @"key": @"preventDeath",
                @"default": @NO,
                @"label": @"Prevent Death",
            },
            @{ @"footerText": @"This switch causes applications to completely disable their backgrounding, natively. Apps such as BatteryLife, FinalFantasy2, and a certain Solitaire do this. This switch will not revert upon the uninstallation of Multiplexer. A respring may or may not be required to apply." },
            @{
                @"cell": @"PSSwitchCell",
                @"key": @"UIApplicationExitsOnSuspend",
                @"default": @(exitsOnSuspend),
                @"label": @"Exit on Suspend",
            },
            @{ 
                @"cell": @"PSGroupCell",
                @"label": @"Native Backgrounding Modes", 
                @"footerText": @"A respring is required to apply changes to these values." 
                },
            @{
                @"cell": @"PSSwitchCell",
                @"label": @"Unbounded Task Completion",
                @"key": kBGModeUnboundedTaskCompletion,
                @"prefix": @"backgroundmodes",
                @"default": [self isBackgroundModeActive:kBGModeUnboundedTaskCompletion withAppInfo:bgModes],
            },
            @{
                @"cell": @"PSSwitchCell",
                @"label": @"Continuous",
                @"key": kBGModeContinuous,
                @"prefix": @"backgroundmodes",
                @"default": [self isBackgroundModeActive:kBGModeContinuous withAppInfo:bgModes],
            },
            @{
                @"cell": @"PSSwitchCell",
                @"label": @"Fetch",
                @"key": kBGModeFetch,
                @"prefix": @"backgroundmodes",
                @"default": [self isBackgroundModeActive:kBGModeFetch withAppInfo:bgModes],
            },
            @{
                @"cell": @"PSSwitchCell",
                @"label": @"Remote Notification",
                @"key": kBGModeRemoteNotification,
                @"prefix": @"backgroundmodes",
                @"default": [self isBackgroundModeActive:kBGModeRemoteNotification withAppInfo:bgModes],
            },
            @{
                @"cell": @"PSSwitchCell",
                @"label": @"External Accessory",
                @"key": kBGModeExternalAccessory,
                @"prefix": @"backgroundmodes",
                @"default": [self isBackgroundModeActive:kBGModeExternalAccessory withAppInfo:bgModes],
            },
            @{
                @"cell": @"PSSwitchCell",
                @"label": @"VOiP",
                @"key": kBGModeVOiP,
                @"prefix": @"backgroundmodes",
                @"default": [self isBackgroundModeActive:kBGModeVOiP withAppInfo:bgModes],
            },
            @{
                @"cell": @"PSSwitchCell",
                @"label": @"Location",
                @"key": kBGModeLocation,
                @"prefix": @"backgroundmodes",
                @"default": [self isBackgroundModeActive:kBGModeLocation withAppInfo:bgModes],
            },
            @{
                @"cell": @"PSSwitchCell",
                @"label": @"Audio",
                @"key": kBGModeAudio,
                @"prefix": @"backgroundmodes",
                @"default": [self isBackgroundModeActive:kBGModeAudio withAppInfo:bgModes],
            },
            @{
                @"cell": @"PSSwitchCell",
                @"label": @"Bluetooth (Central)",
                @"key": kBGModeBluetoothCentral,
                @"prefix": @"backgroundmodes",
                @"default": [self isBackgroundModeActive:kBGModeBluetoothCentral withAppInfo:bgModes],
            },
            @{
                @"cell": @"PSSwitchCell",
                @"label": @"Bluetooth (Peripheral)",
                @"key": kBGModeBluetoothPeripheral,
                @"prefix": @"backgroundmodes",
                @"default": [self isBackgroundModeActive:kBGModeBluetoothPeripheral withAppInfo:bgModes],
            },

         	@{ },
         	@{
         		@"cell": @"PSSwitchCell",
         		@"label": @"Show Indicator on icon",
         		@"key": @"showIndicatorOnIcon",
                 @"default": @YES,
             },
             ];
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier
{
    //[super setPreferenceValue:value specifier:specifier];

    if ([[specifier propertyForKey:@"key"] isEqualToString:@"UIApplicationExitsOnSuspend"])
    {
        LSApplicationProxy *appInfo = [%c(LSApplicationProxy) applicationProxyForIdentifier:_identifier];
        NSString *path = [NSString stringWithFormat:@"%@/Info.plist",appInfo.bundleURL.absoluteString];
        NSMutableDictionary *infoPlist = [NSMutableDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:path]];
        infoPlist[@"UIApplicationExitsOnSuspend"] = value;
        BOOL success = [infoPlist writeToURL:[NSURL URLWithString:path] atomically:YES];

        if (!success)
        {
            NSMutableDictionary *daemonDict = [NSMutableDictionary dictionary];
            daemonDict[@"bundleIdentifier"] = _identifier;
            daemonDict[@"UIApplicationExitsOnSuspend"] = value;
            [daemonDict writeToFile:@"/User/Library/.reachapp.uiappexitsonsuspend.wantstochangerootapp" atomically:YES];
        }

        return;
    }

	CFStringRef appID = CFSTR("com.efrederickson.reachapp.settings");

    NSString *key = [NSString stringWithFormat:@"backgrounder-%@-%@",_identifier,[specifier propertyForKey:@"key"]];
    if ([specifier propertyForKey:@"prefix"])
        key = [NSString stringWithFormat:@"backgrounder-%@-%@-%@",_identifier,[specifier propertyForKey:@"prefix"],[specifier propertyForKey:@"key"]];
    CFPreferencesSetAppValue((__bridge CFStringRef)key, (const void*)value, appID);

    CFPreferencesAppSynchronize(appID);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.reachapp.settings/reloadSettings"), nil, nil, YES);
    RA_BGAppsControllerNeedsToReload();
}

 -(id)readPreferenceValue:(PSSpecifier*)specifier
 {
	CFStringRef appID = CFSTR("com.efrederickson.reachapp.settings");
	CFArrayRef keyList = CFPreferencesCopyKeyList(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (!keyList) {
		return [specifier propertyForKey:@"default"];
	}
	NSDictionary *_settings = (__bridge NSDictionary *)CFPreferencesCopyMultiple(keyList, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFRelease(keyList);
	if (!_settings) {
		return [specifier propertyForKey:@"default"];
	}

    NSString *key = [specifier propertyForKey:@"prefix"] ? [NSString stringWithFormat:@"backgrounder-%@-%@-%@",_identifier,[specifier propertyForKey:@"prefix"],[specifier propertyForKey:@"key"]] : [NSString stringWithFormat:@"backgrounder-%@-%@",_identifier,[specifier propertyForKey:@"key"]];
    return [_settings objectForKey:key] == nil ? [specifier propertyForKey:@"default"] : _settings[key];
 }
@end