#import "RALockStateUpdater.h"
#import "headers.h"

@implementation RALockStateUpdater
+(id) sharedInstance
{
	SHARED_INSTANCE2(RALockStateUpdater, sharedInstance->dict = [NSMutableDictionary dictionary]);
}

-(void) addRequester:(void (^)(BOOL isLocked))block forIdentifier:(NSString*)ident
{
	dict[ident] = [block copy];
}

-(void) removeRequesterForIdentifier:(NSString*)ident
{
	[dict removeObjectForKey:ident];
}

-(void) _updateWithState:(BOOL)state
{
	if (lastState != state)
	{
		lastState = state;
		for (void (^block)(BOOL locked) in dict)
		{
			if (block)
				block(state);
		}
	}
}
@end

%hook SBLockStateAggregator
-(void) _updateLockState
{
    %orig;
    
    [RALockStateUpdater.sharedInstance _updateWithState:[self hasAnyLockState]];
}
%end