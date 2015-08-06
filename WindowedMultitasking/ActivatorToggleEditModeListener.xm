#import <libactivator/libactivator.h>
#import "RADesktopManager.h"
#import "RADesktopWindow.h"
#import "RAHostedAppView.h"
#import "RAWindowBar.h"

@interface RAActivatorToggleEditModeListener : NSObject <LAListener>
@end

static RAActivatorToggleEditModeListener *sharedInstance;

@implementation RAActivatorToggleEditModeListener
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event
{
    RADesktopWindow *desktop = RADesktopManager.sharedInstance.currentDesktop;

    for (RAWindowBar *view in desktop.subviews)
    {
    	if ([view isKindOfClass:[RAWindowBar class]])
    	{
	    	if (view.isOverlayShowing)
	    		[view hideOverlay];
	    	else
	    		[view showOverlay];
    	}

    }
}
@end

%ctor
{
    if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"])
    {
        sharedInstance = [[RAActivatorToggleEditModeListener alloc] init];
        [[%c(LAActivator) sharedInstance] registerListener:sharedInstance forName:@"com.efrederickson.reachapp.windowedmultitasking.toggleEditMode"];
    }
}