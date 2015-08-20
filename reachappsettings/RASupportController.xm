#import <Preferences/Preferences.h>
#import <SettingsKit/SKListControllerProtocol.h>
#import <SettingsKit/SKTintedListController.h>
#import <SettingsKit/SKStandardController.h>
#import <SettingsKit/SKPersonCell.h>
#import <SettingsKit/SKSharedHelper.h>

@interface RAMakersController : SKTintedListController<SKListControllerProtocol, MFMailComposeViewControllerDelegate>
@end

@implementation RAMakersController
-(BOOL) showHeartImage { return NO; }
-(UIColor*) navigationTintColor { return [UIColor blackColor]; }
-(UIColor*) switchOnTintColor { return self.navigationTintColor; }
//-(UIColor*) iconColor { return self.navigationTintColor; }

-(NSString*) customTitle { return @"Creators"; }

- (id)customSpecifiers {
    return @[
             @{ @"cell": @"PSGroupCell", @"label": @"Developed and Designed by" },
             @{
                 @"cell": @"PSLinkCell",
                 //@"cellClass": @"RAElijahPersonCell",
                 @"height": @45,
                 @"action": @"openElijahTwitter",
                 @"label": @"Elijah Frederickson",
                 @"icon": @"elijah"
                 },
             @{
                 @"cell": @"PSLinkCell",
                 //@"cellClass": @"RAAndrewPersonCell",
                 @"height": @45,
                 @"action": @"openAndrewTwitter",
                 @"label": @"Andrew Abosh",
                 @"icon": @"andrew"
                 },

             @{ @"label": @"Beta tested by" },
             @{
                 @"cell": @"PSLinkCell",
                 @"action": @"openAndiTwitter",
                 @"label": @"Andi Andreas",
                 @"icon": @"Andi"
                 },
             @{
                 @"cell": @"PSLinkCell",
                 @"action": @"openBetaPage",
                 @"label": @"Beta382",
                 @"icon": @"beta382"
                 },
             @{
                 @"cell": @"PSLinkCell",
                 @"action": @"openBindersPAge",
                 @"label": @"BindersFullOfWomen",
                 @"icon": @"Binders"
                 },
             @{
                 @"cell": @"PSLinkCell",
                 @"action": @"openDavidTwitter",
                 @"label": @"David",
                 @"icon": @"David"
                 },
             @{
                 @"cell": @"PSLinkCell",
                 @"action": @"openJackTwitter",
                 @"label": @"Jack Haal",
                 @"icon": @"Jack"
                 },
             @{
                 @"cell": @"PSLinkCell",
                 @"action": @"openMosheTwitter",
                 @"label": @"Moshe Dancykier",
                 @"icon": @"Moshe"
                 },
             @{
                 @"cell": @"PSLinkCell",
                 @"action": @"openWilsonTwitter",
                 @"label": @"Wilson (TM3Dev)",
                 @"icon": @"Wilson"
                 },
             @{
                 @"cell": @"PSLinkCell",
                 @"action": @"openZiph0nTwitter",
                 @"label": @"Ziph0n",
                 @"icon": @"Ziphon"
                 },

            @{ @"label": @"Special Thanks To" },
             @{
                 @"cell": @"PSLinkCell",
                 @"action": @"openChonTwitter",
                 @"label": @"Chon Lee",
                 @"icon": @"Chon"
                 },
             @{
                 @"cell": @"PSLinkCell",
                 @"action": @"openEthanTwitter",
                 @"label": @"Ethan Arbuckle",
                 @"icon": @"EthanArbuckle"
                 },
             @{
                 @"cell": @"PSLinkCell",
                 @"action": @"openSharedRoutineTwitter",
                 @"label": @"sharedRoutine",
                 @"icon": @"SharedRoutine"
                 },

             @{ @"cell": @"PSGroupCell" },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Site",
                 @"action": @"openSite",
                 @"icon": @"ra_makers.png"
                 },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Source Code",
                 @"action": @"openGithub",
                 @"icon": @"github.png"
                 },

             @{ @"cell": @"PSGroupCell",
                @"footerText": @"Acknowledgments: \n\
\n\
This code thanks: \n\
ForceReach, Reference, MessageBox \n\
Previous research done by @b3ll and @freerunnering \n\
Pastie 8684110 \n\
OS Experience & Lamo\n\
\n\
A special thanks goes to those who contributed ideas, feature enhancements, bug reports, and who showed support. \n\
\n\
Crafted with love in 🇨🇦 and 🇺🇸. \n\
\n",
                },
             ];
}

-(void) openGithub
{
    [SKSharedHelper openGitHub:@"mlnlover11/Multiplexer"];
}

-(void) openElijahTwitter { [SKSharedHelper openTwitter:@"daementor"]; }
-(void) openAndrewTwitter { [SKSharedHelper openTwitter:@"drewplex"]; }
-(void) openAndiTwitter { [SKSharedHelper openTwitter:@"Nexuist"]; } 
-(void) openBetaPage { [UIApplication.sharedApplication openURL:[NSURL URLWithString:@"https://www.reddit.com/user/beta382"]]; }
-(void) openChonTwitter { [SKSharedHelper openTwitter:@"HikoMitsuketa"]; }
-(void) openDavidTwitter { [SKSharedHelper openTwitter:@"djaovx"]; }
-(void) openJackTwitter { [SKSharedHelper openTwitter:@"JackHaal"]; }
-(void) openMosheTwitter { [SKSharedHelper openTwitter:@"oniconpack"]; }
-(void) openBindersPAge { [UIApplication.sharedApplication openURL:[NSURL URLWithString:@"https://www.reddit.com/user/_BindersFullOfWomen_"]]; }
-(void) openWilsonTwitter { [SKSharedHelper openTwitter:@"xTM3x"]; }
-(void) openZiph0nTwitter { [SKSharedHelper openTwitter:@"ziph0n"]; }
-(void) openSharedRoutineTwitter { [SKSharedHelper openTwitter:@"sharedRoutine"]; }
-(void) openEthanTwitter { [SKSharedHelper openTwitter:@"its_not_herpes"]; }
-(void) openSite { [UIApplication.sharedApplication openURL:[NSURL URLWithString:@"https://elijahandandrew.com"]]; }
@end