#import "RAWidget.h"

@class RAAppSliderProviderView;

@interface RAReachabilityManager : NSObject
+(id) sharedInstance;

-(void) launchTopAppWithIdentifier:(NSString*)identifier;
-(void) launchWidget:(RAWidget*)widget;
-(void) showAppWithSliderProvider:(RAAppSliderProviderView*)view;

-(void) showWidgetSelector;
@end