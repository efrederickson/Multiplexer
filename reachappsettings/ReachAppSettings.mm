#import <Preferences/Preferences.h>
#import <SettingsKit/SKListControllerProtocol.h>
#import <SettingsKit/SKTintedListController.h>
#import <Preferences/PSSwitchTableCell.h>
#import <AppList/AppList.h>
#import <substrate.h>
#import <notify.h>
#import "RAHeaderView.h"
#import "PDFImage.h"
#import "headers.h"

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
    //if (arc4random_uniform(1000000) == 734025)
    //    header.title = @"卐卐 TWEAK SUPREMACY 卍卍";
    header.blendMode = kCGBlendModeSoftLight;
    header.image = [[PDFImage imageWithContentsOfFile:@"/Library/PreferenceBundles/ReachAppSettings.bundle/MainHeader.pdf"] imageWithOptions:[PDFImageOptions optionsWithSize:CGSizeMake(109.33, 41)]];

    UIView *notHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 115)];
    [notHeader addSubview:header];

    return notHeader;
}

-(NSString*) customTitle { return @"Multiplexer"; }

-(BOOL) showHeartImage { return YES; }
-(NSString*) shareMessage { return @"I'm multitasking with Multiplexer, by @daementor and @drewplex"; }

-(NSArray*) customSpecifiers
{
    return @[
             @{ @"footerText": @"Let apps run in the background." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"label": @"Enabled",
                 @"icon": @"enabled.png",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Aura",
                 @"detail": @"ReachAppBackgrounderSettingsListController",
                 @"icon": [UIImage imageNamed:@"aura.png" inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil]
                 },
             @{ @"footerText": @"Windowed multitasking." },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Empoleon",
                 @"detail": @"ReachAppWindowSettingsListController",
                 @"icon": [UIImage imageNamed:@"empoleon.png" inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil]
                 },
             @{ @"footerText": @"Manage multiple desktops and their windows." },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Mission Control",
                 @"detail": @"ReachAppMCSettingsListController",
                 @"icon": [UIImage imageNamed:@"missioncontrol.png" inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil]
                 },
             @{ @"footerText": @"Have an app in Notification Center." },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Quick Access",
                 @"detail": @"ReachAppNCAppSettingsListController",
                 @"icon": [UIImage imageNamed:@"quickaccess.png" inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil]
                 },
            @{ @"footerText": @"Use app in Reachability alongside another." },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Reach App",
                 @"detail": @"ReachAppReachabilitySettingsListController",
                 @"icon": [UIImage imageNamed:@"reachapp.png" inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil]
                 },
             @{ @"footerText": @"Access another app simply by swiping in from the right side of the screen." },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Swipe Over",
                 @"detail": @"ReachAppSwipeOverSettingsListController",
                 @"icon": [UIImage imageNamed:@"swipeover.png" inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil]
                 },
             @{ @"footerText": @"Questions? Problems?" },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Support",
                 @"detail": @"RASupportController",
                 @"icon": [UIImage imageNamed:@"support.png" inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil]
                 },
             ];
}
@end
