#import "headers.h"

@protocol RARunningAppsProviderDelegate
-(void) appDidStart:(SBApplication*)app;
-(void) appDidDie:(SBApplication*)app;
@end

@interface RARunningAppsProvider : NSObject {
	NSMutableArray *apps;
	NSMutableArray *targets;
}
+(instancetype) sharedInstance;

-(void) addRunningApp:(SBApplication*)app;
-(void) removeRunningApp:(SBApplication*)app;

-(void) addTarget:(__weak NSObject<RARunningAppsProviderDelegate>*)target;
-(void) removeTarget:(__weak NSObject<RARunningAppsProviderDelegate>*)target;

-(NSArray*) runningApplications;
@end