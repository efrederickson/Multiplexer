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
    //header.title = @"卐卐 TWEAK SUPREMACY 卍卍";
    header.image = [[PDFImage imageWithContentsOfFile:@"/Library/PreferenceBundles/ReachAppSettings.bundle/MainHeader.pdf"] imageWithOptions:[PDFImageOptions optionsWithSize:CGSizeMake(109.33, 41)]];

    UIView *notHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 115)];
    [notHeader addSubview:header];

    return notHeader;
}

-(NSString*) customTitle { return @"卐 ReachApp 卍"; }

-(BOOL) showHeartImage { return YES; }
-(NSString*) shareMessage { return @"TODO"; }

-(NSArray*) customSpecifiers
{
    return @[
             @{
                 @"cell": @"PSLinkListCell",
                 @"label": @"Reachability",
                 @"detail": @"ReachAppReachabilitySettingsListController",
                 },
             @{ },
             @{
                 @"cell": @"PSLinkListCell",
                 @"label": @"SwipeOver",
                 @"detail": @"ReachAppSwipeOverSettingsListController",
                 },
             @{ },
             @{
                 @"cell": @"PSLinkListCell",
                 @"label": @"NotificationCenter (Quick Access)",
                 @"detail": @"ReachAppNCAppSettingsListController",
                 },
             @{ },
             @{
                 @"cell": @"PSLinkListCell",
                 @"label": @"Windowed Multitasking (Empoleon)",
                 @"detail": @"ReachAppWindowSettingsListController",
                 },
             @{ },
             @{
                 @"cell": @"PSLinkListCell",
                 @"label": @"Mission Control",
                 @"detail": @"ReachAppMCSettingsListController",
                 },
             @{ },
             @{
                 @"cell": @"PSLinkListCell",
                 @"label": @"Backgrounder (Aura)",
                 @"detail": @"ReachAppBackgrounderSettingsListController",
                 },
             ];
}
@end
