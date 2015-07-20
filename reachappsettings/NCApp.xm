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

@interface ReachAppNCAppSettingsListController: SKTintedListController<SKListControllerProtocol>
@end

@implementation ReachAppNCAppSettingsListController
-(UIView*) headerView
{
    RAHeaderView *header = [[RAHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    header.colors = @[ 
        (id) [UIColor colorWithRed:90/255.0f green:212/255.0f blue:39/255.0f alpha:1.0f].CGColor,
        (id) [UIColor colorWithRed:164/255.0f green:231/255.0f blue:134/255.0f alpha:1.0f].CGColor, 
    ];
    header.image = [[PDFImage imageWithContentsOfFile:@"/Library/PreferenceBundles/ReachAppSettings.bundle/NCAppHeader.pdf"] imageWithOptions:[PDFImageOptions optionsWithSize:CGSizeMake(53, 32)]];

    UIView *notHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 70)];
    [notHeader addSubview:header];

    return notHeader;
}

-(NSString*) customTitle { return @"Quick Access"; }
-(BOOL) showHeartImage { return NO; }

-(NSArray*) customSpecifiers
{
    return @[
             @{ @"footerText": @"Respring to apply changes (to the NotificationCenter)." },
            @{
                 @"cell": @"PSLinkListCell",
                 @"detail": @"RANCAppSelectorView",
                 @"label": @"Selected App",
                 },
            ];
}
@end


@interface RANCAppSelectorView : PSViewController <UITableViewDelegate>
{
    UITableView* _tableView;
    ALApplicationTableDataSource* _dataSource;
}
@end

@interface RANCApplicationTableDataSource : ALApplicationTableDataSource
@end

@interface ALApplicationTableDataSource (Private_ReachApp)
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRow:(NSInteger)row;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@implementation RANCApplicationTableDataSource
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
        NSString *key = @"NCApp";// [NSString stringWithFormat:@"NCApp-%@",dn];
        //BOOL value = [prefs[key] boolValue];
        BOOL value = [dn isEqualToString:prefs[key]];
        [(ALCheckCell*)cell loadValue:@(value)];
    }
    return cell;
}
@end

@implementation RANCAppSelectorView

-(void)updateDataSource:(NSString*)searchText
{
    _dataSource.sectionDescriptors = [NSArray arrayWithObjects:
                                  [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"", ALSectionDescriptorTitleKey,
                                   @"ALCheckCell", ALSectionDescriptorCellClassNameKey,
                                   @(29), ALSectionDescriptorIconSizeKey,
                                    @YES, ALSectionDescriptorSuppressHiddenAppsKey,
                                   [NSString stringWithFormat:@"not bundleIdentifier in { }"],ALSectionDescriptorPredicateKey,
                                   @YES,@"ALSingleEnabledMode"
                                   , nil],
                                  nil];
    [_tableView reloadData];
}

-(id)init
{
    if (!(self = [super init])) return nil;
    
    CGRect bounds = [[UIScreen mainScreen] bounds];
    
    _dataSource = [[RANCApplicationTableDataSource alloc] init];
    
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
    if (selected)
        CFPreferencesSetAppValue((__bridge CFStringRef)@"NCApp", (CFPropertyListRef)(identifier), CFSTR("com.efrederickson.reachapp.settings"));

    [self updateDataSource:nil];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.7 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
      CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.reachapp.settings/reloadSettings"), nil, nil, YES);
    });
}
@end