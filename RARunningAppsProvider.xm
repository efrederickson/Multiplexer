#import "RARunningAppsProvider.h"

@implementation RARunningAppsProvider
+(instancetype) sharedInstance
{
	SHARED_INSTANCE2(RARunningAppsProvider, sharedInstance->apps = [NSMutableArray array]);
}

-(void) addRunningApp:(SBApplication*)app
{
	[apps addObject:app];
}

-(void) removeRunningApp:(SBApplication*)app
{
	[apps removeObject:app];
}

-(NSArray*) runningApplications { return apps; }
-(NSMutableArray*) mutableRunningApplications { return apps; }
@end

%hook SBApplication
- (void)updateProcessState:(unsafe_id)arg1
{
	%orig;

	if (self.isRunning && [RARunningAppsProvider.sharedInstance.mutableRunningApplications containsObject:self] == NO)
		[RARunningAppsProvider.sharedInstance addRunningApp:self];
	else if (!self.isRunning && [RARunningAppsProvider.sharedInstance.mutableRunningApplications containsObject:self])
		[RARunningAppsProvider.sharedInstance removeRunningApp:self];
}
%end