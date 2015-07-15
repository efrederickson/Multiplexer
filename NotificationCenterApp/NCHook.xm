#import "RANCViewController.h"
#import "RAHostedAppView.h"

@interface SBNotificationCenterViewController <UITextFieldDelegate>
-(id)_newBulletinObserverViewControllerOfClass:(Class)aClass;
-(void) _addBulletinObserverViewController:(id)arg1;
@end

NSString *getAppName()
{
	SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:@"com.apple.Preferences"];
	return app ? app.displayName : nil;
}

RANCViewController *newViewController;

%hook SBNotificationCenterViewController
- (void)viewWillAppear:(BOOL)animated 
{
   	%orig;

	SBNotificationCenterViewController* modeVC = MSHookIvar<id>(self, "_modeController");
	if (newViewController == nil) 
		newViewController = [self _newBulletinObserverViewControllerOfClass:[RANCViewController class]];
	[modeVC _addBulletinObserverViewController:newViewController];
}

+ (NSString *)_localizableTitleForBulletinViewControllerOfClass:(Class)aClass
{
	if (aClass == [RANCViewController class]) 
		return newViewController.hostedApp.displayName ?: getAppName() ?: @"App";
	else 
		return %orig;
}
%end