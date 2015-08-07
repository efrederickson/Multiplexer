#import <Preferences/Preferences.h>
#import <SettingsKit/SKListControllerProtocol.h>
#import <SettingsKit/SKTintedListController.h>
#import <Preferences/PSSwitchTableCell.h>
#import <AppList/AppList.h>
#import <substrate.h>
#import <notify.h>
#import "RAHeaderView.h"
#import "PDFImage.h"
#import <AppList/AppList.h>
#import "RABackgrounder.h"
#import <libactivator/libactivator.h>

#define PLIST_NAME @"/var/mobile/Library/Preferences/com.efrederickson.reachapp.settings.plist"

@interface PSViewController (Protean)
-(void) viewDidLoad;
-(void) viewWillDisappear:(BOOL)animated;
- (void)viewDidAppear:(BOOL)animated;
@end

@interface PSViewController (SettingsKit2)
-(UINavigationController*)navigationController;
-(void)viewWillAppear:(BOOL)animated;
-(void)viewWillDisappear:(BOOL)animated;
@end

@interface ALApplicationTableDataSource (Private)
- (void)sectionRequestedSectionReload:(id)section animated:(BOOL)animated;
@end

@interface ReachAppBackgrounderSettingsListController: SKTintedListController<SKListControllerProtocol>
@end

@implementation ReachAppBackgrounderSettingsListController
-(UIView*) headerView
{
    RAHeaderView *header = [[RAHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    header.colors = @[ 
        (id) [UIColor colorWithRed:248/255.0f green:73/255.0f blue:88/255.0f alpha:1.0f].CGColor, 
        (id) [UIColor colorWithRed:255/255.0f green:111/255.0f blue:124/255.0f alpha:1.0f].CGColor 
    ];
    header.shouldBlend = NO;
    header.image = [[PDFImage imageWithContentsOfFile:@"/Library/PreferenceBundles/ReachAppSettings.bundle/BackgrounderHeader.pdf"] imageWithOptions:[PDFImageOptions optionsWithSize:CGSizeMake(15, 33)]];

    UIView *notHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 70)];
    [notHeader addSubview:header];

    return notHeader;
}

-(UIColor*) tintColor { return [UIColor colorWithRed:248/255.0f green:73/255.0f blue:88/255.0f alpha:1.0f]; }
-(UIColor*) switchTintColor { return [[UISwitch alloc] init].tintColor; }

-(NSString*) customTitle { return @"Aura"; }
-(BOOL) showHeartImage { return NO; }

-(NSArray*) customSpecifiers
{
    return @[
             @{ @"footerText": @"Enable/disable Aura. After any change to the settings, a respring is recommended but not required." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"backgrounderEnabled",
                 @"label": @"Enabled",
                 },

             @{ @"footerText": @"This option changes whether to exit the current app after using the activator action to switch background modes." },
             @{
                @"cell": @"PSSwitchCell",
                @"label": @"Exit app after Menu",
                @"default": @YES,
                @"key": @"exitAppAfterUsingActivatorAction",
                @"defaults": @"com.efrederickson.reachapp.settings",
                @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
             },    
             @{
                @"cell": @"PSLinkCell",
                @"action": @"showActivatorAction",
                @"label": @"Activation method",
                //@"enabled": objc_getClass("LAEventSettingsController") != nil,
             },

             @{ @"label": @"Global Settings", @"footerText": @"Show in StatusBar will not show for apps with the \"Native\" mode." },
             @{
                @"cell": @"PSSwitchCell",
                @"label": @"Show Icon Indicators",
                @"default": @YES,
                @"key": @"showIconIndicators",
                @"defaults": @"com.efrederickson.reachapp.settings",
                @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
             },
             @{
                @"cell": @"PSSwitchCell",
                @"label": @"Show in StatusBar",
                @"default": @YES,
                @"key": @"shouldShowStatusBarIcons",
                @"defaults": @"com.efrederickson.reachapp.settings",
                @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
             },                          
    
             @{
                @"cell": @"PSLinkListCell",
                @"label": @"Background Mode",
                @"key": @"globalBackgroundMode",
                @"validTitles": @[ @"Native",                 /*@"Forced Native (old apps) [broken]",*/     @"Force Foreground",                 @"Disabled (Kill on exit)",      @"Suspend Immediately (SmartClose)" ],
                @"validValues": @[ @(RABackgroundModeNative), /*@(RABackgroundModeForceNativeForOldApps),*/ @(RABackgroundModeForcedForeground), @(RABackgroundModeForceNone),    @(RABackgroundModeSuspendImmediately)],
                @"shortTitles": @[ @"Native",                 /*@"Native+ [broken]",*/                      @"Forced",                           @"Disabled",                     @"SmartClose" ],
                @"default": @(RABackgroundModeNative),
                @"detail": @"PSListItemsController",
                @"defaults": @"com.efrederickson.reachapp.settings",
                @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                @"staticTextMessage": @"Does not apply to enabled apps with differing background modes in the \"Per App\" section."
                },
             @{
                @"cell": @"PSSwitchCell",
                @"label": @"Show Native Mode Indicators",
                @"default": @YES,
                @"key": @"showNativeStateIconIndicators",
                @"defaults": @"com.efrederickson.reachapp.settings",
                @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
             },
             @{ },
             @{
                @"cell": @"PSLinkCell",
                @"label": @"Per App",
                @"detail": @"RABGPerAppController",
             },
             ];
}

-(void) showActivatorAction
{
    id activator = objc_getClass("LAListenerSettingsViewController");
    if (!activator)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LOCALIZE(@"Multiplexer") message:@"Activator must be installed to use this feature." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    else
    {
        LAListenerSettingsViewController *vc = [[objc_getClass("LAListenerSettingsViewController") alloc] init];
        vc.listenerName = @"com.efrederickson.reachapp.backgrounder.togglemode";
        [self.rootController pushViewController:vc animated:YES];
    }
}
@end
