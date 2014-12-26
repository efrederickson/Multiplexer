#import <Preferences/Preferences.h>
#import <SettingsKit/SKListControllerProtocol.h>
#import <SettingsKit/SKTintedListController.h>

@interface ReachAppSettingsListController: SKTintedListController<SKListControllerProtocol>
@end

@implementation ReachAppSettingsListController

-(NSString*) headerText { return @"ReachApp"; }
-(NSString*) headerSubText { return @"Split-screen multitasking"; }

-(NSString*) customTitle { return @"ReachApp"; }

-(BOOL) showHeartImage { return NO; }

-(NSArray*) customSpecifiers
{
    return @[
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"enabled",
                 @"label": @"Enabled",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"showNCInstead",
                 @"label": @"Show NC instead of app",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"disableAutoDismiss",
                 @"label": @"Disable auto-dismiss",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"enableRotation",
                 @"label": @"Enable Rotation",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
                 
             ];
}

@end
