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
    header.image = [[RAPDFImage imageWithContentsOfFile:@"/Library/PreferenceBundles/ReachAppSettings.bundle/BackgrounderHeader.pdf"] imageWithOptions:[RAPDFImageOptions optionsWithSize:CGSizeMake(15, 33)]];

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
             @{ @"footerText": @"Quickly enable or disable Aura. Relaunch apps to apply changes." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"backgrounderEnabled",
                 @"label": @"Enabled",
                 },

             @{ @"label": @"Activator",
                @"footerText": @"If enabled, the current app will be closed after performing the activation method.",
             },
             @{
                @"cell": @"PSLinkCell",
                @"action": @"showActivatorAction",
                @"label": @"Activation Method",
                //@"enabled": objc_getClass("LAEventSettingsController") != nil,
             },
             @{
                @"cell": @"PSSwitchCell",
                @"label": @"Exit App After Menu",
                @"default": @YES,
                @"key": @"exitAppAfterUsingActivatorAction",
                @"defaults": @"com.efrederickson.reachapp.settings",
                @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
             },

             @{ @"label": @"Global", @"footerText": @"" },
    
             @{
                @"cell": @"PSLinkListCell",
                @"label": @"Background Mode",
                @"key": @"globalBackgroundMode",
                @"validTitles": @[ @"Native",                 @"Unlimited Backgrounding Time",                  @"Force Foreground",                 @"Kill on Exit",      @"Suspend Immediately" ],
                @"validValues": @[ @(RABackgroundModeNative), @(RABackgroundModeUnlimitedBackgroundingTime),    @(RABackgroundModeForcedForeground), @(RABackgroundModeForceNone),    @(RABackgroundModeSuspendImmediately)],
                @"shortTitles": @[ @"Native",                 @"∞",                                             @"Forced",                           @"Disabled",                     @"SmartClose" ],
                @"default": @(RABackgroundModeNative),
                @"detail": @"RABackgroundingListItemsController",
                @"defaults": @"com.efrederickson.reachapp.settings",
                @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                @"staticTextMessage": @"Does not apply to apps enabled with differing options in the “Per App” section."
                },
             @{
                @"cell": @"PSLinkListCell",
                @"detail": @"RABackgrounderIconIndicatorOptionsListController",
                @"label": @"Icon Indicator Options",
            },
             @{
                @"cell": @"PSLinkListCell",
                @"detail": @"RABackgrounderStatusbarOptionsListController",
                @"label": @"Status Bar Indicator Options",
            },   
             @{ @"label": @"Specific" },
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

@interface RABackgrounderIconIndicatorOptionsListController : SKTintedListController<SKListControllerProtocol, UIAlertViewDelegate>
@end

@implementation RABackgrounderIconIndicatorOptionsListController
-(UIColor*) navigationTintColor { return [UIColor colorWithRed:248/255.0f green:73/255.0f blue:88/255.0f alpha:1.0f]; }
-(BOOL) showHeartImage { return NO; }
-(NSArray*) customSpecifiers 
{
    return @[
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
                @"label": @"Show Native Mode Indicators",
                @"default": @NO,
                @"key": @"showNativeStateIconIndicators",
                @"defaults": @"com.efrederickson.reachapp.settings",
                @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
             },
                 ];
}
@end

@interface RABackgrounderStatusbarOptionsListController : SKTintedListController<SKListControllerProtocol, UIAlertViewDelegate>
@end

@implementation RABackgrounderStatusbarOptionsListController
-(UIColor*) navigationTintColor { return [UIColor colorWithRed:248/255.0f green:73/255.0f blue:88/255.0f alpha:1.0f]; }
-(BOOL) showHeartImage { return NO; }
-(NSArray*) customSpecifiers 
{
    return @[
             @{
                @"cell": @"PSSwitchCell",
                @"label": @"Show on Status Bar",
                @"default": @YES,
                @"key": @"shouldShowStatusBarIcons",
                @"defaults": @"com.efrederickson.reachapp.settings",
                @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
             },
             @{
                @"cell": @"PSSwitchCell",
                @"label": @"Show Native in Status Bar",
                @"default": @NO,
                @"key": @"shouldShowStatusBarNativeIcons",
                @"defaults": @"com.efrederickson.reachapp.settings",
                @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
             },        
                 ];
}
@end
