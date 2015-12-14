#import "RANCViewController.h"
#import "RAHostedAppView.h"
#import "RASettings.h"
#import "headers.h"

@interface SBNotificationCenterViewController <UITextFieldDelegate>
-(id)_newBulletinObserverViewControllerOfClass:(Class)aClass;
@end

@interface SBModeViewController
-(void) _addBulletinObserverViewController:(id)arg1;
@end

NSString *getAppName()
{
	NSString *ident = [RASettings.sharedInstance NCApp] ?: @"com.apple.Preferences";
	SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:ident];
	return app ? app.displayName : nil;
}

RANCViewController *ncAppViewController;

%group iOS8
%hook SBNotificationCenterViewController
- (void)viewWillAppear:(BOOL)animated 
{
   	%orig;

   	BOOL hideBecauseLS = [[%c(SBLockScreenManager) sharedInstance] isUILocked] ? [RASettings.sharedInstance ncAppHideOnLS] : NO;

   	if ([RASettings.sharedInstance NCAppEnabled] && !hideBecauseLS)
   	{
		SBModeViewController* modeVC = MSHookIvar<id>(self, "_modeController");
		if (ncAppViewController == nil) 
			ncAppViewController = [self _newBulletinObserverViewControllerOfClass:[RANCViewController class]];
		[modeVC _addBulletinObserverViewController:ncAppViewController];
	}
}

+ (NSString *)_localizableTitleForBulletinViewControllerOfClass:(__unsafe_unretained Class)aClass
{
	if (aClass == [RANCViewController class]) 
	{
		BOOL useGenericLabel = THEMED(quickAccessUseGenericTabLabel) || [RASettings.sharedInstance quickAccessUseGenericTabLabel];
		if (useGenericLabel)
			return LOCALIZE(@"APP");
		return ncAppViewController.hostedApp.displayName ?: getAppName() ?: LOCALIZE(@"APP");
	}
	else 
		return %orig;
}
%end
%end

%group iOS9
/*
%hook SBNotificationCenterLayoutViewController
- (void)viewWillAppear:(BOOL)animated 
{
   	%orig;

   	BOOL hideBecauseLS = [[%c(SBLockScreenManager) sharedInstance] isUILocked] ? [RASettings.sharedInstance ncAppHideOnLS] : NO;

   	if ([RASettings.sharedInstance NCAppEnabled] && !hideBecauseLS)
   	{
		SBModeViewController* modeVC = MSHookIvar<id>(self, "_modeViewController");
		if (ncAppViewController == nil) 
			ncAppViewController = [self _newBulletinObserverViewControllerOfClass:[RANCViewController class]];
		[modeVC _addBulletinObserverViewController:ncAppViewController];
	}
}

+ (NSString *)_localizableTitleForBulletinViewControllerOfClass:(__unsafe_unretained Class)aClass
{
	if (aClass == [RANCViewController class]) 
	{
		BOOL useGenericLabel = THEMED(quickAccessUseGenericTabLabel) || [RASettings.sharedInstance quickAccessUseGenericTabLabel];
		if (useGenericLabel)
			return LOCALIZE(@"APP");
		return ncAppViewController.hostedApp.displayName ?: getAppName() ?: LOCALIZE(@"APP");
	}
	else 
		return %orig;
}
%end
*/
%end

%ctor
{
	if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0"))
	{
		%init(iOS9);
	}
	else
	{
		%init(iOS8);
	}
}