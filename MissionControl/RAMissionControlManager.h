#import "headers.h"
#import "RAMissionControlWindow.h"
#import "RAGestureManager.h"

@interface RAMissionControlManager : NSObject<RAGestureCallbackProtocol> {
	RAMissionControlWindow *window;
	NSMutableArray *inhibitedApplications;
}
+(instancetype) sharedInstance;

@property (nonatomic, readonly) BOOL isShowingMissionControl;
@property (nonatomic) BOOL inhibitDismissalGesture;

-(void) createWindow;
-(void) showMissionControl:(BOOL)animated;
-(void) hideMissionControl:(BOOL)animated;
-(void) toggleMissionControl:(BOOL)animated;

-(void) inhibitApplication:(NSString*)identifer;
-(void) uninhibitApplication:(NSString*)identifer;
-(NSArray*) inhibitedApplications;
-(void) setInhibitedApplications:(NSArray*)icons;

-(RAMissionControlWindow*) missionControlWindow;
@end