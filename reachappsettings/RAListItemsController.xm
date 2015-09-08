#import <Preferences/Preferences.h>
#import <SettingsKit/SKTintedListController.h>

@interface PSListItemsController (tableView)
- (void)tableView:(id)arg1 didSelectRowAtIndexPath:(id)arg2;
- (void)listItemSelected:(id)arg1;
- (id)tableView:(id)arg1 cellForRowAtIndexPath:(id)arg2;
@end

@interface RAListItemsController : PSListItemsController

@end

@implementation RAListItemsController
-(UIColor*) navigationTintColor { return [UIColor blackColor]; }

- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];

    self.navigationController.navigationBar.tintColor = self.navigationTintColor;
    [[UIApplication sharedApplication] keyWindow].tintColor = self.navigationTintColor;
}

- (void)viewWillDisappear:(BOOL)animated 
{
	[super viewWillDisappear:animated];
    
    [[UIApplication sharedApplication] keyWindow].tintColor = nil;
    self.navigationController.navigationBar.tintColor = nil;
}

-(NSArray*) specifiers
{
    if (!_specifiers) {
        PSSpecifier* themeSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Documentation"
                                        target:self
                                           set:NULL
                                           get:NULL
                                        detail:Nil
                                          cell:PSButtonCell
                                          edit:Nil];
        [themeSpecifier setProperty:RSIMG(@"tutorial.png") forKey:@"iconImage"];
        [themeSpecifier setProperty:@"poop" forKey:@"isTheming"];
        _specifiers = [super specifiers];
        [(NSMutableArray*)_specifiers addObject:[PSSpecifier emptyGroupSpecifier]];
        [(NSMutableArray*)_specifiers addObject:themeSpecifier];
    }
    return _specifiers;
}

-(void) openThemingDocumentation
{
    [UIApplication.sharedApplication openURL:[NSURL URLWithString:@"https://elijahandandrew.com/multiplexer/ThemingDocumentation.html"]];
}

-(void) tableView:(id)arg1 didSelectRowAtIndexPath:(id)arg2
{
    [super tableView:arg1 didSelectRowAtIndexPath:arg2];

    PSTableCell *cell = [self tableView:arg1 cellForRowAtIndexPath:arg2];
    if ([cell.specifier propertyForKey:@"isTheming"] != nil)
    {
        [self openThemingDocumentation];
    }
}
@end


@interface RABackgroundingListItemsController : PSListItemsController

@end

@implementation RABackgroundingListItemsController
-(UIColor*) navigationTintColor { return [UIColor colorWithRed:248/255.0f green:73/255.0f blue:88/255.0f alpha:1.0f]; }

- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];

    self.navigationController.navigationBar.tintColor = self.navigationTintColor;
    [[UIApplication sharedApplication] keyWindow].tintColor = self.navigationTintColor;
}

- (void)viewWillDisappear:(BOOL)animated 
{
	[super viewWillDisappear:animated];
    
    [[UIApplication sharedApplication] keyWindow].tintColor = nil;
    self.navigationController.navigationBar.tintColor = nil;
}
@end