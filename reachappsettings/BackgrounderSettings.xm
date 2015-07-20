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
             @{ @"footerText": @"Enable/disable ReachApp. After any change to the settings, a respring is recommended but not required." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"enabled",
                 @"label": @"Enabled",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             ];
}
@end
