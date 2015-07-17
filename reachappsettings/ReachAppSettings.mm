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

-(NSString*) headerText { return @"Empoleon"; }
-(NSString*) headerSubText { return @"卐卐 TWEAK SUPREMACY 卍卍"; }

-(NSString*) customTitle { return @"ReachApp"; }

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
                 @"label": @"NotificationCenter",
                 @"detail": @"ReachAppNCAppSettingsListController",
                 },
             @{ },
             @{
                 @"cell": @"PSLinkListCell",
                 @"label": @"Windowed Multitasking",
                 @"detail": @"ReachAppWindowSettingsListController",
                 },
             ];
}
@end
