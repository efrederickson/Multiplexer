@interface RAMissionControlManager : NSObject
+(instancetype) sharedInstance;

@property (nonatomic, readonly) BOOL isShowingMissionControl;

-(void) showMissionControl:(BOOL)animated;
-(void) hideMissionControl:(BOOL)animated;
-(void) toggleMissionControl:(BOOL)animated;
@end