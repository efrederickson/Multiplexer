#import <Preferences/Preferences.h>
#import <SettingsKit/SKListControllerProtocol.h>
#import <SettingsKit/SKTintedListController.h>
#import <SettingsKit/SKStandardController.h>
#import <SettingsKit/SKPersonCell.h>
#import <SettingsKit/SKSharedHelper.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>

@interface RAMiniPersonCell : PSTableCell { // SKPersonCell
    UIImageView *_background;
    UILabel *label;
    UILabel *label2;
}

-(NSString*)personDescription;
-(NSString*)imageName;
-(NSString*)name;
-(NSString*)twitterHandle;

-(void)updateImage;
-(NSString*)localizedString:(NSString*)string;
@end


@implementation RAMiniPersonCell
-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])){
        UIImage *bkIm = [UIImage imageNamed:self.imageName inBundle:[NSBundle bundleForClass:self.class]];
        _background = [[UIImageView alloc] initWithImage:bkIm];
        _background.frame = CGRectMake(9, 3, 34, 34);
        [self addSubview:_background];
        
        CGRect frame = [self frame];
        
        label = [[UILabel alloc] initWithFrame:CGRectMake(9 + 34 + 5, 3, frame.size.width, frame.size.height - 6)];
        [label setText:LCL(self.name)];
        [label setBackgroundColor:[UIColor clearColor]];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            [label setFont:[UIFont fontWithName:@"Helvetica Light" size:15]];
        else
            [label setFont:[UIFont fontWithName:@"HelveticaNeue" size:15]];
        //[label setTextColor:[UIColor colorWithRed:73/255.0f green:73/255.0f blue:73/255.0f alpha:1.0f]];
    [label sizeToFit];
        [self addSubview:label];
        
        label2 = [[UILabel alloc] initWithFrame:CGRectMake(frame.origin.x + 84, frame.origin.y + 42, frame.size.width, frame.size.height)];
        [label2 setText:LCL(self.personDescription)];
        [label2 setBackgroundColor:[UIColor clearColor]];
        [label2 setFont:[UIFont fontWithName:@"Helvetica" size:15]];
        [label2 setTextColor:[UIColor colorWithRed:115/255.0f green:115/255.0f blue:115/255.0f alpha:1.0f]];
        [label2 sizeToFit];
        label2.frame = CGRectMake(frame.size.width - label2.frame.size.width - 10, (frame.size.height - label2.frame.size.height) / 2, label2.frame.size.width, label2.frame.size.height);
        [self addSubview:label2];
    }
    return self;
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    CGRect frame = self.frame;
    CGFloat imgSize = self.frame.size.height - 10;
    _background.frame = CGRectMake(18, 5, imgSize, imgSize);
    label.frame = CGRectMake(_background.frame.origin.x + _background.frame.size.width + 15, (frame.size.height - label.frame.size.height) / 2, label.frame.size.width, label.frame.size.height);
    label2.frame = CGRectMake(frame.size.width - label2.frame.size.width - 40, (frame.size.height - label2.frame.size.height) / 2, label2.frame.size.width, label2.frame.size.height);
}

-(NSString*)personDescription { return @""; }
-(NSString*)imageName { return @""; }
-(NSString*)name { return @""; }
-(NSString*)twitterHandle { return @""; }

-(void)updateImage
{
    UIImage *bkIm = [UIImage imageNamed:self.imageName inBundle:[NSBundle bundleForClass:self.class]];
    _background.image = bkIm;
}

-(NSString*)localizedString:(NSString*)string
{
    return [[(PSListController*)self.superview bundle] localizedStringForKey:string value:string table:nil] ?: string;
}

@end
@interface RAMakersController : SKTintedListController<SKListControllerProtocol, MFMailComposeViewControllerDelegate>
@end
@interface RAElijahPersonCell : RAMiniPersonCell
@end
@interface RAAndrewPersonCell : RAMiniPersonCell
@end

@implementation RAElijahPersonCell
-(NSString*)personDescription { return @"@daementor"; }
-(NSString*)name { return @"Elijah Frederickson"; }
-(NSString*)imageName { return @"elijah.png"; }
@end

@implementation RAAndrewPersonCell
-(NSString*)personDescription { return @"@drewplex"; }
-(NSString*)name { return @"Andrew Abosh"; }
-(NSString*)imageName { return @"andrew.png"; }
@end

@implementation RAMakersController
-(BOOL) showHeartImage { return NO; }
-(UIColor*) navigationTintColor { return [UIColor blackColor]; }
-(UIColor*) switchOnTintColor { return self.navigationTintColor; }
-(UIColor*) iconColor { return self.navigationTintColor; }

-(NSString*) customTitle { return @"Creators"; }

- (id)customSpecifiers {
    return @[
             @{ @"cell": @"PSGroupCell", @"label": @"Developer" },
             @{
                 @"cell": @"PSLinkCell",
                 @"cellClass": @"RAElijahPersonCell",
                 @"height": @45,
                 @"action": @"openElijahTwitter"
                 },
             @{ @"cell": @"PSGroupCell", @"label": @"Designer" },
             @{
                 @"cell": @"PSLinkCell",
                 @"cellClass": @"RAAndrewPersonCell",
                 @"height": @45,
                 @"action": @"openAndrewTwitter"
                 },

             @{ @"cell": @"PSGroupCell" },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Source Code",
                 @"action": @"openGithub",
                 @"icon": RSIMG(@"github.png")
                 },

             @{ @"cell": @"PSGroupCell",
                @"footerText": @"Acknowledgments: \n\
\n\
This code thanks: \n\
ForceReach, Reference, MessageBox \n\
Pastie 8684110 \n\
Various tips and help: @sharedRoutine \n\
Various concepts and help & Mirmir: Ethan Arbuckle \n\
\n\
There was much knowledge to be gained from perusing those sources, however no copyright infringement occured. \n\
\n\
\n\
Beta Testers:\n\
Beta382\n\
Bindersfullofwoman\n\
Djaovx\n\
Moshed\n\
Nexuist\n\
TM3Dev\n\
JackHaal\n\
\n\
\n\
And thanks to all who tested beta versions and/or reported feedback. \n\
Also, a special thanks goes to those who contributed ideas, feature enhancements, bug reports, and the like. \n\
\n",
                },
             ];
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
@end