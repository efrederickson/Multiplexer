#import "RAAppKiller.h"

extern "C" void BKSTerminateApplicationForReasonAndReportWithDescription(NSString *app, int a, int b, NSString *description);

@implementation RAAppKiller : NSObject
+(void) killAppWithIdentifier:(NSString*)identifier
{
	return [RAAppKiller killAppWithIdentifier:identifier completion:nil];
}

+(void) killAppWithIdentifier:(NSString*)identifier completion:(void(^)())handler
{
	return [RAAppKiller killAppWithSBApplication:[[%c(SBApplicationController) sharedInstance] RA_applicationWithBundleIdentifier:identifier] completion:handler];
}

+(void) killAppWithSBApplication:(SBApplication*)app
{
	return [RAAppKiller killAppWithSBApplication:app completion:nil];
}

+(void) killAppWithSBApplication:(SBApplication*)app completion:(void(^)())handler
{
	return [RAAppKiller checkAppDead:app withTries:0 andCompletion:handler];
}

+(void) checkAppDead:(SBApplication*)app withTries:(int)tries andCompletion:(void(^)())handler
{
	BOOL isDeadOrMaxed = (app.pid == 0 || app.isRunning == NO) && tries < 5;
	if (isDeadOrMaxed)
	{
		if (handler)
		{
			handler();
		}
	}
	else 
	{
		if (tries == 0)
		{
			// Try nicely
			FBApplicationProcess *process = [[%c(FBProcessManager) sharedInstance] createApplicationProcessForBundleID:app.bundleIdentifier];
    		[process killForReason:1 andReport:NO withDescription:@"PSY SLAYED" completion:nil];
		}
		/*else if (tries == 1)
		{
			BKSTerminateApplicationForReasonAndReportWithDescription(app.bundleIdentifier, 5, 1, @"PSY SLAYED");
		}
		else if (tries == 2)
		{
			kill(app.pid, SIGTERM);
		}
		else
		{
			// Attempt force
			kill(app.pid, SIGKILL);
		}*/
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[RAAppKiller checkAppDead:app withTries:tries + 1 andCompletion:handler];
		});
	}
}
@end
