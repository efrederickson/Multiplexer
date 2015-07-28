#import <Preferences/Preferences.h>
#import <SettingsKit/SKListControllerProtocol.h>
#import <SettingsKit/SKTintedListController.h>
#import <Preferences/PSSwitchTableCell.h>
#import <SettingsKit/SKStandardController.h>
#import <SettingsKit/SKPersonCell.h>
#import <SettingsKit/SKSharedHelper.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>
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

@interface ReachAppSettingsListController: SKTintedListController<SKListControllerProtocol, MFMailComposeViewControllerDelegate>
@end

@implementation ReachAppSettingsListController
-(UIView*) headerView
{
    RAHeaderView *header = [[RAHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 95)];
    header.colors = @[ 
        (id) [UIColor colorWithRed:234/255.0f green:152/255.0f blue:115/255.0f alpha:1.0f].CGColor, 
        (id) [UIColor colorWithRed:190/255.0f green:83/255.0f blue:184/255.0f alpha:1.0f].CGColor 
    ];
#if DEBUG
    if (arc4random_uniform(1000000) == 11)
        header.title = @"卐卐 TWEAK SUPREMACY 卍卍";
    else if (arc4random_uniform(1000000) >= 300000)
        header.title = @"dank memes";
#endif
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
             @{ @"footerText": @"Quickly enable or disable Multiplexer." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"enabled",
                 @"label": @"Enabled",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 @"icon": RSIMG(@"ra_enabled.png")
                 },

             @{ @"footerText": @"Let apps run in the background." },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Aura",
                 @"detail": @"ReachAppBackgrounderSettingsListController",
                 @"icon": RSIMG(@"aura.png")
                 },
             @{ @"footerText": @"Windowed multitasking." },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Empoleon",
                 @"detail": @"ReachAppWindowSettingsListController",
                 @"icon": RSIMG(@"empoleon.png")
                 },
             @{ @"footerText": @"Manage multiple desktops and their windows." },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Mission Control",
                 @"detail": @"ReachAppMCSettingsListController",
                 @"icon": RSIMG(@"missioncontrol.png")
                 },
             @{ @"footerText": @"Have an app in Notification Center." },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Quick Access",
                 @"detail": @"ReachAppNCAppSettingsListController",
                 @"icon": RSIMG(@"quickaccess.png")
                 },
            @{ @"footerText": @"Use an app in Reachability alongside another." },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Reach App",
                 @"detail": @"ReachAppReachabilitySettingsListController",
                 @"icon": RSIMG(@"reachapp.png")
                 },
             @{ @"footerText": @"Access another app simply by swiping in from the right side of the screen." },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Swipe Over",
                 @"detail": @"ReachAppSwipeOverSettingsListController",
                 @"icon": RSIMG(@"swipeover.png")
                 },
             @{ @"footerText": [NSString stringWithFormat:@"%@%@",
#if DEBUG
                    arc4random_uniform(10000) == 9901 ? @"2fast5me" : 
#endif
                    @"© 2015 Elijah Frederickson & Andrew Abosh.",
#if DEBUG
                    @" **DEBUG** "
#else
                    @""
#endif
                     ]},
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Creators",
                 @"detail": @"RAMakersController",
                 @"icon": RSIMG(@"ra_makers.png")
                 },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Support",
                 @"action": @"showSupportDialog",
                 @"icon": RSIMG(@"ra_support.png")
                 },

             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Tutorial",
                 @"action": @"showTutorial",
                 @"icon": @"tutorial.png"
                 },
             ];
}

-(void) showSupportDialog
{
    MFMailComposeViewController *mailViewController;
    if ([MFMailComposeViewController canSendMail])
    {
        mailViewController = [[MFMailComposeViewController alloc] init];
        mailViewController.mailComposeDelegate = self;
        [mailViewController setSubject:@"Multiplexer"];
        
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString *sysInfo = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
        
        NSString *msg = [NSString stringWithFormat:@"\n\n%@ %@\nModel: %@\n", [UIDevice currentDevice].systemName, [UIDevice currentDevice].systemVersion, sysInfo];
        [mailViewController setMessageBody:msg isHTML:NO];
        [mailViewController setToRecipients:@[@"elijahandandrew@gmail.com"]];
            
        [self.rootController presentViewController:mailViewController animated:YES completion:nil];
    }

}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error{
    [self dismissViewControllerAnimated:YES completion:NULL];
}
@end
