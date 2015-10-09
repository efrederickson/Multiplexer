#import <Preferences/Preferences.h>
#import <SettingsKit/SKListControllerProtocol.h>
#import <SettingsKit/SKTintedListController.h>
#import <Preferences/PSSwitchTableCell.h>
#import <AppList/AppList.h>
#import <substrate.h>
#import <notify.h>
#import "RAHeaderView.h"
#import "PDFImage.h"

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

@interface ReachAppReachabilitySettingsListController: SKTintedListController<SKListControllerProtocol>
@end

@implementation ReachAppReachabilitySettingsListController
-(UIView*) headerView
{
    RAHeaderView *header = [[RAHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    header.colors = @[ 
        (id) [UIColor colorWithRed:29/255.0f green:119/255.0f blue:239/255.0f alpha:1.0f].CGColor, 
        (id) [UIColor colorWithRed:82/255.0f green:191/255.0f blue:232/255.0f alpha:1.0f].CGColor 
    ];
    header.shouldBlend = NO;
    //header.title = @"ReachApp";
    header.image = [[RAPDFImage imageWithContentsOfFile:@"/Library/PreferenceBundles/ReachAppSettings.bundle/ReachAppHeader.pdf"] imageWithOptions:[RAPDFImageOptions optionsWithSize:CGSizeMake(27.15, 32)]];

    UIView *notHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 70)];
    [notHeader addSubview:header];

    return notHeader;
}
-(UIColor*) tintColor { return [UIColor colorWithRed:29/255.0f green:119/255.0f blue:239/255.0f alpha:1.0f]; }
-(UIColor*) switchTintColor { return [[UISwitch alloc] init].tintColor; }
-(NSString*) customTitle { return @"Reach App"; }
-(BOOL) showHeartImage { return NO; }

-(NSArray*) customSpecifiers
{
    return @[
             @{ @"footerText": @"Quickly enable or disable ReachApp." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"reachabilityEnabled",
                 @"label": @"Enabled",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"footerText": @"If enabled, the Notification Center view is displayed in Reachability." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"showNCInstead",
                 @"label": @"Show NC Instead of App",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"footerText": @"Disables the default duration that Reachability closes after." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"disableAutoDismiss",
                 @"label": @"Disable Auto-dismiss",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
/*
             @{ @"footerText": @"Forces apps to rotate to the current orientation" },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"enableRotation",
                 @"label": @"Enable Rotation",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
*/

             @{ @"footerText": @"If enabled, the home button will no longer return to the home screen when Reachability is displayed." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"homeButtonClosesReachability",
                 @"label": @"Home Button Closes Reachability",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
/*
             @{ @"footerText": @"Shows the bottom half of the resizing grabber" },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"showBottomGrabber",
                 @"label": @"Show Bottom Grabber",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"footerText": @"This attempts to hide the lower status bar and force the upper status bar." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"unifyStatusBar",
                 @"label": @"Unify Status Bar",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
*/

             @{ @"footerText": @"If enabled, a widget selector will be displayed. If disabled, the last used app will be show in Reachability." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"showAppSelector",
                 @"label": @"Display Widget Selector",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
             @{
                @"cell": @"PSLinkListCell",
                @"detail": @"RAAppChooserOptionsListController",
                @"label": @"Options",
            },

/*
             @{ @"footerText": @"PLEASE NOTE THESE ARE BETA OPTIONS, STILL UNDER WORK OR TEMPORARILY BEING IGNORED. DO NOT SEND EMAILS RELATING TO THIS FEATURE. THEY WILL BE IGNORED. \n\nThat said, one will force applications into portrait and scale them to the screen size in landscape mode\nand the other will flip the top and bottom panes" },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @0,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"rotationMode",
                 @"label": @"Use Scaling Rotation Mode",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 @"cellClass": @"RASwitchCell",
                 },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"flipTopAndBottom",
                 @"label": @"Appear at Bottom",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
                 */
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
             @{ @"footerText": @"If enabled, the app selector will scale to the size of available apps." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"autoSizeAppChooser",
                 @"label": @"Auto-size Widget Chooser",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
             
             @{ @"footerText": @"If enabled, a list of your recent apps will display in the app selector." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"showRecents",
                 @"label": @"Display Recent Apps",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

            @{ @"footerText": @"Apps that will be displayed in the favorites section of the app selector." },
            @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"showFavorites",
                 @"label": @"Display Favorite Apps",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
            @{
                 @"cell": @"PSLinkListCell",
                 @"detail": @"RAFavoritesAppSelectorView",
                 @"label": @"Favorites",
                 },

             @{ @"footerText": @"If enabled, a section with all your apps will display in the app selector." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"showAllAppsInAppChooser",
                 @"label": @"Display All Apps",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"footerText": @"If enabled, apps will be divided into discrete pages." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"pagingEnabled",
                 @"label": @"Pagination",
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