#import <UIKit/UIKit.h>

@interface RASettings : NSObject
+(id)sharedInstance;

-(void) reloadSettings;

-(BOOL) enabled;
-(BOOL) disableAutoDismiss;
-(BOOL) enableRotation;
-(BOOL) showNCInstead;
-(BOOL) homeButtonClosesReachability;
-(BOOL) showBottomGrabber;
-(BOOL) showWidgetSelector;
-(BOOL) scalingRotationMode;
-(BOOL) autoSizeWidgetSelector;
-(BOOL) showAllAppsInWidgetSelector;
-(BOOL) showRecentAppsInWidgetSelector;
-(BOOL) pagingEnabled;
-(NSMutableArray*) favoriteApps;
-(BOOL) unifyStatusBar;
-(BOOL) flipTopAndBottom;

-(NSString*) NCApp;

-(BOOL) alwaysEnableGestures;
-(BOOL) snapWindows;
-(BOOL) launchIntoWindows;

-(BOOL) backgrounderEnabled;
-(BOOL) shouldShowIconIndicatorsGlobally;
-(BOOL) showNativeStateIconIndicators;
-(NSDictionary*) rawCompiledBackgrounderSettingsForIdentifier:(NSString*)identifier;

-(BOOL) isFirstRun;
-(void) setFirstRun:(BOOL)value;

-(BOOL) alwaysShowSOGrabber;
@end 