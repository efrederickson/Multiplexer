#import <UIKit/UIKit.h>

enum RAGrabArea {
	RAGrabAreaBottomLeftThird = 1,
	RAGrabAreaBottomMiddleThird = 2,
	RAGrabAreaBottomRightThird = 3,

	RAGrabAreaSideAnywhere,
	RAGrabAreaSideTopThird,
	RAGrabAreaSideMiddleThird,
	RAGrabAreaSideBottomThird,
};

@interface RASettings : NSObject
+(instancetype)sharedInstance;

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
-(BOOL) snapRotation;
-(BOOL) launchIntoWindows;

-(NSInteger) globalBackgroundMode;
-(BOOL) backgrounderEnabled;
-(BOOL) shouldShowIconIndicatorsGlobally;
-(BOOL) showNativeStateIconIndicators;
-(NSDictionary*) rawCompiledBackgrounderSettingsForIdentifier:(NSString*)identifier;

-(BOOL) missionControlEnabled;
-(BOOL) replaceAppSwitcherWithMC;

-(BOOL) isFirstRun;
-(void) setFirstRun:(BOOL)value;

-(BOOL) swipeOverEnabled;
-(BOOL) alwaysShowSOGrabber;

-(BOOL) windowedMultitaskingEnabled;
-(RAGrabArea) windowedMultitaskingGrabArea;
-(RAGrabArea) swipeOverGrabArea;
@end 