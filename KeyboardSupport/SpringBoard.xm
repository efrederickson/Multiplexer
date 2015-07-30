#import "headers.h"
#import "RAKeyboardWindow.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import "RARemoteKeyboardView.h"
#import "RADesktopManager.h"

extern CPDistributedMessagingCenter *messagingCenter;

extern BOOL overrideDisableForStatusBar;
RAKeyboardWindow *keyboardWindow;

@interface RASpringBoardKeyboardActivation : NSObject
+(void) loadMessagingCenter;
@end

static RASpringBoardKeyboardActivation *sharedInstance$RASpringBoardKeyboardActivation;

@implementation RASpringBoardKeyboardActivation
+(void) loadMessagingCenter
{
	sharedInstance$RASpringBoardKeyboardActivation = [[RASpringBoardKeyboardActivation alloc] init];

	if (!messagingCenter)
	{
	    messagingCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.efrederickson.reachapp.keyboardMessaging.springBoard"];

	    void* handle = dlopen("/usr/lib/librocketbootstrap.dylib", RTLD_LAZY);
	    if(handle)
	    {
	        void (*rocketbootstrap_distributedmessagingcenter_apply)(CPDistributedMessagingCenter*);
	        rocketbootstrap_distributedmessagingcenter_apply = (void(*)(CPDistributedMessagingCenter*))dlsym(handle, "rocketbootstrap_distributedmessagingcenter_apply");
	        rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
	    }

	    [messagingCenter runServerOnCurrentThread];
	}

    [messagingCenter registerForMessageName:@"showKeyboardForAppWithIdentifier" target:sharedInstance$RASpringBoardKeyboardActivation selector:@selector(showKeyboardForAppWithIdentifier:userInfo:)];
    [messagingCenter registerForMessageName:@"hideKeyboardForAppWithIdentifier" target:sharedInstance$RASpringBoardKeyboardActivation selector:@selector(hideKeyboardForAppWithIdentifier:userInfo:)];
}

-(void) showKeyboardForAppWithIdentifier:(NSString*)name userInfo:(NSDictionary*)userInfo
{
	NSString *bundleIdentifier = userInfo[@"bundleIdentifier"];

	NSLog(@"[ReachApp] springboard received showKeyboardForAppWithIdentifier: %@", bundleIdentifier);
	
	if (keyboardWindow)
	{
		NSLog(@"[ReachApp] springboard cancelling");
		return;
	}

	keyboardWindow = [[RAKeyboardWindow alloc] init];	
	overrideDisableForStatusBar = YES;
	[keyboardWindow setupForKeyboardAndShow:bundleIdentifier];
	overrideDisableForStatusBar = NO;
}

-(void) hideKeyboardForAppWithIdentifier:(NSString*)name userInfo:(NSDictionary*)userInfo
{
	NSLog(@"[ReachApp] Springboard received showKeyboardForAppWithIdentifier:");

	NSLog(@"[ReachApp] remove kb window");
	keyboardWindow.hidden = YES;
	[keyboardWindow removeKeyboard];
	keyboardWindow = nil;
}
@end

%ctor
{
	if ([NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"])
	{
		[RASpringBoardKeyboardActivation loadMessagingCenter];
	}
}