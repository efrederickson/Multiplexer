#import "headers.h"
#import <AppSupport/CPDistributedMessagingCenter.h>

@interface RAMessagingServer : NSObject {
	CPDistributedMessagingCenter *messagingCenter;
}
+(instancetype) sharedInstance;

-(void) resizeApp:(NSString*)identifier toSize:(CGRect)size;
-(void) resizeApp:(NSString*)identifier toSize:(CGRect)size hideStatusBarIfWanted:(BOOL)hide;
@end
