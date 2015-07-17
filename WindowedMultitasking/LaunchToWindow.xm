#import "headers.h"
#import "RASettings.h"
#import "RADesktopManager.h"
#import "RADesktopWindow.h"

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)


// Data from http://iphonedevwiki.net/index.php/SBIconView#SBIconViewLocation

%hook SBIcon
- (void)launchFromLocation:(int)arg1
{
	BOOL isProbablyHS = YES;// SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"8.3") ? arg1 == 0 : arg1 == 1;

	if (isProbablyHS && [RASettings.sharedInstance launchIntoWindows] && self.application)
	{
		[RADesktopManager.sharedInstance.currentDesktop createAppWindowForSBApplication:self.application animated:YES];
	}
	else
		%orig;
}
%end