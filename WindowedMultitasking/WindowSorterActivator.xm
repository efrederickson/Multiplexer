#import <libactivator/libactivator.h>
#import "RADesktopManager.h"
#import "RADesktopWindow.h"
#import "RAHostedAppView.h"
#import "RAWindowBar.h"
#import "RAWindowSorter.h"

@interface RAActivatorSortWindowsListener : NSObject <LAListener>
@end

static RAActivatorSortWindowsListener *sharedInstance$RAActivatorSortWindowsListener;

@implementation RAActivatorSortWindowsListener
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event
{
    RADesktopWindow *desktop = RADesktopManager.sharedInstance.currentDesktop;

    [RAWindowSorter sortWindowsOnDesktop:desktop resizeIfNecessary:YES];
}
@end

%ctor
{
    if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"])
    {
        sharedInstance$RAActivatorSortWindowsListener = [[RAActivatorSortWindowsListener alloc] init];
        [[%c(LAActivator) sharedInstance] registerListener:sharedInstance$RAActivatorSortWindowsListener forName:@"com.efrederickson.reachapp.windowedmultitasking.sortWindows"];
    }
}


