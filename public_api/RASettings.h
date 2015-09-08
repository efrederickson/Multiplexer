#import <UIKit/UIKit.h>

// This exposes the entirety of the settings
// You can check any setting from nearly any process with this.

enum RAGrabArea {
	RAGrabAreaBottomLeftThird = 1,
	RAGrabAreaBottomMiddleThird = 2,
	RAGrabAreaBottomRightThird = 3,

	RAGrabAreaSideAnywhere = 6,
	RAGrabAreaSideTopThird = 7,
	RAGrabAreaSideMiddleThird = 8,
	RAGrabAreaSideBottomThird = 9,
};

@interface RASettings : NSObject
+(instancetype)sharedInstance;

+(BOOL) isParagonInstalled;
+(BOOL) isActivatorInstalled;
+(BOOL) isLibStatusBarInstalled;

-(void) reloadSettings;

-(BOOL) enabled;

-(BOOL) reachabilityEnabled;
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
-(BOOL) showFavorites;
-(BOOL) NCAppEnabled;
-(NSString*) NCApp;
-(BOOL) ncAppHideOnLS;
-(BOOL) alwaysEnableGestures;
-(BOOL) snapWindows;
-(BOOL) snapRotation;
-(BOOL) launchIntoWindows;
-(BOOL) windowedMultitaskingCompleteAnimations;
-(BOOL) openLinksInWindows;
-(BOOL) showSnapHelper;
-(NSInteger) globalBackgroundMode;
-(BOOL) shouldShowStatusBarIcons;
-(BOOL) shouldShowStatusBarNativeIcons;
-(BOOL) backgrounderEnabled;
-(BOOL) shouldShowIconIndicatorsGlobally;
-(BOOL) showNativeStateIconIndicators;
-(NSDictionary*) rawCompiledBackgrounderSettingsForIdentifier:(NSString*)identifier;
-(BOOL) missionControlEnabled;
-(BOOL) replaceAppSwitcherWithMC;
-(BOOL) missionControlKillApps;
-(NSInteger) missionControlDesktopStyle;
-(BOOL) missionControlPagingEnabled;
-(BOOL) isFirstRun;
-(void) setFirstRun:(BOOL)value;
-(BOOL) swipeOverEnabled;
-(BOOL) alwaysShowSOGrabber;
-(BOOL) exitAppAfterUsingActivatorAction;
-(BOOL) quickAccessUseGenericTabLabel;
-(BOOL) windowedMultitaskingEnabled;
-(NSInteger) windowRotationLockMode;
-(RAGrabArea) windowedMultitaskingGrabArea;
-(RAGrabArea) swipeOverGrabArea;
-(BOOL) onlyShowWindowBarIconsOnOverlay;
-(NSString*) currentThemeIdentifier;
@end 