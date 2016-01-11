#import "headers.h"

@class RAHostedAppView;

@interface SBNCColumnViewController : UIViewController
@end

@interface RANCViewController : SBNCColumnViewController
+(instancetype) sharedViewController;

-(RAHostedAppView*) hostedApp;
-(void) forceReloadAppLikelyBecauseTheSettingChanged;
@end