#import "RANCViewController.h"
#import "RAHostedAppView.h"
#import "RASettings.h"
#import "headers.h"

@interface SBNotificationCenterViewController <UITextFieldDelegate>
-(id)_newBulletinObserverViewControllerOfClass:(Class)aClass;
@end

@interface SBNotificationCenterLayoutViewController
@end

@interface SBModeViewController
-(void) _addBulletinObserverViewController:(id)arg1;
- (void)addViewController:(id)arg1;
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
%hook SBNotificationCenterLayoutViewController
- (void)_loadContentViewControllers
{
   	%orig;

   	BOOL hideBecauseLS = [[%c(SBLockScreenManager) sharedInstance] isUILocked] ? [RASettings.sharedInstance ncAppHideOnLS] : NO;

   	if ([RASettings.sharedInstance NCAppEnabled] && !hideBecauseLS)
   	{
		SBModeViewController* modeVC = MSHookIvar<id>(self, "_modeViewController");
		if (ncAppViewController == nil) 
			ncAppViewController = [[RANCViewController alloc] init];
		[modeVC _addBulletinObserverViewController:ncAppViewController];
	}
}
%end

// This is more of a hack than anything else. Note that `_localizableTitleForColumnViewController` on iOS 9 does not seem to work (I may be doing something else wrong)
// if more than one custom nc tab is added, this will not work correctly. 
%hook SBModeViewController
- (void)_layoutHeaderViewIfNecessary
{
	%orig;

	NSString *text = @"";
	BOOL useGenericLabel = THEMED(quickAccessUseGenericTabLabel) || [RASettings.sharedInstance quickAccessUseGenericTabLabel];
	if (useGenericLabel)
		text = LOCALIZE(@"APP");
	else
		text = ncAppViewController.hostedApp.displayName ?: getAppName() ?: LOCALIZE(@"APP");

	for (UIView *view in MSHookIvar<UIView*>(self, "_headerView").subviews)
	{
		if ([view isKindOfClass:[UISegmentedControl class]])
		{
			UISegmentedControl *segment = (UISegmentedControl*)view;
			if (segment.numberOfSegments > 2)
				[segment setTitle:text forSegmentAtIndex:2];
		}
	}
}
%end
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