#import "headers.h"
#import "RAMissionControlWindow.h"

@interface RAMissionControlManager : NSObject {
	RAMissionControlWindow *window;
	NSMutableArray *runningApplications;
}
+(instancetype) sharedInstance;

@property (nonatomic, readonly) BOOL isShowingMissionControl;

-(void) showMissionControl:(BOOL)animated;
-(void) hideMissionControl:(BOOL)animated;
-(void) toggleMissionControl:(BOOL)animated;

-(RAMissionControlWindow*) missionControlWindow;
@end