#import <libactivator/libactivator.h>
#import "RAMissionControlManager.h"
#import "RASettings.h"

@interface RAActivatorListener : NSObject <LAListener>
@end

static RAActivatorListener *sharedInstance;

@implementation RAActivatorListener
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event
{
	if ([RASettings.sharedInstance replaceAppSwitcherWithMC])
	{
		if (RAMissionControlManager.sharedInstance.isShowingMissionControl == NO)
			[[%c(SBUIController) sharedInstance] _activateAppSwitcher];
		else
			[RAMissionControlManager.sharedInstance hideMissionControl:YES];
	}
	else
	    [RAMissionControlManager.sharedInstance toggleMissionControl:YES];
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