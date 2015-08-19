#import <Preferences/Preferences.h>
#import <AppList/AppList.h>
#import <UIKit/UISearchBar2.h>
#import <substrate.h>
#import <RABackgrounder.h>
#import "BackgroundPerAppDetailsController.h"

@interface PSViewController (SettingsKit2)
-(UINavigationController*)navigationController;
-(void)viewWillAppear:(BOOL)animated;
-(void)viewWillDisappear:(BOOL)animated;
@end

@interface ALApplicationTableDataSource (Private)
- (void)sectionRequestedSectionReload:(id)section animated:(BOOL)animated;
@end

@interface ALLinkCell : ALValueCell
@end

@implementation ALLinkCell
-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if (!(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) return nil;
	self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return self;
}
@end

@interface PSViewController (Protean)
-(void) viewDidLoad;
-(void) viewWillDisappear:(BOOL)animated;
- (void)viewDidAppear:(BOOL)animated;
@end

BOOL reload = NO;
void RA_BGAppsControllerNeedsToReload()
{
    reload = YES;
}

@interface RABGPerAppController : PSViewController <UITableViewDelegate>
{
	UITableView* _tableView;
	ALApplicationTableDataSource* _dataSource;
}
@end

@implementation RABGPerAppController

-(void)updateDataSource:(NSString*)searchText
{
	NSNumber *iconSize = [NSNumber numberWithUnsignedInteger:ALApplicationIconSizeSmall];
    
	NSString *enabledList = @"";

    CFStringRef appID = CFSTR("com.efrederickson.reachapp.settings");
    CFArrayRef keyList = CFPreferencesCopyKeyList(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if (keyList) 
    {
        NSDictionary *prefs = (__bridge NSDictionary *)CFPreferencesCopyMultiple(keyList, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        CFRelease(keyList);
        if (prefs) 
        {
            NSArray *apps = [[ALApplicationList sharedApplicationList] applications].allKeys;
        	for (NSString* identifier in apps)
        	{
                if ([prefs[[NSString stringWithFormat:@"backgrounder-%@-enabled",identifier]] boolValue])
                {
                    enabledList = [enabledList stringByAppendingString:[NSString stringWithFormat:@"'%@',", identifier]];
                }
        	}
        }
    }
    enabledList = [enabledList stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
	NSString* filter = (searchText && searchText.length > 0) ? [NSString stringWithFormat:@"displayName beginsWith[cd] '%@'", searchText] : nil;
    
	if (filter)
	{
		_dataSource.sectionDescriptors = [NSArray arrayWithObjects:
                                          [NSDictionary dictionaryWithObjectsAndKeys:
                                           @"Search Results", ALSectionDescriptorTitleKey,
                                           @"ALLinkCell", ALSectionDescriptorCellClassNameKey,
                                           iconSize, ALSectionDescriptorIconSizeKey,
                                           @YES, ALSectionDescriptorSuppressHiddenAppsKey,
                                           filter, ALSectionDescriptorPredicateKey
                                           , nil]
                                          , nil];
	}
	else
	{
        if ([enabledList isEqual:@""])
        {
            _dataSource.sectionDescriptors = [NSArray arrayWithObjects:
                                          [NSDictionary dictionaryWithObjectsAndKeys:
                                           @"", ALSectionDescriptorTitleKey,
                                           @"ALLinkCell", ALSectionDescriptorCellClassNameKey,
                                           iconSize, ALSectionDescriptorIconSizeKey,
                                            @YES, ALSectionDescriptorSuppressHiddenAppsKey,
                                           [NSString stringWithFormat:@"not bundleIdentifier in {%@}", enabledList],
                                           ALSectionDescriptorPredicateKey
                                           , nil],
                                          nil];
        }
        else
        {
            _dataSource.sectionDescriptors = [NSArray arrayWithObjects:
                                          [NSDictionary dictionaryWithObjectsAndKeys:
                                           @"Enabled Applications", ALSectionDescriptorTitleKey,
                                           @"ALLinkCell", ALSectionDescriptorCellClassNameKey,
                                           iconSize, ALSectionDescriptorIconSizeKey,
                                           @YES, ALSectionDescriptorSuppressHiddenAppsKey,
                                           [NSString stringWithFormat:@"bundleIdentifier in {%@}", enabledList],
                                           ALSectionDescriptorPredicateKey
                                           , nil],
                                          [NSDictionary dictionaryWithObjectsAndKeys:
                                           @"Other Applications", ALSectionDescriptorTitleKey,
                                           @"ALLinkCell", ALSectionDescriptorCellClassNameKey,
                                           iconSize, ALSectionDescriptorIconSizeKey,
                                           @YES, ALSectionDescriptorSuppressHiddenAppsKey,
                                           [NSString stringWithFormat:@"not bundleIdentifier in {%@}", enabledList],
                                           ALSectionDescriptorPredicateKey
                                           , nil],
                                          nil];
        }
	}
    [_tableView reloadData];
}

-(id)init
{
	if (!(self = [super init])) return nil;
	
	CGRect bounds = [[UIScreen mainScreen] bounds];
	
	_dataSource = [[ALApplicationTableDataSource alloc] init];
    
	_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, bounds.size.height) style:UITableViewStyleGrouped];
	_tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_tableView.delegate = self;
	_tableView.dataSource = _dataSource;
	_dataSource.tableView = _tableView;
	[self updateDataSource:nil];
	
	return self;
}

-(void)viewDidLoad
{
	((UIViewController *)self).title = @"Applications";
	
	[self.view addSubview:_tableView];
    
	[super viewDidLoad];
}

-(void) viewWillAppear:(BOOL) animated
{
    if (reload)
    {
        [self updateDataSource:nil];
        reload = NO;
    }
    
    ((UIView*)self.view).tintColor = self.tintColor;
    self.navigationController.navigationBar.tintColor = self.tintColor;

    [super viewWillAppear:animated];
}


-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    
	// Need to mimic what PSListController does when it handles didSelectRowAtIndexPath
	// otherwise the child controller won't load
	RABGPerAppDetailsController *controller = [[RABGPerAppDetailsController alloc] initWithAppName:cell.textLabel.text identifier:[_dataSource displayIdentifierForIndexPath:indexPath]];
	controller.rootController = self.rootController;
	controller.parentController = self;
	
	[self pushController:controller];
	[tableView deselectRowAtIndexPath:indexPath animated:true];
}

-(UIColor*) tintColor { return [UIColor colorWithRed:248/255.0f green:73/255.0f blue:88/255.0f alpha:1.0f]; }

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    ((UIView*)self.view).tintColor = nil;
    self.navigationController.navigationBar.tintColor = nil;
}

@end