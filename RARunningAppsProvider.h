#import "headers.h"

@interface RARunningAppsProvider : NSObject {
	NSMutableArray *apps;
}
+(instancetype) sharedInstance;

-(void) addRunningApp:(SBApplication*)app;
-(void) removeRunningApp:(SBApplication*)app;

-(NSArray*) runningApplications;
@end