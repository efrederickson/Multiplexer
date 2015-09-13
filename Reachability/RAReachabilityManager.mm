#import <objc/runtime.h>
#import "RAReachabilityManager.h"
#import "headers.h"
#import "RAAppSliderProviderView.h"
#import "RAMessagingServer.h"

@implementation RAReachabilityManager
+(id) sharedInstance
{
	SHARED_INSTANCE(RAReachabilityManager);
}

-(void) launchTopAppWithIdentifier:(NSString*)identifier
{
	[[objc_getClass("SBWorkspace") sharedInstance] RA_closeCurrentView];
	[[objc_getClass("SBWorkspace") sharedInstance] RA_launchTopAppWithIdentifier:identifier];
}

-(void) launchWidget:(RAWidget*)widget
{
	[[objc_getClass("SBWorkspace") sharedInstance] RA_closeCurrentView];
	[[objc_getClass("SBWorkspace") sharedInstance] RA_setView:[widget view] preferredHeight:[widget preferredHeight]];
}

-(void) showWidgetSelector
{
	[[objc_getClass("SBWorkspace") sharedInstance] RA_closeCurrentView];
	[[objc_getClass("SBWorkspace") sharedInstance] RA_showWidgetSelector];
}

-(void) showAppWithSliderProvider:(__weak RAAppSliderProviderView*)view
{
	[[objc_getClass("SBWorkspace") sharedInstance] RA_closeCurrentView];
	[view updateCurrentView];
	[view load];
	[[objc_getClass("SBWorkspace") sharedInstance] RA_setView:view preferredHeight:view.frame.size.height];
}
@end