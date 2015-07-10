#import <libactivator/libactivator.h>
#import "RAMissionControlManager.h"

// Haven't tested this, i don't even have activator

@interface RAActivatorListener : NSObject <LAListener>
@end

static RAActivatorListener *sharedInstance;

@implementation RAActivatorListener
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event
{
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