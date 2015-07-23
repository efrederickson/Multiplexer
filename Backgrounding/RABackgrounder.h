#import "headers.h"

enum {
    RABackgroundModeNative = 1,
    RABackgroundModeForceNativeForOldApps = 2,
    RABackgroundModeForcedForeground = 3,
    RABackgroundModeForceNone = 4,
} RABackgroundMode;

@interface RABackgrounder : NSObject {
	NSMutableDictionary *backgroundStateInfo;
}
+(id) sharedInstance;

-(BOOL) shouldAutoLaunchApplication:(NSString*)identifier;
-(BOOL) shouldAutoRelaunchApplication:(NSString*)identifier;

-(BOOL) shouldKeepInForeground:(NSString*)identifier;

-(BOOL) killProcessOnExit:(NSString*)identifier;
-(BOOL) preventKillingOfIdentifier:(NSString*)identifier;
-(NSInteger) backgroundModeForIdentifier:(NSString*)identifier;
-(BOOL) hasUnlimitedBackgroundTime:(NSString*)identifier;

-(void) setBackgroundStateIconInfo:(NSString*)info forIdentifier:(NSString*)identifier;
-(BOOL) hasBackgroundStateIconInfoForIdentifier:(NSString*)identifier;
-(NSString*) descriptionForBackgroundStateInfoWithIdentifier:(NSString*)identifier;

-(BOOL) application:(NSString*)identifier overrideBackgroundMode:(NSString*)mode;
@end