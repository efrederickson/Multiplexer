#import "headers.h"
#import "RAMissionControlWindow.h"
#import "RAGestureManager.h"

@interface RAMissionControlManager : NSObject<RAGestureCallbackProtocol> {
	RAMissionControlWindow *window;
}
+(instancetype) sharedInstance;

@property (nonatomic, readonly) BOOL isShowingMissionControl;
@property (nonatomic) BOOL inhibitDismissalGesture;

-(void) createWindow;
-(void) showMissionControl:(BOOL)animated;
-(void) hideMissionControl:(BOOL)animated;
-(void) toggleMissionControl:(BOOL)animated;

-(RAMissionControlWindow*) missionControlWindow;
@end