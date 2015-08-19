#import <Preferences/Preferences.h>

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