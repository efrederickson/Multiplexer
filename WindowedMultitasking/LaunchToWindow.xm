#import "headers.h"
#import "RASettings.h"
#import "RADesktopManager.h"
#import "RADesktopWindow.h"

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)


BOOL override = NO;

%hook SBIconController
-(void)iconWasTapped:(SBApplicationIcon*)arg1 
{
	if ([RASettings.sharedInstance launchIntoWindows] && arg1.application)
	{
		[RADesktopManager.sharedInstance.currentDesktop createAppWindowForSBApplication:arg1.application animated:YES];
		override = YES;
	}
	%orig;
}

-(void)_launchIcon:(id)icon
{ 
	if (!override) 
		%orig;
	else 
		override = NO;
}
%end