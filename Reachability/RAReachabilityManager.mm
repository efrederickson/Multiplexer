#import <objc/runtime.h>
#import "RAReachabilityManager.h"
#import "headers.h"
#import "RAAppSliderProviderView.h"

@implementation RAReachabilityManager
+(id) sharedInstance
{
	static RAReachabilityManager *shared = nil;
	if (shared == nil)
		shared = [[RAReachabilityManager alloc] init];
	return shared;
}

-(void) launchTopAppWithIdentifier:(NSString*)identifier
{
	[[objc_getClass("SBWorkspace") sharedInstance] RA_launchTopAppWithIdentifier:identifier];
}

-(void) launchWidget:(RAWidget*)widget
{
	[[objc_getClass("SBWorkspace") sharedInstance] RA_setView:[widget view] preferredHeight:[widget preferredHeight]];
}

-(void) showWidgetSelector
{
	[[objc_getClass("SBWorkspace") sharedInstance] RA_showWidgetSelector];
}

-(void) showAppWithSliderProvider:(RAAppSliderProviderView*)view
{
	[view updateCurrentView];
	[view load];
	[[objc_getClass("SBWorkspace") sharedInstance] RA_setView:view preferredHeight:view.frame.size.height];
}
@end