#import "RAMessaging.h"

@interface RAMessagingClient : NSObject
+(instancetype) sharedInstance;

@property (nonatomic, readonly) RAMessageAppData currentData;
@property (nonatomic) BOOL hasRecievedData;

-(void) requestUpdateFromServer;

-(BOOL) notifyServerToOpenURL:(NSURL*)url openInWindow:(BOOL)openWindow;

-(BOOL) shouldResize;
-(CGSize) resizeSize;
-(BOOL) shouldHideStatusBar;
-(BOOL) shouldShowStatusBar;
-(UIInterfaceOrientation) forcedOrientation;
-(BOOL) shouldForceOrientation;
-(BOOL) shouldUseExternalKeyboard;
-(BOOL) isBeingHosted;
@end