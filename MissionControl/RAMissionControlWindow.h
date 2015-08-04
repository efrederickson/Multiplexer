#import "headers.h"

@class RAMissionControlManager;

@interface RAMissionControlWindow : UIAutoRotatingWindow
@property (nonatomic, weak) RAMissionControlManager *manager;

-(void) reloadDesktopSection;
-(void) reloadWindowedAppsSection;
-(void) reloadWindowedAppsSection:(NSArray*)runningApplications;
-(void) reloadOtherAppsSection;

-(void) deconstructComponents;
@end