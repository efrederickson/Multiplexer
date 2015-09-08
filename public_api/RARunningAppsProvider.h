@class SBApplication;

@protocol RARunningAppsProviderDelegate
@optional
-(void) appDidStart:(SBApplication*)app;
-(void) appDidDie:(SBApplication*)app;
@end

@interface RARunningAppsProvider : NSObject
+(instancetype) sharedInstance;

-(void) addTarget:(NSObject<RARunningAppsProviderDelegate>*)target;
-(void) removeTarget:(NSObject<RARunningAppsProviderDelegate>*)target;

-(NSArray*) runningApplications;
@end