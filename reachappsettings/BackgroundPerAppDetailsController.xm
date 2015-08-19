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
-(UIColor*) navigationTintColor { return [UIColor colorWithRed:248/255.0f green:73/255.0f blue:88/255.0f alpha:1.0f]; }

-(id) isBackgroundModeActive:(NSString*)mode withAppInfo:(NSArray*)info
{
    return [info containsObject:mode] ? @YES : @NO;
}

-(NSArray*) customSpecifiers
{
    LSApplicationProxy *appInfo = [%c(LSApplicationProxy) applicationProxyForIdentifier:_identifier];
    NSArray *bgModes = appInfo.UIBackgroundModes;

    BOOL exitsOnSuspend = [[NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/Info.plist",appInfo.bundleURL.absoluteString]]][@"UIApplicationExitsOnSuspend"] boolValue];

    BOOL preventDeath = [[self getActualPrefValue:@"preventDeath"] boolValue]; // Default is NO so it should work fine

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
             	@"validTitles": @[ @"Native",                 @"Unlimited Backgrounding Time",                  @"Force Foreground",                 @"Kill on Exit",      @"Suspend Immediately" ],
             	@"validValues": @[ @(RABackgroundModeNative), @(RABackgroundModeUnlimitedBackgroundingTime),    @(RABackgroundModeForcedForeground), @(RABackgroundModeForceNone),    @(RABackgroundModeSuspendImmediately)],
                @"shortTitles": @[ @"Native",                 @"∞",                                             @"Forced",                           @"Disabled",                     @"SmartClose" ],
             	@"default": @(RABackgroundModeNative),
             	@"detail": @"RABackgroundingListItemsController"
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
                
             @{ @"footerText": @"If the app's background mode is Disabled, this will remove the app from the switcher in addition to killing it." },
             @{
                @"cell": @"PSSwitchCell",
                @"label": @"Remove from Switcher",
                @"key": @"removeFromSwitcher",
                 @"default": @NO,
                },

            @{ @"footerText": @"This will prevent most cases of the app being terminated (app switcher, low memory, etc). Please note that if you enable this option, and your system runs low on memory or some other situation, it may yield unpredictable results. Enabling both this and \"Exit on Suspend\" (see below) will cause this switch to have no effect." },
            @{
                @"cell": @"PSSwitchCell",
                @"key": @"preventDeath",
                @"default": @NO,
                @"label": @"Prevent Death",
                @"enabled": @(!exitsOnSuspend),
                @"reloadSpecifiersXX": @YES,
            },
            @{ @"footerText": @"This switch causes applications to completely disable their backgrounding, natively. Apps such as BatteryLife, FinalFantasy2, and a certain Solitaire do this. This switch will not revert upon the uninstallation of Multiplexer because it actually writes to the app's data. A respring may be required to apply." },
            @{
                @"cell": @"PSSwitchCell",
                @"key": @"UIApplicationExitsOnSuspend",
                @"default": @(exitsOnSuspend),
                @"label": @"Exit on Suspend",
                @"enabled": @(!preventDeath),
                @"reloadSpecifiersXX": @YES,
            },
            @{ 
                @"cell": @"PSGroupCell",
                @"label": @"Native Backgrounding Modes", 
                @"footerText": @"A respring is required to apply changes to these values. Just because a mode has been enabled does not necessarily mean it will be used by the app.",
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
                @"label": @"VoIP",
                @"key": kBGModeVoIP,
                @"prefix": @"backgroundmodes",
                @"default": [self isBackgroundModeActive:kBGModeVoIP withAppInfo:bgModes],
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

         	@{ @"footerText": @"Description of icon letters: \n\
N - Native\n\
B - Unlimited Backgrounding Time\n\
F - Force Foreground\n\
D - Kill on Exit\n\
S - Suspend Immediately\n\
U - Unkillable\n\
\n\
The status bar icon is simply the app icon.", },
         	@{
         		@"cell": @"PSSwitchCell",
         		@"label": @"Show Icon Indicators",
         		@"key": @"showIndicatorOnIcon",
                 @"default": @YES,
             },
            @{
                @"cell": @"PSSwitchCell",
                @"label": @"Show in Status Bar",
                @"key": @"showStatusBarIcon",
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

        if ([[specifier propertyForKey:@"reloadSpecifiers"] boolValue])
            [self reloadSpecifiers];

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

    if ([[specifier propertyForKey:@"reloadSpecifiers"] boolValue])
        [self reloadSpecifiers];
}

-(id) getActualPrefValue:(NSString*)basename
{
    CFStringRef appID = CFSTR("com.efrederickson.reachapp.settings");
    CFArrayRef keyList = CFPreferencesCopyKeyList(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if (!keyList) {
        return nil;
    }
    NSDictionary *_settings = (__bridge NSDictionary *)CFPreferencesCopyMultiple(keyList, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    CFRelease(keyList);
    if (!_settings) {
        return nil;
    }

    NSString *key = [NSString stringWithFormat:@"backgrounder-%@-%@",_identifier,basename];
    return [_settings objectForKey:key] == nil ? nil : _settings[key];
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