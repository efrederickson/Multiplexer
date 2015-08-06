#import "RAMessagingClient.h"

@implementation RAMessagingClient
+(id) sharedInstance
{
	SHARED_INSTANCE2(RAMessagingClient, [sharedInstance loadMessagingCenter]);
}

-(void) loadMessagingCenter
{
	RAMessageAppData data;

	data.shouldForceSize = NO;
	data.wantedClientSize = CGSizeMake(-1, -1);
	data.statusBarVisibility = YES;
	data.shouldForceStatusBar = NO;
	data.canHideStatusBarIfWanted = NO;
	data.forcedOrientation = UIInterfaceOrientationPortrait;
	data.shouldForceOrientation = NO;

	_currentData = data; // Initialize data

	messagingCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:[NSString stringWithFormat:@"com.efrederickson.reachapp.messaging.client-%@",NSBundle.mainBundle.bundleIdentifier]];
	serverCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.efrederickson.reachapp.messaging.server"];

    void* handle = dlopen("/usr/lib/librocketbootstrap.dylib", RTLD_LAZY);
    if(handle)
    {
        void (*rocketbootstrap_distributedmessagingcenter_apply)(CPDistributedMessagingCenter*);
        rocketbootstrap_distributedmessagingcenter_apply = (void(*)(CPDistributedMessagingCenter*))dlsym(handle, "rocketbootstrap_distributedmessagingcenter_apply");
        rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
        rocketbootstrap_distributedmessagingcenter_apply(serverCenter);
    }

    [messagingCenter runServerOnCurrentThread];

    [messagingCenter registerForMessageName:RAMessagingUpdateAppInfoMessageName target:self selector:@selector(handleMessageNamed:userInfo:)];
}

-(NSDictionary*) handleMessageNamed:(NSString*)identifier userInfo:(NSDictionary*)info
{
	NSLog(@"[ReachApp] %@ %@", identifier, info);
	if ([identifier isEqual:RAMessagingUpdateAppInfoMessageName])
	{
		RAMessageAppData data;
		[info[@"data"] getBytes:&data length:sizeof(data)];
		[self updateWithData:data];
		return @{ @"success": @YES };
	}
	return nil;
}

-(void) alertUser:(NSString*)description
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LOCALIZE(@"MULTIPLEXER") message:description delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

-(void) _requestUpdateFromServerWithTries:(int)tries
{
	NSDictionary *dict = @{ @"bundleIdentifier": NSBundle.mainBundle.bundleIdentifier };
	NSDictionary *data = [serverCenter sendMessageAndReceiveReplyName:RAMessagingUpdateAppInfoMessageName userInfo:dict];
	if (data && [data objectForKey:@"data"] != nil)
	{
		RAMessageAppData actualData;
		[data[@"data"] getBytes:&actualData length:sizeof(actualData)];
		[self updateWithData:actualData];
	}
	else
	{
		if (tries <= 4)
			[self _requestUpdateFromServerWithTries:tries + 1];
		else
		{
			[self alertUser:[NSString stringWithFormat:@"App \"%@\" is unable to communicate with messaging server", [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"]]];
		}
	}
}

-(void) requestUpdateFromServer
{
	[self _requestUpdateFromServerWithTries:0];
}

-(void) updateWithData:(RAMessageAppData)data
{
	BOOL didStatusBarVisibilityChange = _currentData.shouldForceStatusBar != data.shouldForceStatusBar;
	BOOL didOrientationChange = _currentData.shouldForceOrientation != data.shouldForceOrientation;
	BOOL didSizingChange  =_currentData.shouldForceSize != data.shouldForceSize;

	/* THE REAL IMPORTANT BIT */
	_currentData = data;

	NSLog(@"[ReachApp] got orientation %ld", (long)_currentData.forcedOrientation);

	if (didStatusBarVisibilityChange && data.shouldForceStatusBar == NO)
   		[UIApplication.sharedApplication RA_forceStatusBarVisibility:_currentData.statusBarVisibility orRevert:YES];
   	else if (data.shouldForceStatusBar)
   		[UIApplication.sharedApplication RA_forceStatusBarVisibility:_currentData.statusBarVisibility orRevert:NO];

	if (didSizingChange && data.shouldForceSize == NO)
	   	[UIApplication.sharedApplication RA_updateWindowsForSizeChange:data.wantedClientSize isReverting:YES];
	else if (data.shouldForceSize)
	   	[UIApplication.sharedApplication RA_updateWindowsForSizeChange: data.wantedClientSize isReverting:NO];

	if (didOrientationChange && data.shouldForceOrientation == NO)	
		[UIApplication.sharedApplication RA_forceRotationToInterfaceOrientation:data.forcedOrientation isReverting:YES];
	else if (data.shouldForceOrientation)
		[UIApplication.sharedApplication RA_forceRotationToInterfaceOrientation:data.forcedOrientation isReverting:NO];
}

-(void) notifyServerWithKeyboardContextId:(unsigned int)cid
{
	NSDictionary *dict = @{ @"contextId": @(cid), @"bundleIdentifier": NSBundle.mainBundle.bundleIdentifier };
	[serverCenter sendMessageName:RAMessagingUpdateKeyboardContextIdMessageName userInfo:dict];
}

-(void) notifyServerToShowKeyboard
{
	NSDictionary *dict = @{ @"bundleIdentifier": NSBundle.mainBundle.bundleIdentifier };
	[serverCenter sendMessageName:RAMessagingShowKeyboardMessageName userInfo:dict];
}

-(void) notifyServerToHideKeyboard
{
	[serverCenter sendMessageName:RAMessagingHideKeyboardMessageName userInfo:nil];
}

-(BOOL) shouldUseExternalKeyboard { return _currentData.shouldUseExternalKeyboard; }
-(BOOL) shouldResize { return _currentData.shouldForceSize; }
-(CGSize) resizeSize { return _currentData.wantedClientSize; }
-(BOOL) shouldHideStatusBar { return _currentData.shouldForceStatusBar && _currentData.statusBarVisibility == NO; }
-(BOOL) shouldShowStatusBar { return _currentData.shouldForceStatusBar && _currentData.statusBarVisibility == YES; }
-(UIInterfaceOrientation) forcedOrientation { return _currentData.forcedOrientation; }
-(BOOL) shouldForceOrientation { return _currentData.shouldForceOrientation; }
@end

void reloadClientData(CFNotificationCenterRef center,
                    void *observer,
                    CFStringRef name,
                    const void *object,
                    CFDictionaryRef userInfo)
{
	[[RAMessagingClient sharedInstance] requestUpdateFromServer];
}

%ctor
{
	IF_SPRINGBOARD {

	}
	else 
	{
		[RAMessagingClient sharedInstance];
    	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &reloadClientData, (__bridge CFStringRef)[NSString stringWithFormat:@"com.efrederickson.reachapp.clientupdate-%@",NSBundle.mainBundle.bundleIdentifier], NULL, 0);
	}
}