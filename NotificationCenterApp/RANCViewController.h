#import "headers.h"

@class RAHostedAppView;

@interface RANCViewController : UIViewController
-(RAHostedAppView*) hostedApp;
-(void) forceReloadAppLikelyBecauseTheSettingChanged;
@end