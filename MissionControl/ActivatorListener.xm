#import <libactivator/libactivator.h>
#import "RAMissionControlManager.h"

// Haven't tested this, i don't even have activator

@interface RAActivatorListener : NSObject <LAListener>
@end

static RAActivatorListener *sharedInstance;

@implementation RAActivatorListener
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event
{
	if (RAMissionControlManager.sharedInstance.isShowingMissionControl == NO)
	{
		FBWorkspaceEvent *event = [%c(FBWorkspaceEvent) eventWithName:@"ActivateSpringBoard" handler:^{
			SBAppToAppWorkspaceTransaction *transaction = [[%c(SBAppToAppWorkspaceTransaction) alloc] initWithAlertManager:nil exitedApp:UIApplication.sharedApplication._accessibilityFrontMostApplication];
			[transaction begin];
		}];
		[(FBWorkspaceEventQueue*)[%c(FBWorkspaceEventQueue) sharedInstance] executeOrAppendEvent:event];
	}
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