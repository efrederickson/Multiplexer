#import <Preferences/Preferences.h>
#import <SettingsKit/SKListControllerProtocol.h>
#import <SettingsKit/SKTintedListController.h>
#import <Preferences/PSSwitchTableCell.h>
#import <AppList/AppList.h>
#import <substrate.h>
#import <notify.h>
#import "RAHeaderView.h"
#import "PDFImage.h"
#import "RASettings.h"
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

@interface ReachAppWindowSettingsListController: SKTintedListController<SKListControllerProtocol>
@end

@implementation ReachAppWindowSettingsListController
-(UIView*) headerView
{
    RAHeaderView *header = [[RAHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    header.colors = @[ 
        (id) [UIColor colorWithRed:255/255.0f green:94/255.0f blue:58/255.0f alpha:1.0f].CGColor,
        (id) [UIColor colorWithRed:255/255.0f green:149/255.0f blue:0/255.0f alpha:1.0f].CGColor, 
    ];
    header.shouldBlend = NO;
    header.image = [[RAPDFImage imageWithContentsOfFile:@"/Library/PreferenceBundles/ReachAppSettings.bundle/EmpoleonHeader.pdf"] imageWithOptions:[RAPDFImageOptions optionsWithSize:CGSizeMake(32, 32)]];

    UIView *notHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 70)];
    [notHeader addSubview:header];

    return notHeader;
}
-(UIColor*) tintColor { return [UIColor colorWithRed:255/255.0f green:94/255.0f blue:58/255.0f alpha:1.0f]; }
-(UIColor*) switchTintColor { return [[UISwitch alloc] init].tintColor; }
-(NSString*) customTitle { return @"Empoleon"; }
-(BOOL) showHeartImage { return NO; }

-(NSArray*) customSpecifiers
{
    return @[
                 @{ @"footerText": @"Quickly enable or disable Empoleon." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"windowedMultitaskingEnabled",
                 @"label": @"Enabled",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"label": @"Swipe Up From Bottom...", @"footerText": @"Launches all apps into windows rather than fullscreen." },
             @{
                 @"cell": @"PSSegmentCell",
                 @"validTitles": @[ @"Left",                      @"Middle",                      @"Right" ],
                 @"validValues": @[ @(RAGrabAreaBottomLeftThird), @(RAGrabAreaBottomMiddleThird), @(RAGrabAreaBottomRightThird), ],
                 @"default": @(RAGrabAreaBottomLeftThird),
                 @"key": @"windowedMultitaskingGrabArea",
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"launchIntoWindows",
                 @"label": @"Launch Into Window",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"footerText": @"If disabled, you will not be able to resize and rotate windows unless the easy-tap-mode overlay is displayed." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"alwaysEnableGestures",
                 @"label": @"Always Enable Gestures",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"onlyShowWindowBarIconsOnOverlay",
                 @"label": @"Only Show Icons in Easy-Tap-Mode",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"footerText": @"If enabled, tapping an icon on the easy-tap-mode overlay will be delayed until the bounce animation is complete." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"windowedMultitaskingCompleteAnimations",
                 @"label": @"Complete Animations",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"label": @"Snapping" },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"snapWindows",
                 @"label": @"Snap Windows",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"snapRotation",
                 @"label": @"Rotation Snapping",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"showSnapHelper",
                 @"label": @"Show Snap Helper",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"label": @"Lock button action" },
             @{
                 @"cell": @"PSSegmentCell",
                 @"validTitles": @[ @"Lock All Rotation", @"Lock App Rotation" ],
                 @"validValues": @[ @0, @1 ],
                 @"default": @0,
                 @"key": @"windowRotationLockMode",
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"label": @"Activator" },
             @{
                @"cell": @"PSLinkCell",
                @"action": @"showActivatorAction",
                @"label": @"Sort Windows Activation",
                //@"enabled": objc_getClass("LAEventSettingsController") != nil,
             },
             @{
                @"cell": @"PSLinkCell",
                @"action": @"showActivatorAction2",
                @"label": @"Easy-Tap-Mode Activation",
                //@"enabled": objc_getClass("LAEventSettingsController") != nil,
             },

                 /*
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"openLinksInWindows",
                 @"label": @"Open links in windows",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
                 */
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
        vc.listenerName = @"com.efrederickson.reachapp.windowedmultitasking.sortWindows";
        [self.rootController pushViewController:vc animated:YES];
    }
}

-(void) showActivatorAction2
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
        vc.listenerName = @"com.efrederickson.reachapp.windowedmultitasking.toggleEditMode";
        [self.rootController pushViewController:vc animated:YES];
    }
}
@end