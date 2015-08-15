#import "headers.h"
#import "RASettings.h"
#import "RADesktopManager.h"
#import "RADesktopWindow.h"

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

BOOL launchNextOpenIntoWindow = NO;
BOOL override = NO;
BOOL allowOpenApp = NO;

%hook SBIconController
-(void)iconWasTapped:(__unsafe_unretained SBApplicationIcon*)arg1 
{
	if ([RASettings.sharedInstance launchIntoWindows] && arg1.application)
	{
		[RADesktopManager.sharedInstance.currentDesktop createAppWindowForSBApplication:arg1.application animated:YES];
		override = YES;
	}
	%orig;
}

-(void)_launchIcon:(unsafe_id)icon
{
	if (!override) 
		%orig;
	else 
		override = NO;
}
%end

%hook SBUIController
- (void)activateApplicationAnimated:(__unsafe_unretained SBApplication*)arg1
{
	// Broken
	//if (launchNextOpenIntoWindow)

	if ([RASettings.sharedInstance launchIntoWindows] && allowOpenApp != YES)
	{
		[RADesktopManager.sharedInstance.currentDesktop createAppWindowForSBApplication:arg1 animated:YES];
		//launchNextOpenIntoWindow = NO;
		return;
	}
	%orig;
}
%end
