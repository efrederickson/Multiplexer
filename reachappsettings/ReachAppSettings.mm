#import <Preferences/Preferences.h>
#import <SettingsKit/SKListControllerProtocol.h>
#import <SettingsKit/SKTintedListController.h>
#import <Preferences/PSSwitchTableCell.h>
#import <AppList/AppList.h>
#import <substrate.h>
#import <notify.h>

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

@interface ReachAppSettingsListController: SKTintedListController<SKListControllerProtocol>
@end

@implementation ReachAppSettingsListController

-(NSString*) headerText { return @"ReachApp"; }
-(NSString*) headerSubText { return @"Split-screen multitasking"; }

-(NSString*) customTitle { return @"ReachApp"; }

-(BOOL) showHeartImage { return YES; }
-(NSString*) shareMessage { return @"I'm using #ReachApp by @daementor for split screen multitasking on iOS!"; }

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
                 @"label": @"Show NC Instead of App",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"footerText": @"Disables the default duration that Reachability closes after" },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"disableAutoDismiss",
                 @"label": @"Disable Auto-dismiss",
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
                 @"label": @"Home Button Closes Reachability",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"footerText": @"Shows the bottom half of the resizing grabber" },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"showBottomGrabber",
                 @"label": @"Show Bottom Grabber",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"footerText": @"Shows an app chooser that allows you to choose which app to show. If disabled, the last used app will be shown in Reachability." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"showAppSelector",
                 @"label": @"Show App Selector",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
             @{
                @"cell": @"PSLinkListCell",
                @"detail": @"RAAppChooserOptionsListController",
                @"label": @"App Chooser Options",
            },

             @{ @"footerText": @"PLEASE NOTE THIS IS A BETA OPTION, IT'S STILL UNDER WORK. DO NOT SEND EMAILS RELATING TO THIS FEATURE. THEY WILL BE IGNORED. \n\nThat said, it will force applications into portrait and scale them to the screen size in landscape mode." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @0,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"rotationMode",
                 @"label": @"Use Scaling Rotation Mode",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 @"cellClass": @"RASwitchCell",
                 },
             ];
}
@end

@interface RAAppChooserOptionsListController : SKTintedListController<SKListControllerProtocol, UIAlertViewDelegate>
@end

@implementation RAAppChooserOptionsListController
-(BOOL) showHeartImage { return NO; }
-(NSArray*) customSpecifiers 
{
    return @[
             @{ @"footerText": @"Auto-size the app chooser to the size of the available apps... Or not." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"autoSizeAppChooser",
                 @"label": @"Auto-size App Chooser",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
             
             @{ @"footerText": @"Choose whether to show the recents section in the chooser or not." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"showRecents",
                 @"label": @"Show Recent Apps",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

            @{ @"footerText": @"Apps to show in the Favorites section of the app chooser." },
            @{
                 @"cell": @"PSLinkListCell",
                 @"detail": @"RAFavoritesAppSelectorView",
                 @"label": @"Favorites",
                 },

             @{ @"footerText": @"Choose whether to show the all apps section in the chooser or not." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"showAllAppsInAppChooser",
                 @"label": @"Show All Apps",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"footerText": @"Choose whether to page the app chooser, allowing for a different experience." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"pagingEnabled",
                 @"label": @"Paging Enabled",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
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

@interface RAFavoritesAppSelectorView : PSViewController <UITableViewDelegate>
{
    UITableView* _tableView;
    ALApplicationTableDataSource* _dataSource;
}
@end

@interface RAApplicationTableDataSource : ALApplicationTableDataSource
@end

@interface ALApplicationTableDataSource (Private_ReachApp)
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRow:(NSInteger)row;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@implementation RAApplicationTableDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //NSInteger row = indexPath.row;
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

    NSDictionary *prefs = nil;

    CFStringRef appID = CFSTR("com.efrederickson.reachapp.settings");
    CFArrayRef keyList = CFPreferencesCopyKeyList(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if (!keyList) {
        return cell;
    }
    prefs = (__bridge NSDictionary*)CFPreferencesCopyMultiple(keyList, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if (!prefs) {
        return cell;
    }
    CFRelease(keyList);

    if ([cell isKindOfClass:[ALCheckCell class]])
    {
        NSString *dn = [self displayIdentifierForIndexPath:indexPath];
        NSString *key = [NSString stringWithFormat:@"Favorites-%@",dn];
        BOOL value = [prefs[key] boolValue];
        [(ALCheckCell*)cell loadValue:@(value)];
    }
    return cell;
}
@end

@implementation RAFavoritesAppSelectorView

-(void)updateDataSource:(NSString*)searchText
{
    _dataSource.sectionDescriptors = [NSArray arrayWithObjects:
                                  [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"", ALSectionDescriptorTitleKey,
                                   @"ALCheckCell", ALSectionDescriptorCellClassNameKey,
                                   @(29), ALSectionDescriptorIconSizeKey,
                                    @YES, ALSectionDescriptorSuppressHiddenAppsKey,
                                   [NSString stringWithFormat:@"not bundleIdentifier in { }"],
                                   ALSectionDescriptorPredicateKey
                                   , nil],
                                  nil];
    [_tableView reloadData];
}

-(id)init
{
    if (!(self = [super init])) return nil;
    
    CGRect bounds = [[UIScreen mainScreen] bounds];
    
    _dataSource = [[RAApplicationTableDataSource alloc] init];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, bounds.size.height) style:UITableViewStyleGrouped];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.delegate = self;
    _tableView.dataSource = _dataSource;
    _dataSource.tableView = _tableView;
    [self updateDataSource:nil];
    
    return self;
}

-(void)viewDidLoad
{
    ((UIViewController *)self).title = @"Applications";
    [self.view addSubview:_tableView];
    [super viewDidLoad];
}

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    ALCheckCell* cell = (ALCheckCell*)[tableView cellForRowAtIndexPath:indexPath];
    [cell didSelect];

    UITableViewCellAccessoryType type = [cell accessoryType];
    BOOL selected = type == UITableViewCellAccessoryCheckmark;
    
    NSString *identifier = [_dataSource displayIdentifierForIndexPath:indexPath];
    CFPreferencesSetAppValue((__bridge CFStringRef)[NSString stringWithFormat:@"Favorites-%@", identifier], (CFPropertyListRef)(@(selected)), CFSTR("com.efrederickson.reachapp.settings"));

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.7 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
      CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.reachapp.settings/reloadSettings"), nil, nil, YES);
    });
}
@end