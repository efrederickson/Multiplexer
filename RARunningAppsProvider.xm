#import "RARunningAppsProvider.h"

@implementation RARunningAppsProvider
+(instancetype) sharedInstance
{
	SHARED_INSTANCE2(RARunningAppsProvider, 
		sharedInstance->apps = [NSMutableArray array]; 
		sharedInstance->targets = [NSMutableArray array];
	);
}

-(void) addRunningApp:(SBApplication*)app
{
	@synchronized(apps) { @synchronized(targets) {
		[apps addObject:app];

		for (NSObject<RARunningAppsProviderDelegate>* target in targets)
			if ([target respondsToSelector:@selector(appDidStart:)])
				[target appDidStart:app];
	}}
}

-(void) removeRunningApp:(SBApplication*)app
{
	@synchronized(apps) { @synchronized(targets) {
		[apps removeObject:app];

		for (NSObject<RARunningAppsProviderDelegate>* target in targets)
			if ([target respondsToSelector:@selector(appDidDie:)])
				[target appDidDie:app];
	}}
}

-(void) addTarget:(__weak NSObject<RARunningAppsProviderDelegate>*)target
{
	@synchronized(apps) { @synchronized(targets) {
		if ([targets containsObject:target] == NO)
			[targets addObject:target];
	}}
}

-(void) removeTarget:(__weak NSObject<RARunningAppsProviderDelegate>*)target
{
	@synchronized(apps) { @synchronized(targets) {
		[targets removeObject:target];
	}}
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