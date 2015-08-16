#import "headers.h"

@class RAHostedAppView;

@interface RANCViewController : UIViewController
+(instancetype) sharedViewController;

-(RAHostedAppView*) hostedApp;
-(void) forceReloadAppLikelyBecauseTheSettingChanged;
@end