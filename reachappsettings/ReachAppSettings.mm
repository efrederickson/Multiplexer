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

@interface ReachAppSettingsListController: SKTintedListController<SKListControllerProtocol>
@end

@implementation ReachAppSettingsListController
-(UIView*) headerView
{
    RAHeaderView *header = [[RAHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 95)];
    header.colors = @[ 
        (id) [UIColor colorWithRed:234/255.0f green:152/255.0f blue:115/255.0f alpha:1.0f].CGColor, 
        (id) [UIColor colorWithRed:190/255.0f green:83/255.0f blue:184/255.0f alpha:1.0f].CGColor 
    ];
    if (arc4random_uniform(1000000) == 734025)
        header.title = @"卐卐 TWEAK SUPREMACY 卍卍";
    header.blendMode = kCGBlendModeSoftLight;
    header.image = [[PDFImage imageWithContentsOfFile:@"/Library/PreferenceBundles/ReachAppSettings.bundle/MainHeader.pdf"] imageWithOptions:[PDFImageOptions optionsWithSize:CGSizeMake(109.33, 41)]];

    UIView *notHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 115)];
    [notHeader addSubview:header];

    return notHeader;
}

-(NSString*) customTitle { return @"Multiplexer"; }

-(BOOL) showHeartImage { return YES; }
-(NSString*) shareMessage { return @"TODO"; }

-(NSArray*) customSpecifiers
{
    return @[
             @{ @"footerText": @"Backgrounder" },
             @{
                 @"cell": @"PSLinkListCell",
                 @"label": @"Aura",
                 @"detail": @"ReachAppBackgrounderSettingsListController",
                 @"icon": @"aura.png",
                 },
             @{ @"footerText": @"Wiondowed Multitasking" },
             @{
                 @"cell": @"PSLinkListCell",
                 @"label": @"Empoleon",
                 @"detail": @"ReachAppWindowSettingsListController",
                 @"icon": @"empoleon.png",
                 },
             @{ @"footerText": @"MissionControl" },
             @{
                 @"cell": @"PSLinkListCell",
                 @"label": @"Mission Control",
                 @"detail": @"ReachAppMCSettingsListController",
                 @"icon": @"missioncontrol.png",
                 },
             @{ @"footerText": @"NotificationCenter" },
             @{
                 @"cell": @"PSLinkListCell",
                 @"label": @"Quick Access",
                 @"detail": @"ReachAppNCAppSettingsListController",
                 @"icon": @"quickaccess.png",
                 },
            @{ @"footerText": @"Reachability" },
             @{
                 @"cell": @"PSLinkListCell",
                 @"label": @"ReachApp",
                 @"detail": @"ReachAppReachabilitySettingsListController",
                 @"icon": @"reachapp.png",
                 },
             @{ @"footerText": @"SwipeOver" },
             @{
                 @"cell": @"PSLinkListCell",
                 @"label": @"SwipeOver",
                 @"detail": @"ReachAppSwipeOverSettingsListController",
                 @"icon": @"swipeover.png",
                 },
             ];
}
@end
