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

+(BOOL) isParagonInstalled;
+(BOOL) isActivatorInstalled;
+(BOOL) isLibStatusBarInstalled;

-(void) reloadSettings;
-(void) resetSettings;

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

#if DEBUG
-(BOOL) debug_showIPCMessages;
#endif

-(BOOL) windowedMultitaskingEnabled;
-(NSInteger) windowRotationLockMode;
-(RAGrabArea) windowedMultitaskingGrabArea;
-(RAGrabArea) swipeOverGrabArea;
-(BOOL) onlyShowWindowBarIconsOnOverlay;

-(NSString*) currentThemeIdentifier;
@end 