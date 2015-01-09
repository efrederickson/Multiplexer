#import <Preferences/Preferences.h>
#import <SettingsKit/SKListControllerProtocol.h>
#import <SettingsKit/SKTintedListController.h>
#import <Preferences/PSSwitchTableCell.h>

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
             @{ @"footerText": @"Enable/disable ReachApp. After any change to the settings, a respring is recommended but not required." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"enabled",
                 @"label": @"Enabled",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"footerText": @"Show the Notification Center instead of an app in the Reachability view." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"showNCInstead",
                 @"label": @"Show NC instead of app",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"footerText": @"Disables the default duration that Reachability closes after" },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"disableAutoDismiss",
                 @"label": @"Disable auto-dismiss",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"footerText": @"Forces apps to rotate to the current orientation" },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"enableRotation",
                 @"label": @"Enable Rotation",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"footerText": @"Instead of the home button closing Reachability and going to home screen it will just close Reachability." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"homeButtonClosesReachability",
                 @"label": @"Home button closes Reachability",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"footerText": @"Shows the bottom half of the resizing grabber" },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"showBottomGrabber",
                 @"label": @"Show bottom grabber",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"footerText": @"Shows an app chooser similar to the iOS 6 App Switcher in the Reachability view. Only running apps will show. If disabled, the last used app will be shown in Reachability." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"showAppSelector",
                 @"label": @"Show App Selector",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"footerText": @"Auto-size the app chooser to the size of the available apps... Or not." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"autoSizeAppChooser",
                 @"label": @"Auto-size app chooser",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"footerText": @"PLEASE NOTE THIS IS A BETA OPTION, IT'S STILL UNDER WORK. DO NOT SEND EMAILS RELATING TO THIS FEATURE. THEY WILL BE IGNORED. \n\nThat said, it will force applications into portrait and scale them to the screen size in landscape mode." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @0,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"rotationMode",
                 @"label": @"Use scaling rotation mode",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 @"cellClass": @"RASwitchCell",
                 },
             ];
}
@end

@interface RASwitchCell : PSSwitchTableCell //our class
@end
 
@implementation RASwitchCell
 
-(id)initWithStyle:(int)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 { //init method
    self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3]; //call the super init method
    if (self) {
        [((UISwitch *)[self control]) setOnTintColor:[UIColor redColor]]; //change the switch color
    }
    return self;
}
 
@end