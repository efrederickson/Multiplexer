#import <Preferences/Preferences.h>
#import <SettingsKit/SKListControllerProtocol.h>
#import <SettingsKit/SKTintedListController.h>
#import <SettingsKit/SKStandardController.h>
#import <SettingsKit/SKPersonCell.h>
#import <SettingsKit/SKSharedHelper.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>

@interface RASupportController : SKTintedListController<SKListControllerProtocol, MFMailComposeViewControllerDelegate>
@end
@interface PRElijahPersonCell : SKPersonCell
@end
@interface PRAndrewPersonCell : SKPersonCell
@end

@implementation PRElijahPersonCell
-(NSString*)personDescription { return @"The Developer"; }
-(NSString*)name { return @"Elijah Frederickson"; }
-(NSString*)imageName { return @"elijah.png"; }
@end

@implementation PRAndrewPersonCell
-(NSString*)personDescription { return @"The Designer"; }
-(NSString*)name { return @"Andrew Abosh"; }
-(NSString*)imageName { return @"andrew.png"; }
@end

@implementation RASupportController
-(BOOL) showHeartImage { return NO; }
-(UIColor*) navigationTintColor { return [UIColor colorWithRed:79/255.0f green:176/255.0f blue:136/255.0f alpha:1.0f]; }
-(UIColor*) switchOnTintColor { return self.navigationTintColor; }
-(UIColor*) iconColor { return self.navigationTintColor; }

-(NSString*) customTitle { return @"Credits"; }

- (id)customSpecifiers {
    return @[
             @{ @"cell": @"PSGroupCell" },
             @{
                 @"cell": @"PSLinkCell",
                 @"cellClass": @"PRElijahPersonCell",
                 @"height": @100,
                 @"action": @"openElijahTwitter"
                 },
             @{ @"cell": @"PSGroupCell" },
             @{
                 @"cell": @"PSLinkCell",
                 @"cellClass": @"PRAndrewPersonCell",
                 @"height": @100,
                 @"action": @"openAndrewTwitter"
                 },

             @{ @"cell": @"PSGroupCell" },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Source Code",
                 @"action": @"openGithub",
                 @"icon": [UIImage imageNamed:@"github.png" inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil]
                 },
             
             @{ @"cell": @"PSGroupCell" },
             @{
                 @"cell": @"PSButtonCell",
                 @"label": @"View the Tutorial",
                 @"action": @"showTutorial",
                 @"icon": @"tutorial.png"
                 },
             @{
                 @"cell": @"PSButtonCell",
                 @"label": @"View the FAQ",
                 @"action": @"showFAQ",
                 @"icon": @"tutorial.png"
                 },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Send Email",
                 @"action": @"showSupportDialog",
                 @"icon": [UIImage imageNamed:@"support_template.png" inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil]
                 },

             @{ @"cell": @"PSGroupCell",
                @"footerText": @"Acknowledgments: \n\
\n\
This code thanks: \n\
ForceReach, Reference, MessageBox \n\
Pastie 8684110 \n\
Various tips and help: @sharedRoutine \n\
Various concepts and help & Mirmir: Ethan Arbuckle (@its_not_herpes) \n\
\n\
There was much knowledge to be gained from perusing those sources, however no copyright infringement occured. \n\
\n\
\n\
Beta Testers:\n\
Person 1\n\
Person 2\n\
\n\
\n\
And thanks to all who tested beta versions and/or reported feedback. \n\
Also, a special thanks goes to those who contributed ideas, feature enhancements, bug reports, and the like. \n\
\n",
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

-(void) openGithub
{
    [SKSharedHelper openGitHub:@"mlnlover11/Multiplexer"];
}

-(void) openElijahTwitter
{
    [SKSharedHelper openTwitter:@"daementor"];
}

-(void) openAndrewTwitter
{
    [SKSharedHelper openTwitter:@"drewplex"];
}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error{
    [self dismissViewControllerAnimated:YES completion:NULL];
}
@end