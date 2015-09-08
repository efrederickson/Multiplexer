#import "RARunningAppsProvider.h"

@implementation RARunningAppsProvider
+(instancetype) sharedInstance
{
	SHARED_INSTANCE2(RARunningAppsProvider, 
		sharedInstance->apps = [NSMutableArray array]; 
		sharedInstance->targets = [NSMutableArray array];
		sharedInstance->lock = [[NSLock alloc] init];
	);
}

-(void) addRunningApp:(__unsafe_unretained SBApplication*)app
{
	[lock lock];

	[apps addObject:app];
	for (NSObject<RARunningAppsProviderDelegate>* target in targets)
		if ([target respondsToSelector:@selector(appDidStart:)])
    		dispatch_async(dispatch_get_main_queue(), ^{
				[target appDidStart:app];
			});

	[lock unlock];
}

-(void) removeRunningApp:(__unsafe_unretained SBApplication*)app
{
	[lock lock];

	[apps removeObject:app];

	for (NSObject<RARunningAppsProviderDelegate>* target in targets)
		if ([target respondsToSelector:@selector(appDidDie:)])
 	   		dispatch_async(dispatch_get_main_queue(), ^{
				[target appDidDie:app];
			});

	[lock unlock];
}

-(void) addTarget:(__weak NSObject<RARunningAppsProviderDelegate>*)target
{
	[lock lock];

	if ([targets containsObject:target] == NO)
		[targets addObject:target];

	[lock unlock];
}

-(void) removeTarget:(__weak NSObject<RARunningAppsProviderDelegate>*)target
{
	[lock lock];

	[targets removeObject:target];

	[lock unlock];
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