#import <UIKit/UIKit.h>

// https://gist.github.com/evilGoldfish/49753c4aa247b727453e

typedef NS_ENUM(NSInteger, ASAuthenticationAlertType) {
    ASAuthenticationAlertAppArranging,
    ASAuthenticationAlertSwitcher,
    ASAuthenticationAlertSpotlight,
    ASAuthenticationAlertPowerDown,
    ASAuthenticationAlertControlCentre,
    ASAuthenticationAlertControlPanel,
    ASAuthenticationAlertPhotos,
    ASAuthenticationAlertSettingsPanel,
    ASAuthenticationAlertFlipswitch
};

typedef void (^ASCommonAuthenticationHandler) (BOOL wasCancelled);

@interface ASCommon : NSObject <UIAlertViewDelegate> {
    ASCommonAuthenticationHandler authHandler;
}
+(instancetype)sharedInstance;
-(UIAlertView *)currentAuthAlert;
-(BOOL)authenticateAppWithDisplayIdentifier:(NSString *)appIdentifier customMessage:(NSString *)customMessage dismissedHandler:(ASCommonAuthenticationHandler)handler;
-(BOOL)authenticateFunction:(ASAuthenticationAlertType)alertType dismissedHandler:(ASCommonAuthenticationHandler)handler;

@end

#define LOAD_ASPHALEIA dlopen("/usr/lib/libasphaleiaui.dylib", RTLD_LAZY);

#define HAS_ASPHALEIA2 (objc_getClass("ASCommon") != nil)
#define IF_ASPHALEIA2  if (HAS_ASPHALEIA2)

#define ASPHALEIA2_AUTHENTICATE_APP(ident, success, failure_) \
    BOOL isAppProtected = [[objc_getClass("ASCommon") sharedInstance] authenticateAppWithDisplayIdentifier:ident customMessage:nil dismissedHandler:^(BOOL wasCancelled) { \
        if (!wasCancelled) \
            success(); \
        else \
            failure_(); \
    }]; \
    if (!isAppProtected) { \
        success(); \
    }