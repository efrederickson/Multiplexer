#import "headers.h"
#import "RARunningAppsProvider.h"

@class RAMissionControlManager;

@interface RAMissionControlWindow : UIAutoRotatingWindow  <RARunningAppsProviderDelegate>
@property (nonatomic, weak) RAMissionControlManager *manager;

-(void) reloadDesktopSection;
-(void) reloadWindowedAppsSection;
-(void) reloadWindowedAppsSection:(NSArray*)runningApplications;
-(void) reloadOtherAppsSection;

-(void) deconstructComponents;
@end