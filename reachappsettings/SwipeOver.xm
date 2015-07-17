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

@interface ReachAppSwipeOverSettingsListController: SKTintedListController<SKListControllerProtocol>
@end

@implementation ReachAppSwipeOverSettingsListController
-(NSString*) headerText { return @"SwipeOver"; }
-(NSString*) headerSubText { return @"Slide in from the right"; }
-(NSString*) customTitle { return @"SwipeOver"; }

-(BOOL) showHeartImage { return NO; }

-(NSArray*) customSpecifiers
{
    return @[
             @{ @"footerText": @"todo" },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"__todo__",
                 @"label": @"todo",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
            ];
}
@end

