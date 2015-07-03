#import "RAWidget.h"

@interface RAReachabilityManager : NSObject
+(id) sharedInstance;

-(void) launchTopAppWithIdentifier:(NSString*)identifier;
-(void) launchWidget:(RAWidget*)widget;

-(void) showWidgetSelector;
@end