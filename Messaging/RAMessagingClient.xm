#import "RAMessagingClient.h"

extern const char *__progname;

@implementation RAMessagingClient
+(instancetype) sharedInstance
{
	IF_SPRINGBOARD {
		@throw [NSException exceptionWithName:@"IsSpringBoardException" reason:@"Cannot use RAMessagingClient in SpringBoard" userInfo:nil];
	}

	SHARED_INSTANCE2(RAMessagingClient, 
		[sharedInstance loadMessagingCenter];
		sharedInstance.hasRecievedData = NO;
	);
}

-(void) loadMessagingCenter
{
	RAMessageAppData data;

	data.shouldForceSize = NO;
	data.wantedClientOriginX = -1;
	data.wantedClientOriginY = -1;
	data.wantedClientWidth = -1;
	data.wantedClientHeight = -1;
	data.statusBarVisibility = YES;
	data.shouldForceStatusBar = NO;
	data.canHideStatusBarIfWanted = NO;
	data.forcedOrientation = UIInterfaceOrientationPortrait;
	data.shouldForceOrientation = NO;
	data.shouldUseExternalKeyboard = NO;
	data.forcePhoneMode = NO;
	data.isBeingHosted = NO; 

	_currentData = data; // Initialize data

	serverCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.efrederickson.reachapp.messaging.server"];

    void* handle = dlopen("/usr/lib/librocketbootstrap.dylib", RTLD_LAZY);
    if (handle)
    {
        void (*rocketbootstrap_distributedmessagingcenter_apply)(CPDistributedMessagingCenter*);
        rocketbootstrap_distributedmessagingcenter_apply = (void(*)(CPDistributedMessagingCenter*))dlsym(handle, "rocketbootstrap_distributedmessagingcenter_apply");
        rocketbootstrap_distributedmessagingcenter_apply(serverCenter);
        dlclose(handle);
    }
}

-(void) alertUser:(NSString*)description
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LOCALIZE(@"MULTIPLEXER") message:description delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

-(void) _requestUpdateFromServerWithTries:(int)tries
{
	if (!NSBundle.mainBundle.bundleIdentifier || strcmp(__progname, "assertiond") == 0 || strcmp(__progname, "searchd") == 0)
		return;
	NSDictionary *dict = @{ @"bundleIdentifier": NSBundle.mainBundle.bundleIdentifier };
	NSDictionary *data = [serverCenter sendMessageAndReceiveReplyName:RAMessagingUpdateAppInfoMessageName userInfo:dict];
	if (data && [data objectForKey:@"data"] != nil)
	{
		RAMessageAppData actualData;
		[data[@"data"] getBytes:&actualData length:sizeof(actualData)];
		[self updateWithData:actualData];
		self.hasRecievedData = YES;
	}
	else
	{
		if (tries <= 4)
			[self _requestUpdateFromServerWithTries:tries + 1];
		else
		{
			[self alertUser:[NSString stringWithFormat:@"App \"%@\" is unable to communicate with messaging server", [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"] ?: NSBundle.mainBundle.bundleIdentifier]];
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

	if (didStatusBarVisibilityChange && data.shouldForceStatusBar == NO)
   		[UIApplication.sharedApplication RA_forceStatusBarVisibility:_currentData.statusBarVisibility orRevert:YES];
   	else if (data.shouldForceStatusBar)
   		[UIApplication.sharedApplication RA_forceStatusBarVisibility:_currentData.statusBarVisibility orRevert:NO];

	if (didSizingChange && data.shouldForceSize == NO)
	   	[UIApplication.sharedApplication RA_updateWindowsForSizeChange:CGSizeMake(data.wantedClientWidth, data.wantedClientHeight) isReverting:YES];
	else if (data.shouldForceSize)
	   	[UIApplication.sharedApplication RA_updateWindowsForSizeChange:CGSizeMake(data.wantedClientWidth, data.wantedClientHeight) isReverting:NO];

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

-(void) notifyServerOfKeyboardSizeUpdate:(CGSize)size
{
	NSDictionary *dict = @{ @"size": NSStringFromCGSize(size) };
	[serverCenter sendMessageName:RAMessagingUpdateKeyboardSizeMessageName userInfo:dict];
}

-(BOOL) notifyServerToOpenURL:(NSURL*)url openInWindow:(BOOL)openWindow
{
	NSDictionary *dict = @{
		@"url": url.absoluteString,
		@"openInWindow": @(openWindow)
	};
	return [[serverCenter sendMessageAndReceiveReplyName:RAMessagingOpenURLKMessageName userInfo:dict][@"success"] boolValue];
}

-(void) notifySpringBoardOfFrontAppChangeToSelf
{
	if ([self isBeingHosted] && (self.knownFrontmostApp == nil || [self.knownFrontmostApp isEqualToString:NSBundle.mainBundle.bundleIdentifier] == NO))
		[serverCenter sendMessageName:RAMessagingChangeFrontMostAppMessageName userInfo:@{ @"bundleIdentifier": NSBundle.mainBundle.bundleIdentifier }];
}

-(BOOL) shouldUseExternalKeyboard { return _currentData.shouldUseExternalKeyboard; }
-(BOOL) shouldResize { return _currentData.shouldForceSize; }
-(CGSize) resizeSize { return CGSizeMake(_currentData.wantedClientWidth, _currentData.wantedClientHeight); }
-(BOOL) shouldHideStatusBar { return _currentData.shouldForceStatusBar && _currentData.statusBarVisibility == NO; }
-(BOOL) shouldShowStatusBar { return _currentData.shouldForceStatusBar && _currentData.statusBarVisibility == YES; }
-(UIInterfaceOrientation) forcedOrientation { return _currentData.forcedOrientation; }
-(BOOL) shouldForceOrientation { return _currentData.shouldForceOrientation; }
-(BOOL) isBeingHosted { return _currentData.isBeingHosted; }
@end

void reloadClientData(CFNotificationCenterRef center,
                    void *observer,
                    CFStringRef name,
                    const void *object,
                    CFDictionaryRef userInfo)
{
	[[RAMessagingClient sharedInstance] requestUpdateFromServer];
}

void updateFrontmostApp(CFNotificationCenterRef center,
                    void *observer,
                    CFStringRef name,
                    const void *object,
                    CFDictionaryRef userInfo)
{
	RAMessagingClient.sharedInstance.knownFrontmostApp = ((__bridge NSDictionary*)userInfo)[@"bundleIdentifier"];
}

%ctor
{
	IF_SPRINGBOARD {

	}
	else 
	{
		[RAMessagingClient sharedInstance];
    	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &reloadClientData, (__bridge CFStringRef)[NSString stringWithFormat:@"com.efrederickson.reachapp.clientupdate-%@",NSBundle.mainBundle.bundleIdentifier], NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    	CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, &updateFrontmostApp, CFSTR("com.efrederickson.reachapp.frontmostAppDidUpdate"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	}
}