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