#import "RAOrientationLocker.h"

@implementation RAOrientationLocker
+(void) lockOrientation
{
	if ([%c(SBUIController) instancesRespondToSelector:@selector(_lockOrientationForSwitcher)])
		[[%c(SBUIController) sharedInstance] _lockOrientationForSwitcher]; // iOS 8
	else // iOS 9
		[[%c(SBMainSwitcherGestureCoordinator) sharedInstance] _lockOrientation];
}

+(void) unlockOrientation
{
	if ([%c(SBUIController) instancesRespondToSelector:@selector(releaseSwitcherOrientationLock)])
		[[%c(SBUIController) sharedInstance] releaseSwitcherOrientationLock]; // iOS 8
	else // iOS 9
		[[%c(SBMainSwitcherGestureCoordinator) sharedInstance] _releaseOrientationLock];
}
@end