#import "headers.h"
#import "RAMissionControlWindow.h"
#import "RAGestureManager.h"

@interface RAMissionControlManager : NSObject<RAGestureCallbackProtocol> {
	RAMissionControlWindow *window;
	NSMutableArray *runningApplications;
}
+(instancetype) sharedInstance;

@property (nonatomic, readonly) BOOL isShowingMissionControl;

-(void) createWindow;
-(void) showMissionControl:(BOOL)animated;
-(void) hideMissionControl:(BOOL)animated;
-(void) toggleMissionControl:(BOOL)animated;

-(RAMissionControlWindow*) missionControlWindow;
@end