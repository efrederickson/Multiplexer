#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBIconModel.h>
#import <SpringBoard/SBIcon.h>
#import <SpringBoard/SBIconController.h>
#import <SpringBoard/SBApplicationIcon.h>
#import <SpringBoard/SBIconImageView.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIImageView.h>
#import <SpringBoard/SBIconLabel.h>
#import <SpringBoard/SBApplication.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <SpringBoard/SBApplication.h>
#include <mach/mach.h>
#include <libkern/OSCacheControl.h>
#include <stdbool.h>
#include <dlfcn.h>
#include <sys/sysctl.h>
#import <notify.h>
#import <IOKit/hid/IOHIDEvent.h>

#import "RALocalizer.h"
#define LOCALIZE(x) [RALocalizer.sharedInstance localizedStringForKey:x]

#if DEBUG
#define NSLog NSLog
#else
#define NSLog 
#endif

#define IS_SPRINGBOARD [NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"]
#define IF_SPRINGBOARD if (IS_SPRINGBOARD)
#define IF_THIS_PROCESS(x) if ([[x objectForKey:@"bundleIdentifier"] isEqual:NSBundle.mainBundle.bundleIdentifier])

// ugh, i got so tired of typing this in by hand, plus it expands method declarations by a LOT.
#define unsafe_id __unsafe_unretained id

#define kBGModeUnboundedTaskCompletion @"unboundedTaskCompletion"
#define kBGModeContinuous              @"continuous"
#define kBGModeFetch                   @"fetch"
#define kBGModeRemoteNotification      @"remote-notification"
#define kBGModeExternalAccessory       @"external-accessory"
#define kBGModeVoIP                    @"voip"
#define kBGModeLocation                @"location"
#define kBGModeAudio                   @"audio"
#define kBGModeBluetoothCentral        @"bluetooth-central"
#define kBGModeBluetoothPeripheral     @"bluetooth-peripheral"
// newsstand-content

extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(radians) ((radians) * (M_PI / 180))

void SET_BACKGROUNDED(id settings, BOOL val);

#define SHARED_INSTANCE2(cls, extracode) \
static cls *sharedInstance = nil; \
static dispatch_once_t onceToken = 0; \
dispatch_once(&onceToken, ^{ \
    sharedInstance = [[cls alloc] init]; \
    extracode; \
}); \
return sharedInstance;

#define SHARED_INSTANCE(cls) SHARED_INSTANCE2(cls, );

extern "C" void BKSHIDServicesCancelTouchesOnMainDisplay();



@interface UIScreen (ohBoy)
-(CGRect) _interfaceOrientedBounds;
@end

@interface UIAutoRotatingWindow : UIWindow
- (instancetype)_initWithFrame:(CGRect)arg1 attached:(BOOL)arg2;
- (void)updateForOrientation:(UIInterfaceOrientation)arg1;
@end

@interface LSApplicationProxy
+ (id)applicationProxyForIdentifier:(id)arg1;
- (NSArray*) UIBackgroundModes;
@property (nonatomic, readonly) NSURL *appStoreReceiptURL;
@property (nonatomic, readonly) NSURL *bundleContainerURL;
@property (nonatomic, readonly) NSURL *bundleURL;
@end

@interface UIViewController ()
- (void)setInterfaceOrientation:(UIInterfaceOrientation)arg1;
- (void)_setInterfaceOrientationOnModalRecursively:(int)arg1;
- (void)_updateInterfaceOrientationAnimated:(BOOL)arg1;
@end

@interface SBWallpaperController
+(id) sharedInstance;
-(void) beginRequiringWithReason:(NSString*)reason;
@end

@interface BBAction
+ (id)actionWithCallblock:(id /* block */)arg1;
@end

typedef enum
{
    NSNotificationSuspensionBehaviorDrop = 1,
    NSNotificationSuspensionBehaviorCoalesce = 2,
    NSNotificationSuspensionBehaviorHold = 3,
    NSNotificationSuspensionBehaviorDeliverImmediately = 4
} NSNotificationSuspensionBehavior;

@interface NSDistributedNotificationCenter : NSNotificationCenter
+ (instancetype)defaultCenter;
- (void)addObserver:(id)notificationObserver selector:(SEL)notificationSelector name:(NSString *)notificationName object:(NSString *)notificationSender suspensionBehavior:(NSNotificationSuspensionBehavior)suspendedDeliveryBehavior;
- (void)removeObserver:(id)notificationObserver name:(NSString *)notificationName object:(NSString *)notificationSender;
- (void)postNotificationName:(NSString *)notificationName object:(NSString *)notificationSender userInfo:(NSDictionary *)userInfo deliverImmediately:(BOOL)deliverImmediately;
@end

@interface SBLockStateAggregator
-(void) _updateLockState;
-(BOOL) hasAnyLockState;
@end

@interface BBBulletinRequest : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *sectionID;
@property (nonatomic, copy) BBAction *defaultAction;
@property (nonatomic, copy) NSDate *date;
@end

@interface SBBulletinBannerController : NSObject
+ (SBBulletinBannerController *)sharedInstance;
- (void)observer:(id)observer addBulletin:(BBBulletinRequest *)bulletin forFeed:(int)feed;
-(void) observer:(id)observer addBulletin:(BBBulletinRequest*) bulletin forFeed:(int)feed playLightsAndSirens:(BOOL)guess1 withReply:(id)guess2;
@end

@interface SBAppSwitcherWindow : UIWindow
@end

@interface SBChevronView : UIView
-(void) setState:(int)state animated:(BOOL)animated;
@end

@interface SBControlCenterGrabberView : UIView
-(SBChevronView*) chevronView;
- (void)_setStatusState:(int)arg1;
@end

@interface SBAppSwitcherController
- (void)forceDismissAnimated:(_Bool)arg1;
@end

@interface SBUIController : NSObject
+(id) sharedInstance;
+ (id)_zoomViewWithSplashboardLaunchImageForApplication:(id)arg1 sceneID:(id)arg2 screen:(id)arg3 interfaceOrientation:(long long)arg4 includeStatusBar:(_Bool)arg5 snapshotFrame:(struct CGRect *)arg6;
-(id) switcherController;
- (id)_appSwitcherController;
-(void) activateApplicationAnimated:(SBApplication*)app;
- (id)switcherWindow;
- (void)_animateStatusBarForSuspendGesture;
- (void)_showControlCenterGestureCancelled;
- (void)_showControlCenterGestureFailed;
- (void)_hideControlCenterGrabber;
- (void)_showControlCenterGestureEndedWithLocation:(CGPoint)arg1 velocity:(CGPoint)arg2;
- (void)_showControlCenterGestureChangedWithLocation:(CGPoint)arg1 velocity:(CGPoint)arg2 duration:(CGFloat)arg3;
- (void)_showControlCenterGestureBeganWithLocation:(CGPoint)arg1;
- (void)restoreContentUpdatingStatusBar:(_Bool)arg1;
-(void) restoreContentAndUnscatterIconsAnimated:(BOOL)arg1;
- (_Bool)shouldShowControlCenterTabControlOnFirstSwipe;- (_Bool)isAppSwitcherShowing;
@end

@interface SBDisplayItem : NSObject <NSCopying>
+ (id)displayItemWithType:(NSString *)arg1 displayIdentifier:(id)arg2;
@end

@interface SBLockScreenManager
+(id) sharedInstance;
-(BOOL) isUILocked;
@end

@interface BKSWorkspace : NSObject
- (NSString *)topActivatingApplication;
@end

@interface SpringBoard (OrientationSupport)
- (UIInterfaceOrientation)activeInterfaceOrientation;
- (void)noteInterfaceOrientationChanged:(UIInterfaceOrientation)orientation;
@end

typedef struct {
    int type;
    int modifier;
    NSUInteger pathIndex;
    NSUInteger pathIdentity;
    CGPoint location;
    CGPoint previousLocation;
    CGPoint unrotatedLocation;
    CGPoint previousUnrotatedLocation;
    double totalDistanceTraveled;
    UIInterfaceOrientation interfaceOrientation;
    UIInterfaceOrientation previousInterfaceOrientation;
    double timestamp;
    BOOL isValid;
} SBActiveTouch;

typedef NS_ENUM(NSInteger, UIScreenEdgePanRecognizerType) {
    UIScreenEdgePanRecognizerTypeMultitasking,
    UIScreenEdgePanRecognizerTypeNavigation,
    UIScreenEdgePanRecognizerTypeOther
};

@protocol _UIScreenEdgePanRecognizerDelegate;

@interface _UIScreenEdgePanRecognizer : NSObject
- (id)initWithType:(UIScreenEdgePanRecognizerType)type;
- (void)incorporateTouchSampleAtLocation:(CGPoint)location timestamp:(double)timestamp modifier:(NSInteger)modifier interfaceOrientation:(UIInterfaceOrientation)orientation;
- (void)reset;
@property (nonatomic, assign) id <_UIScreenEdgePanRecognizerDelegate> delegate;
@property (nonatomic, readonly) NSInteger state;
@property (nonatomic) UIRectEdge targetEdges;
@property (nonatomic) CGRect screenBounds;
@end

@protocol _UIScreenEdgePanRecognizerDelegate <NSObject>
@optional
- (void)screenEdgePanRecognizerStateDidChange:(_UIScreenEdgePanRecognizer *)screenEdgePanRecognizer;
@end

@interface UIDevice (UIDevicePrivate)
- (void)setOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated;
@end

@interface _UIBackdropViewSettings : NSObject
@property (nonatomic) CGFloat grayscaleTintAlpha;
@property (nonatomic) CGFloat grayscaleTintLevel;
@end

@interface _UIBackdropView : UIView
@property (retain, nonatomic) _UIBackdropViewSettings *outputSettings;
@property (retain, nonatomic) _UIBackdropViewSettings *inputSettings;
-(void) setBlurRadius:(CGFloat)radius;
-(void) setBlurRadiusSetOnce:(BOOL)v;
@end

@interface SBOffscreenSwipeGestureRecognizer : NSObject // SBPanGestureRecognizer <_UIScreenEdgePanRecognizerDelegate>
-(id) initForOffscreenEdge:(int)edge;
-(void) setTypes:(NSInteger)types;
-(void) setMinTouches:(NSInteger)amount;
-(void) setHandler:(id)arg;
-(void) setCanBeginCondition:(id)arg;
-(void) setShouldUseUIKitHeuristics:(BOOL)val;
@end

@interface UIInternalEvent : UIEvent {
    __GSEvent *_gsEvent;
    __IOHIDEvent *_hidEvent;
}

- (__GSEvent*)_gsEvent;
- (__IOHIDEvent*)_hidEvent;
- (id)_screen;
- (void)_setGSEvent:(__GSEvent*)arg1;
- (void)_setHIDEvent:(__IOHIDEvent*)arg1;
@end

@interface UIKeyboardImpl
+ (id)activeInstance;
+ (id)sharedInstance;
- (void)handleKeyEvent:(id)arg1;
- (void)handleKeyWithString:(id)arg1 forKeyEvent:(id)arg2 executionContext:(id)arg3;
- (void)deleteBackward;
-(void) setInHardwareKeyboardMode:(BOOL)arg1;
@end

@interface UIPhysicalKeyboardEvent
+ (id)_eventWithInput:(id)arg1 inputFlags:(int)arg2;
@property(retain, nonatomic) NSString *_privateInput; // @synthesize _privateInput;
@property(nonatomic) int _inputFlags; // @synthesize _inputFlags;
@property(nonatomic) int _modifierFlags; // @synthesize _modifierFlags;
@property(retain, nonatomic) NSString *_markedInput; // @synthesize _markedInput;
@property(retain, nonatomic) NSString *_commandModifiedInput; // @synthesize _commandModifiedInput;
@property(retain, nonatomic) NSString *_shiftModifiedInput; // @synthesize _shiftModifiedInput;
@property(retain, nonatomic) NSString *_unmodifiedInput; // @synthesize _unmodifiedInput;
@property(retain, nonatomic) NSString *_modifiedInput; // @synthesize _modifiedInput;
@property(readonly, nonatomic) int _gsModifierFlags;
- (void)_privatizeInput;
- (void)dealloc;
- (id)_cloneEvent;
- (BOOL)isEqual:(id)arg1;
- (BOOL)_matchesKeyCommand:(id)arg1;
- (void)_setHIDEvent:(struct __IOHIDEvent *)arg1 keyboard:(struct __GSKeyboard *)arg2;
@property(readonly, nonatomic) long _keyCode;
@property(readonly, nonatomic) BOOL _isKeyDown;
- (int)type;
@end

@interface FBWorkspaceEvent : NSObject
+ (instancetype)eventWithName:(NSString *)label handler:(id)handler;
@end

@interface FBSceneManager : NSObject
@end

@interface SBAppToAppWorkspaceTransaction
- (void)begin;
- (id)initWithAlertManager:(id)alertManager exitedApp:(id)app;
- (id)initWithAlertManager:(id)arg1 from:(id)arg2 to:(id)arg3 withResult:(id)arg4;
- (id)initWithTransitionRequest:(id)arg1;
@end

@interface FBWorkspaceEventQueue : NSObject
+ (instancetype)sharedInstance;
- (void)executeOrAppendEvent:(FBWorkspaceEvent *)event;
@end

@interface SBDeactivationSettings
-(id)init;
-(void)setFlag:(int)flag forDeactivationSetting:(unsigned)deactivationSetting;
@end

@interface SBWorkspace 
+(id) sharedInstance;
-(BOOL) isUsingReachApp;
- (void)_exitReachabilityModeWithCompletion:(id)arg1;
- (void)_disableReachabilityImmediately:(_Bool)arg1;
- (void)handleReachabilityModeDeactivated;
-(void) RA_animateWidgetSelectorOut:(id)completion;
-(void) RA_setView:(UIView*)view preferredHeight:(CGFloat)preferredHeight;
-(void) RA_launchTopAppWithIdentifier:(NSString*) bundleIdentifier;
-(void) RA_showWidgetSelector;
-(void) updateViewSizes:(CGPoint)center animate:(BOOL)animate;
-(void) RA_closeCurrentView;
-(void) RA_handleLongPress:(UILongPressGestureRecognizer*)gesture;
-(void) RA_updateViewSizes;
@end

@interface SBDisplayLayout : NSObject {
	int _layoutSize;
	NSMutableArray* _displayItems;
	NSString* _uniqueStringRepresentation;
}
@property(readonly, assign, nonatomic) NSArray* displayItems;
@property(readonly, assign, nonatomic) int layoutSize;
+(id)fullScreenDisplayLayoutForApplication:(id)application;
+(id)homeScreenDisplayLayout;
+(id)displayLayoutWithPlistRepresentation:(id)plistRepresentation;
+(id)displayLayoutWithLayoutSize:(int)layoutSize displayItems:(id)items;
-(id)displayLayoutBySettingSize:(int)size;
-(id)displayLayoutByReplacingDisplayItemOnSide:(int)side withDisplayItem:(id)displayItem;
-(id)displayLayoutByRemovingDisplayItems:(id)items;
-(id)displayLayoutByRemovingDisplayItem:(id)item;
-(id)displayLayoutByAddingDisplayItem:(id)item side:(int)side withLayout:(int)layout;
-(BOOL)isEqual:(id)equal;
-(unsigned)hash;
-(id)uniqueStringRepresentation;
-(id)_calculateUniqueStringRepresentation;
-(id)description;
-(id)copyWithZone:(NSZone*)zone;
-(void)dealloc;
-(id)plistRepresentation;
-(id)initWithLayoutSize:(int)layoutSize displayItems:(id)items;
@end

@interface FBProcessManager : NSObject
+ (id)sharedInstance;
- (void)_updateWorkspaceLockedState;
- (void)applicationProcessWillLaunch:(id)arg1;
- (void)noteProcess:(id)arg1 didUpdateState:(id)arg2;
- (void)noteProcessDidExit:(id)arg1;
- (id)_serviceClientAddedWithPID:(int)arg1 isUIApp:(BOOL)arg2 isExtension:(BOOL)arg3 bundleID:(id)arg4;
- (id)_serviceClientAddedWithConnection:(id)arg1;
- (id)_systemServiceClientAdded:(id)arg1;
- (BOOL)_isWorkspaceLocked;
- (id)createApplicationProcessForBundleID:(id)arg1 withExecutionContext:(id)arg2;
- (id)createApplicationProcessForBundleID:(id)arg1;
- (id)applicationProcessForPID:(int)arg1;
- (id)processForPID:(int)arg1;
- (id)applicationProcessesForBundleIdentifier:(id)arg1;
- (id)processesForBundleIdentifier:(id)arg1;
- (id)allApplicationProcesses;
- (id)allProcesses;
@end

@interface UIGestureRecognizerTarget : NSObject {
	id _target;
}
@end

typedef NS_ENUM(NSUInteger, BKSProcessAssertionReason)
{
    kProcessAssertionReasonNone = 0,
    kProcessAssertionReasonAudio = 1,
    kProcessAssertionReasonLocation = 2,
    kProcessAssertionReasonExternalAccessory = 3,
    kProcessAssertionReasonFinishTask = 4,
    kProcessAssertionReasonBluetooth = 5,
    kProcessAssertionReasonNetworkAuthentication = 6,
    kProcessAssertionReasonBackgroundUI = 7,
    kProcessAssertionReasonInterAppAudioStreaming = 8,
    kProcessAssertionReasonViewServices = 9,
    kProcessAssertionReasonNewsstandDownload = 10,
    kProcessAssertionReasonBackgroundDownload = 11,
    kProcessAssertionReasonVOiP = 12,
    kProcessAssertionReasonExtension = 13,
    kProcessAssertionReasonContinuityStreams = 14,
    // 15-9999 unknown
    kProcessAssertionReasonActivation = 10000,
    kProcessAssertionReasonSuspend = 10001,
    kProcessAssertionReasonTransientWakeup = 10002,
    kProcessAssertionReasonVOiP_PreiOS8 = 10003,
    kProcessAssertionReasonPeriodicTask_iOS8 = kProcessAssertionReasonVOiP_PreiOS8,
    kProcessAssertionReasonFinishTaskUnbounded = 10004,
    kProcessAssertionReasonContinuous = 10005,
    kProcessAssertionReasonBackgroundContentFetching = 10006,
    kProcessAssertionReasonNotificationAction = 10007,
    // 10008-49999 unknown
    kProcessAssertionReasonFinishTaskAfterBackgroundContentFetching = 50000,
    kProcessAssertionReasonFinishTaskAfterBackgroundDownload = 50001,
    kProcessAssertionReasonFinishTaskAfterPeriodicTask = 50002,
    kProcessAssertionReasonAFterNoficationAction = 50003,
    // 50004+ unknown
};

typedef NS_ENUM(NSUInteger, ProcessAssertionFlags)
{
    ProcessAssertionFlagNone = 0,
    ProcessAssertionFlagPreventSuspend         = 1 << 0,
    ProcessAssertionFlagPreventThrottleDownCPU = 1 << 1,
    ProcessAssertionFlagAllowIdleSleep         = 1 << 2,
    ProcessAssertionFlagWantsForegroundResourcePriority  = 1 << 3
};


@interface FBWindowContextHostManager
- (id)hostViewForRequester:(id)arg1 enableAndOrderFront:(BOOL)arg2;
- (void)resumeContextHosting;
- (id)_hostViewForRequester:(id)arg1 enableAndOrderFront:(BOOL)arg2;
- (id)snapshotViewWithFrame:(CGRect)arg1 excludingContexts:(id)arg2 opaque:(BOOL)arg3;
- (id)snapshotUIImageForFrame:(struct CGRect)arg1 excludingContexts:(id)arg2 opaque:(BOOL)arg3 outTransform:(struct CGAffineTransform *)arg4;
- (id)visibleContexts;
- (void)orderRequesterFront:(id)arg1;
- (void)enableHostingForRequester:(id)arg1 orderFront:(BOOL)arg2;
- (void)enableHostingForRequester:(id)arg1 priority:(int)arg2;
- (void)disableHostingForRequester:(id)arg1;
- (void)_updateHostViewFrameForRequester:(id)arg1;
- (void)invalidate;

@property(copy, nonatomic) NSString *identifier; // @synthesize identifier=_identifier;
@end

@interface FBSSceneSettings : NSObject <NSCopying, NSMutableCopying>
{
    CGRect _frame;
    CGPoint _contentOffset;
    float _level;
    int _interfaceOrientation;
    BOOL _backgrounded;
    BOOL _occluded;
    BOOL _occludedHasBeenCalculated;
    NSSet *_ignoreOcclusionReasons;
    NSArray *_occlusions;
    //BSSettings *_otherSettings;
    //BSSettings *_transientLocalSettings;
}

+ (BOOL)_isMutable;
+ (id)settings;
@property(readonly, copy, nonatomic) NSArray *occlusions; // @synthesize occlusions=_occlusions;
@property(readonly, nonatomic, getter=isBackgrounded) BOOL backgrounded; // @synthesize backgrounded=_backgrounded;
@property(readonly, nonatomic) int interfaceOrientation; // @synthesize interfaceOrientation=_interfaceOrientation;
@property(readonly, nonatomic) float level; // @synthesize level=_level;
@property(readonly, nonatomic) CGPoint contentOffset; // @synthesize contentOffset=_contentOffset;
@property(readonly, nonatomic) CGRect frame; // @synthesize frame=_frame;
- (id)valueDescriptionForFlag:(int)arg1 object:(id)arg2 ofSetting:(unsigned int)arg3;
- (id)keyDescriptionForSetting:(unsigned int)arg1;
- (id)description;
- (BOOL)isEqual:(id)arg1;
- (unsigned int)hash;
- (id)_descriptionOfSettingsWithMultilinePrefix:(id)arg1;
- (id)transientLocalSettings;
- (BOOL)isIgnoringOcclusions;
- (id)ignoreOcclusionReasons;
- (id)otherSettings;
- (BOOL)isOccluded;
- (CGRect)bounds;
- (void)dealloc;
- (id)init;
- (id)initWithSettings:(id)arg1;

@end

@interface FBSMutableSceneSettings : FBSSceneSettings
{
}

+ (BOOL)_isMutable;
- (id)mutableCopyWithZone:(struct _NSZone *)arg1;
- (id)copyWithZone:(struct _NSZone *)arg1;
@property(copy, nonatomic) NSArray *occlusions;
- (id)transientLocalSettings;
- (id)ignoreOcclusionReasons;
- (id)otherSettings;
@property(nonatomic, getter=isBackgrounded) BOOL backgrounded;
@property(nonatomic) int interfaceOrientation;
@property(nonatomic) float level;
@property(nonatomic) struct CGPoint contentOffset;
@property(nonatomic) struct CGRect frame;

@end

@interface FBProcess : NSObject
@end

@interface FBScene
-(FBWindowContextHostManager*) contextHostManager;
@property(readonly, retain, nonatomic) FBSMutableSceneSettings *mutableSettings; // @synthesize mutableSettings=_mutableSettings;
- (void)updateSettings:(id)arg1 withTransitionContext:(id)arg2;
- (void)_applyMutableSettings:(id)arg1 withTransitionContext:(id)arg2 completion:(id)arg3;
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly, retain) FBProcess *clientProcess;
@end

@interface SBApplication ()
-(void) _setDeactivationSettings:(SBDeactivationSettings*)arg1;
-(FBScene*) mainScene;
-(id) mainScreenContextHostManager;
-(id) mainSceneID;
- (void)activate;

- (void)processDidLaunch:(id)arg1;
- (void)processWillLaunch:(id)arg1;
- (void)resumeForContentAvailable;
- (void)resumeToQuit;
- (void)_sendDidLaunchNotification:(_Bool)arg1;
- (void)notifyResumeActiveForReason:(long long)arg1;

@property(readonly, nonatomic) int pid;
@end

@interface SBApplicationController : NSObject
+(id) sharedInstance;
-(SBApplication*) applicationWithBundleIdentifier:(NSString*)identifier;
-(SBApplication*) applicationWithDisplayIdentifier:(NSString*)identifier;
-(SBApplication*)applicationWithPid:(int)arg1;
-(SBApplication*) RA_applicationWithBundleIdentifier:(NSString*)bundleIdentifier;
@end

@interface FBWindowContextHostWrapperView : UIView
@property(readonly, nonatomic) FBWindowContextHostManager *manager; // @synthesize manager=_manager;
@property(nonatomic) unsigned int appearanceStyle; // @synthesize appearanceStyle=_appearanceStyle;
- (void)_setAppearanceStyle:(unsigned int)arg1 force:(BOOL)arg2;
- (id)_stringForAppearanceStyle;
- (id)window;
@property(readonly, nonatomic) struct CGRect referenceFrame; // @dynamic referenceFrame;
@property(readonly, nonatomic, getter=isContextHosted) BOOL contextHosted; // @dynamic contextHosted;
- (void)clearManager;
- (void)_hostingStatusChanged;
- (BOOL)_isReallyHosting;
- (void)updateFrame;

@property(retain, nonatomic) UIColor *backgroundColorWhileNotHosting;
@property(retain, nonatomic) UIColor *backgroundColorWhileHosting;
@end
@interface FBWindowContextHostView : UIView
@end

@interface UIKeyboard : UIView
+ (BOOL)isOnScreen;
+ (CGSize)keyboardSizeForInterfaceOrientation:(UIInterfaceOrientation)orientation;
+ (CGRect)defaultFrameForInterfaceOrientation:(UIInterfaceOrientation)orientation;
+ (id)activeKeyboard;

- (BOOL)isMinimized;
- (void)minimize;
@end

@interface BKSProcessAssertion
- (id)initWithPID:(int)arg1 flags:(unsigned int)arg2 reason:(unsigned int)arg3 name:(id)arg4 withHandler:(id)arg5;
- (id)initWithBundleIdentifier:(id)arg1 flags:(unsigned int)arg2 reason:(unsigned int)arg3 name:(id)arg4 withHandler:(id)arg5;
- (void)invalidate;
@property(readonly, nonatomic) BOOL valid;
@end

@interface SBReachabilityManager
+ (id)sharedInstance;
@property(readonly, nonatomic) _Bool reachabilityModeActive; // @synthesize reachabilityModeActive=_reachabilityModeActive;
- (void)_handleReachabilityDeactivated;
- (void)_handleReachabilityActivated;
@end
@interface SBAppSwitcherModel : NSObject
+ (id)sharedInstance;
- (id)snapshotOfFlattenedArrayOfAppIdentifiersWhichIsOnlyTemporary;
- (id)snapshot;
- (void)remove:(id)arg1;
- (void)removeDisplayItem:(id)arg1;
- (void)addToFront:(id)arg1;
- (void)_verifyAppList;
- (id)_recentsFromPrefs;
- (id)_recentsFromLegacyPrefs;
@end

@interface UIImage ()
+ (id)_applicationIconImageForBundleIdentifier:(id)arg1 format:(int)arg2 scale:(float)arg3;
+ (id)_applicationIconImageForBundleIdentifier:(id)arg1 format:(int)arg2;
- (UIImage*) _flatImageWithColor: (UIColor*) color;
@end

@interface FBApplicationProcess : NSObject
- (void)launchIfNecessary;
- (BOOL)bootstrapAndExec;
- (void)killForReason:(int)arg1 andReport:(BOOL)arg2 withDescription:(id)arg3 completion:(id/*block*/)arg4;
- (void)killForReason:(int)arg1 andReport:(BOOL)arg2 withDescription:(id)arg3;
@property(readonly, copy, nonatomic) NSString *bundleIdentifier;

@end

@interface UITextEffectsWindow : UIWindow
+ (instancetype)sharedTextEffectsWindow;
- (unsigned int)contextID;
@end

@interface UIWindow () 
+(id) keyWindow;
-(id) firstResponder;
+ (void)setAllWindowsKeepContextInBackground:(BOOL)arg1;
-(void) _setRotatableViewOrientation:(UIInterfaceOrientation)orientation duration:(CGFloat)duration force:(BOOL)force;
- (void)_setRotatableViewOrientation:(int)arg1 updateStatusBar:(BOOL)arg2 duration:(double)arg3 force:(BOOL)arg4;
- (void)_rotateWindowToOrientation:(int)arg1 updateStatusBar:(BOOL)arg2 duration:(double)arg3 skipCallbacks:(BOOL)arg4;
- (unsigned int)_contextId;
-(UIInterfaceOrientation) _windowInterfaceOrientation;
@end

@interface UIApplication ()
- (void)_handleKeyUIEvent:(id)arg1;
-(UIView*) statusBar;
- (id)_mainScene;

// SpringBoard methods
-(BOOL)launchApplicationWithIdentifier:(id)identifier suspended:(BOOL)suspended;
-(SBApplication*) _accessibilityFrontMostApplication;

- (void)_setStatusBarHidden:(BOOL)arg1 animationParameters:(id)arg2 changeApplicationFlag:(BOOL)arg3;
- (void)RA_forceRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation isReverting:(BOOL)reverting;
- (void)applicationDidResume;
- (void)_sendWillEnterForegroundCallbacks;
- (void)suspend;
- (void)applicationWillSuspend;
- (void)_setSuspended:(BOOL)arg1;
- (void)applicationSuspend;
- (void)_deactivateForReason:(int)arg1 notify:(BOOL)arg2;
@end

@interface SBIconLabelView : UIView
@end

@interface SBIcon (iOS81)
-(BOOL) isBeta;
- (_Bool)isApplicationIcon;
@end

@interface SBIconModel (iOS81)
- (id)visibleIconIdentifiers;
- (id)applicationIconForBundleIdentifier:(id)arg1;
@end

@interface SBIconModel (iOS40)
- (/*SBApplicationIcon*/SBIcon *)applicationIconForDisplayIdentifier:(NSString *)displayIdentifier;
@end

@interface SBIcon (iOS40)
- (void)prepareDropGlow;
- (UIImageView *)dropGlow;
- (void)showDropGlow:(BOOL)showDropGlow;
- (long long)badgeValue;
- (id)leafIdentifier;
- (SBApplication*)application;
- (NSString*)applicationBundleID;
@end

@interface SBIconController (iOS40)
- (BOOL)canUninstallIcon:(SBIcon *)icon;
@end

@protocol SBIconViewDelegate, SBIconViewLocker;
@class SBIconImageContainerView, SBIconBadgeImage;

@interface SBIconAccessoryImage : UIImage
-(id)initWithImage:(id)arg1 ;
@end

@interface SBDarkeningImageView : UIImageView
- (void)setImage:(id)arg1 brightness:(double)arg2;
- (void)setImage:(id)arg1;
@end

@interface SBIconBadgeView : UIView
{
    NSString *_text;
    _Bool _animating;
    id/*block*/ _queuedAnimation;
    _Bool _displayingAccessory;
    SBIconAccessoryImage *_backgroundImage;
    SBDarkeningImageView *_backgroundView;
    SBDarkeningImageView *_textView;
}

+ (id)_createImageForText:(id)arg1 highlighted:(_Bool)arg2;
+ (id)_checkoutImageForText:(id)arg1 highlighted:(_Bool)arg2;
+ (id)_checkoutBackgroundImage;
+ (id)checkoutAccessoryImagesForIcon:(id)arg1 location:(int)arg2;
+ (struct CGPoint)_overhang;
+ (double)_textPadding;
+ (struct CGPoint)_textOffset;
+ (double)_maxTextWidth;
+ (id)_textFont;
- (void)_resizeForTextImage:(id)arg1;
- (void)_clearText;
- (void)_zoomOutWithPreparation:(id/*block*/)arg1 animation:(id/*block*/)arg2 completion:(id/*block*/)arg3;
- (void)_zoomInWithTextImage:(id)arg1 preparation:(id/*block*/)arg2 animation:(id/*block*/)arg3 completion:(id/*block*/)arg4;
- (void)_crossfadeToTextImage:(id)arg1 withPreparation:(id/*block*/)arg2 animation:(id/*block*/)arg3 completion:(id/*block*/)arg4;
- (void)_configureAnimatedForText:(id)arg1 highlighted:(_Bool)arg2 withPreparation:(id/*block*/)arg3 animation:(id/*block*/)arg4 completion:(id/*block*/)arg5;
- (void)setAccessoryBrightness:(double)arg1;
- (struct CGPoint)accessoryOriginForIconBounds:(struct CGRect)arg1;
- (void)prepareForReuse;
- (_Bool)displayingAccessory;
- (void)configureForIcon:(id)arg1 location:(int)arg2 highlighted:(_Bool)arg3;
- (void)configureAnimatedForIcon:(id)arg1 location:(int)arg2 highlighted:(_Bool)arg3 withPreparation:(id/*block*/)arg4 animation:(id/*block*/)arg5 completion:(id/*block*/)arg6;
- (void)layoutSubviews;
- (void)dealloc;
- (id)init;
@end

@interface SBIconParallaxBadgeView : SBIconBadgeView
- (void)_applyParallaxSettings;
- (void)settings:(id)arg1 changedValueForKey:(id)arg2;
@end

@interface SBIconView : UIView {
	SBIcon *_icon;
	id<SBIconViewDelegate> _delegate;
	id<SBIconViewLocker> _locker;
	SBIconImageContainerView *_iconImageContainer;
	SBIconImageView *_iconImageView;
	UIImageView *_iconDarkeningOverlay;
	UIImageView *_ghostlyImageView;
	UIImageView *_reflection;
	UIImageView *_shadow;
	SBIconBadgeImage *_badgeImage;
	UIImageView *_badgeView;
	SBIconLabel *_label;
	BOOL _labelHidden;
	BOOL _labelOnWallpaper;
	UIView *_closeBox;
	int _closeBoxType;
	UIImageView *_dropGlow;
	unsigned _drawsLabel : 1;
	unsigned _isHidden : 1;
	unsigned _isGrabbed : 1;
	unsigned _isOverlapping : 1;
	unsigned _refusesRecipientStatus : 1;
	unsigned _highlighted : 1;
	unsigned _launchDisabled : 1;
	unsigned _isJittering : 1;
	unsigned _allowJitter : 1;
	unsigned _touchDownInIcon : 1;
	unsigned _hideShadow : 1;
	NSTimer *_delayedUnhighlightTimer;
	unsigned _onWallpaper : 1;
	unsigned _ghostlyRequesters;
	int _iconLocation;
	float _iconImageAlpha;
	float _iconImageBrightness;
	float _iconLabelAlpha;
	float _accessoryAlpha;
	CGPoint _unjitterPoint;
	CGPoint _grabPoint;
	NSTimer *_longPressTimer;
	unsigned _ghostlyTag;
	UIImage *_ghostlyImage;
	BOOL _ghostlyPending;
}


-(void) RA_updateIndicatorView:(NSInteger)info;
-(void) RA_updateIndicatorViewWithExistingInfo;


+ (CGSize)defaultIconSize;
+ (CGSize)defaultIconImageSize;
+ (BOOL)allowsRecycling;
+ (id)_jitterPositionAnimation;
+ (id)_jitterTransformAnimation;
+ (struct CGSize)defaultIconImageSize;
+ (struct CGSize)defaultIconSize;

- (id)initWithDefaultSize;
- (void)dealloc;

@property(assign) id<SBIconViewDelegate> delegate;
@property(assign) id<SBIconViewLocker> locker;
@property(readonly, retain) SBIcon *icon;
- (void)setIcon:(SBIcon *)icon;

- (int)location;
- (void)setLocation:(int)location;
- (void)showIconAnimationDidStop:(id)showIconAnimation didFinish:(id)finish icon:(id)icon;
- (void)setIsHidden:(BOOL)hidden animate:(BOOL)animate;
- (BOOL)isHidden;
- (BOOL)isRevealable;
- (void)positionIconImageView;
- (void)applyIconImageTransform:(CATransform3D)transform duration:(float)duration delay:(float)delay;
- (void)setDisplayedIconImage:(id)image;
- (id)snapshotSettings;
- (id)iconImageSnapshot:(id)snapshot;
- (id)reflectedIconWithBrightness:(CGFloat)brightness;
- (void)setIconImageAlpha:(CGFloat)alpha;
- (void)setIconLabelAlpha:(CGFloat)alpha;
- (SBIconImageView *)iconImageView;
- (void)setLabelHidden:(BOOL)hidden;
- (void)positionLabel;
- (CGSize)_labelSize;
- (Class)_labelClass;
- (void)updateLabel;
- (void)_updateBadgePosition;
- (id)_overriddenBadgeTextForText:(id)text;
- (void)updateBadge;
- (id)_automationID;
- (BOOL)pointMostlyInside:(CGPoint)inside withEvent:(UIEvent *)event;
- (CGRect)frameForIconOverlay;
- (void)placeIconOverlayView;
- (void)updateIconOverlayView;
- (void)_updateIconBrightness;
- (BOOL)allowsTapWhileEditing;
- (BOOL)delaysUnhighlightWhenTapped;
- (BOOL)isHighlighted;
- (void)setHighlighted:(BOOL)highlighted;
- (void)setHighlighted:(BOOL)highlighted delayUnhighlight:(BOOL)unhighlight;
- (void)_delayedUnhighlight;
- (BOOL)isInDock;
- (id)_shadowImage;
- (void)_updateShadow;
- (void)updateReflection;
- (void)setDisplaysOnWallpaper:(BOOL)wallpaper;
- (void)setLabelDisplaysOnWallpaper:(BOOL)wallpaper;
- (BOOL)showsReflection;
- (float)_reflectionImageOffset;
- (void)setFrame:(CGRect)frame;
- (void)setIsJittering:(BOOL)isJittering;
- (void)setAllowJitter:(BOOL)allowJitter;
- (BOOL)allowJitter;
- (void)removeAllIconAnimations;
- (void)setIconPosition:(CGPoint)position;
- (void)setRefusesRecipientStatus:(BOOL)status;
- (BOOL)canReceiveGrabbedIcon:(id)icon;
- (double)grabDurationForEvent:(id)event;
- (void)setIsGrabbed:(BOOL)grabbed;
- (BOOL)isGrabbed;
- (void)setIsOverlapping:(BOOL)overlapping;
- (CGAffineTransform)transformToMakeDropGlowShrinkToIconSize;
- (void)prepareDropGlow;
- (void)showDropGlow:(BOOL)glow;
- (void)removeDropGlow;
- (id)dropGlow;
- (BOOL)isShowingDropGlow;
- (void)placeGhostlyImageView;
- (id)_genGhostlyImage:(id)image;
- (void)prepareGhostlyImageIfNeeded;
- (void)prepareGhostlyImage;
- (void)prepareGhostlyImageView;
- (void)setGhostly:(BOOL)ghostly requester:(int)requester;
- (void)setPartialGhostly:(float)ghostly requester:(int)requester;
- (void)removeGhostlyImageView;
- (BOOL)isGhostly;
- (int)ghostlyRequesters;
- (void)longPressTimerFired;
- (void)cancelLongPressTimer;
- (void)touchesCancelled:(id)cancelled withEvent:(id)event;
- (void)touchesBegan:(id)began withEvent:(id)event;
- (void)touchesMoved:(id)moved withEvent:(id)event;
- (void)touchesEnded:(id)ended withEvent:(id)event;
- (BOOL)isTouchDownInIcon;
- (void)setTouchDownInIcon:(BOOL)icon;
- (void)hideCloseBoxAnimationDidStop:(id)hideCloseBoxAnimation didFinish:(id)finish closeBox:(id)box;
- (void)positionCloseBoxOfType:(int)type;
- (id)_newCloseBoxOfType:(int)type;
- (void)setShowsCloseBox:(BOOL)box;
- (void)setShowsCloseBox:(BOOL)box animated:(BOOL)animated;
- (BOOL)isShowingCloseBox;
- (void)closeBoxTapped;
- (BOOL)pointInside:(CGPoint)inside withEvent:(id)event;
- (UIEdgeInsets)snapshotEdgeInsets;
- (void)setShadowsHidden:(BOOL)hidden;
- (void)_updateShadowFrameForShadow:(id)shadow;
- (void)_updateShadowFrame;
- (BOOL)_delegatePositionIsEditable;
- (void)_delegateTouchEnded:(BOOL)ended;
- (BOOL)_delegateTapAllowed;
- (int)_delegateCloseBoxType;
- (id)createShadowImageView;
- (void)prepareForRecycling;
- (CGRect)defaultFrameForProgressBar;
- (void)iconImageDidUpdate:(id)iconImage;
- (void)iconAccessoriesDidUpdate:(id)iconAccessories;
- (void)iconLaunchEnabledDidChange:(id)iconLaunchEnabled;
- (SBIconImageView*)_iconImageView;

@end

@class NSMapTable;

@interface SBIconViewMap : NSObject {
	NSMapTable* _iconViewsForIcons;
	id<SBIconViewDelegate> _iconViewdelegate;
	NSMapTable* _recycledIconViewsByType;
	NSMapTable* _labels;
	NSMapTable* _badges;
}
+ (SBIconViewMap *)switcherMap;
+(SBIconViewMap *)homescreenMap;
+(Class)iconViewClassForIcon:(SBIcon *)icon location:(int)location;
-(id)init;
-(void)dealloc;
-(SBIconView *)mappedIconViewForIcon:(SBIcon *)icon;
-(SBIconView *)_iconViewForIcon:(SBIcon *)icon;
-(SBIconView *)iconViewForIcon:(SBIcon *)icon;
-(void)_addIconView:(SBIconView *)iconView forIcon:(SBIcon *)icon;
-(void)purgeIconFromMap:(SBIcon *)icon;
-(void)_recycleIconView:(SBIconView *)iconView;
-(void)recycleViewForIcon:(SBIcon *)icon;
-(void)recycleAndPurgeAll;
-(id)releaseIconLabelForIcon:(SBIcon *)icon;
-(void)captureIconLabel:(id)label forIcon:(SBIcon *)icon;
-(void)purgeRecycledIconViewsForClass:(Class)aClass;
-(void)_modelListAddedIcon:(SBIcon *)icon;
-(void)_modelRemovedIcon:(SBIcon *)icon;
-(void)_modelReloadedIcons;
-(void)_modelReloadedState;
-(void)iconAccessoriesDidUpdate:(SBIcon *)icon;
@end

@interface SBIconViewMap (iOS6)
@property (nonatomic, readonly) SBIconModel *iconModel;
@end

@interface SBApplication (iOS6)
- (BOOL)isRunning;
- (id)badgeNumberOrString;
- (NSString*)bundleIdentifier;
- (_Bool)_isRecentlyUpdated;
- (_Bool)_isNewlyInstalled;
-(UIInterfaceOrientation)statusBarOrientation;
@end

@interface SBIconBlurryBackgroundView : UIView
{
    struct CGRect _wallpaperRelativeBounds;
    _Bool _isBlurring;
    id _wantsBlurEvaluator;
    struct CGPoint _wallpaperRelativeCenter;
}

@property(copy, nonatomic) id wantsBlurEvaluator; // @synthesize wantsBlurEvaluator=_wantsBlurEvaluator;
@property(readonly, nonatomic) _Bool isBlurring; // @synthesize isBlurring=_isBlurring;
@property(nonatomic) struct CGPoint wallpaperRelativeCenter; // @synthesize wallpaperRelativeCenter=_wallpaperRelativeCenter;
- (_Bool)_shouldAnimatePropertyWithKey:(id)arg1;
- (void)setBlurring:(_Bool)arg1;
- (void)setWallpaperColor:(struct CGColor *)arg1 phase:(struct CGSize)arg2;
- (_Bool)wantsBlur:(id)arg1;
- (struct CGRect)wallpaperRelativeBounds;
- (void)didAddSubview:(id)arg1;
- (void)dealloc;
- (id)initWithFrame:(struct CGRect)arg1;
@end

@interface SBFolderIconBackgroundView : SBIconBlurryBackgroundView
- (id)initWithDefaultSize;
@end

@interface SBIconImageView ()
{
    UIImageView *_overlayView;
    //SBIconProgressView *_progressView;
    _Bool _isPaused;
    UIImage *_cachedSquareContentsImage;
    _Bool _showsSquareCorners;
    SBIcon *_icon;
    double _brightness;
    double _overlayAlpha;
}

+ (id)dequeueRecycledIconImageViewOfClass:(Class)arg1;
+ (void)recycleIconImageView:(id)arg1;
+ (double)cornerRadius;
@property(nonatomic) _Bool showsSquareCorners; // @synthesize showsSquareCorners=_showsSquareCorners;
@property(nonatomic) double overlayAlpha; // @synthesize overlayAlpha=_overlayAlpha;
@property(nonatomic) double brightness; // @synthesize brightness=_brightness;
@property(retain, nonatomic) SBIcon *icon; // @synthesize icon=_icon;
- (_Bool)_shouldAnimatePropertyWithKey:(id)arg1;
- (void)iconImageDidUpdate:(id)arg1;
- (struct CGRect)visibleBounds;
- (struct CGSize)sizeThatFits:(struct CGSize)arg1;
- (id)squareDarkeningOverlayImage;
- (id)darkeningOverlayImage;
- (id)squareContentsImage;
- (UIImage*)contentsImage;
- (void)_clearCachedImages;
- (id)_generateSquareContentsImage;
- (void)_updateProgressMask;
- (void)_updateOverlayImage;
- (id)_currentOverlayImage;
- (void)updateImageAnimated:(_Bool)arg1;
- (id)snapshot;
- (void)prepareForReuse;
- (void)layoutSubviews;
- (void)setPaused:(_Bool)arg1;
- (void)setProgressAlpha:(double)arg1;
- (void)_clearProgressView;
- (void)progressViewCanBeRemoved:(id)arg1;
- (void)setProgressState:(long long)arg1 paused:(_Bool)arg2 percent:(double)arg3 animated:(_Bool)arg4;
- (void)_updateOverlayAlpha;
- (void)setIcon:(id)arg1 animated:(_Bool)arg2;
- (void)dealloc;
- (id)initWithFrame:(struct CGRect)arg1;
@end

@interface BBBulletin
@property(copy, nonatomic) NSString *bulletinID; // @synthesize bulletinID=_bulletinID;
@property(copy, nonatomic) NSString *sectionID; // @synthesize sectionID=_sectionID;
@property(copy, nonatomic) NSString *section;
@property(copy, nonatomic) NSString *message;
@property(copy, nonatomic) NSString *subtitle;
@property(copy, nonatomic) NSString *title;
@property(copy, nonatomic) NSDate *date;
@end

@interface BBServer
- (void)publishBulletin:(id)arg1 destinations:(unsigned long long)arg2 alwaysToLockScreen:(_Bool)arg3;
- (id)_allBulletinsForSectionID:(id)arg1;

- (id)allBulletinIDsForSectionID:(id)arg1;
- (id)noticesBulletinIDsForSectionID:(id)arg1;
- (id)bulletinIDsForSectionID:(id)arg1 inFeed:(unsigned long long)arg2;
@end

