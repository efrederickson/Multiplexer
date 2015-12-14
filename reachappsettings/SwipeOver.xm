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
-(UIView*) headerView
{
    RAHeaderView *header = [[RAHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    header.colors = @[ 
        (id) [UIColor colorWithRed:88/255.0f green:86/255.0f blue:214/255.0f alpha:1.0f].CGColor,
        (id) [UIColor colorWithRed:198/255.0f green:68/255.0f blue:252/255.0f alpha:1.0f].CGColor, 
    ];
    header.shouldBlend = NO;
    header.image = [[RAPDFImage imageWithContentsOfFile:@"/Library/PreferenceBundles/ReachAppSettings.bundle/SwipeOverHeader.pdf"] imageWithOptions:[RAPDFImageOptions optionsWithSize:CGSizeMake(54, 32)]];

    UIView *notHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 70)];
    [notHeader addSubview:header];

    return notHeader;
}
-(NSString*) customTitle { return @"Swipe Over"; }
-(UIColor*) tintColor { return [UIColor colorWithRed:88/255.0f green:86/255.0f blue:214/255.0f alpha:1.0f]; }
-(UIColor*) switchTintColor { return [[UISwitch alloc] init].tintColor; }
-(BOOL) showHeartImage { return NO; }

-(void) viewDidAppear:(BOOL)arg1
{
    [super viewDidAppear:arg1];
    [super performSelector:@selector(setupHeader)];
}

-(NSArray*) customSpecifiers
{
    return @[
             @{ @"footerText": @"Quickly enable or disable Swipe Over." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"swipeOverEnabled",
                 @"label": @"Enabled",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"label": @"Swipe In From Left..."},
             @{
                 @"cell": @"PSSegmentCell",
                 @"validTitles": @[ @"Anywhere",               @"Top",                      @"Middle",           @"Bottom" ],
                 @"validValues": @[ @(RAGrabAreaSideAnywhere), @(RAGrabAreaSideTopThird), @(RAGrabAreaSideMiddleThird), @(RAGrabAreaSideBottomThird) ],
                 @"default": @(RAGrabAreaSideAnywhere),
                 @"key": @"swipeOverGrabArea",
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"footerText": @"If enabled, the grabber will always display when invoking Swipe Over." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"alwaysShowSOGrabber",
                 @"label": @"Always Display Grabber",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
            ];
}
@end

