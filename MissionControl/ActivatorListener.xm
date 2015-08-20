#import <libactivator/libactivator.h>
#import "RAMissionControlManager.h"
#import "RASettings.h"

@interface RAActivatorListener : NSObject <LAListener>
@end

static RAActivatorListener *sharedInstance;

@implementation RAActivatorListener
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event
{
	if ([[%c(SBLockScreenManager) sharedInstance] isUILocked])
		return;
		
	if ([RASettings.sharedInstance replaceAppSwitcherWithMC] && [RASettings.sharedInstance missionControlEnabled])
	{
		if (RAMissionControlManager.sharedInstance.isShowingMissionControl == NO)
			[[%c(SBUIController) sharedInstance] _activateAppSwitcher];
		else
			[RAMissionControlManager.sharedInstance hideMissionControl:YES];
	}
	else if ([RASettings.sharedInstance missionControlEnabled])
	{
		[[[%c(SBUIController) sharedInstance] _appSwitcherController] forceDismissAnimated:YES];
	    [RAMissionControlManager.sharedInstance toggleMissionControl:YES];
	}
    [event setHandled:YES];
}
@end

%ctor
{
    if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"])
    {
        sharedInstance = [[RAActivatorListener alloc] init];
        [[%c(LAActivator) sharedInstance] registerListener:sharedInstance forName:@"com.efrederickson.reachapp.missioncontrol.activatorlistener"];
    }
}