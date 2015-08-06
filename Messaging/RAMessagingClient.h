#import "headers.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import "RAMessaging.h"

@interface RAMessagingClient : NSObject {
	CPDistributedMessagingCenter *serverCenter;
}
+(id) sharedInstance;

@property (nonatomic, readonly) RAMessageAppData currentData;

-(void) requestUpdateFromServer;

-(void) notifyServerWithKeyboardContextId:(unsigned int)cid;
-(void) notifyServerToShowKeyboard;
-(void) notifyServerToHideKeyboard;

// Methods to ease the currentData usage
-(BOOL) shouldResize;
-(CGSize) resizeSize;
-(BOOL) shouldHideStatusBar;
-(BOOL) shouldShowStatusBar;
-(UIInterfaceOrientation) forcedOrientation;
-(BOOL) shouldForceOrientation;
-(BOOL) shouldUseExternalKeyboard;
@end