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
	else if ([RASettings.sharedInstance missionControlEnabled])
	{
	    [RAMissionControlManager.sharedInstance toggleMissionControl:YES];
		[[[%c(SBUIController) sharedInstance] _appSwitcherController] forceDismissAnimated:NO];
	}
    [event setHandled:YES];
}
@end

%ctor
{
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"])
    {
        sharedInstance = [[RAActivatorListener alloc] init];
        [[%c(LAActivator) sharedInstance] registerListener:sharedInstance forName:@"com.efrederickson.reachapp.missioncontrol.activatorlistener"];
    }
}