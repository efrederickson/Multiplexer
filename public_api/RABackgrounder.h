@class SBApplication;

enum RABackgroundMode {
    RABackgroundModeNative = 1,
    RABackgroundModeForceNativeForOldApps = 2,
    RABackgroundModeForcedForeground = 3,
    RABackgroundModeForceNone = 4,
    RABackgroundModeSuspendImmediately = 5,
    RABackgroundModeUnlimitedBackgroundingTime = 6,
};

// Localized.
NSString *FriendlyNameForBackgroundMode(RABackgroundMode mode);

@interface RABackgrounder : NSObject
+(id) sharedInstance;

-(BOOL) shouldAutoLaunchApplication:(NSString*)identifier;
-(BOOL) shouldAutoRelaunchApplication:(NSString*)identifier;

-(NSInteger) backgroundModeForIdentifier:(NSString*)identifier;

-(BOOL) shouldShowIndicatorForIdentifier:(NSString*)identifier;
-(BOOL) shouldShowStatusBarIconForIdentifier:(NSString*)identifier;
@end