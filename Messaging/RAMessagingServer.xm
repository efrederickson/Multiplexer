#import "headers.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import "RAMessagingServer.h"
#import "RASpringBoardKeyboardActivation.h"

@implementation RAMessagingServer
+(instancetype) sharedInstance
{
	SHARED_INSTANCE2(RAMessagingServer, 
		[sharedInstance loadServer];
		sharedInstance->dataForApps = [NSMutableDictionary dictionary];
		sharedInstance->contextIds = [NSMutableDictionary dictionary];
		sharedInstance->waitingCompletions = [NSMutableDictionary dictionary];
	);
}

-(void) loadServer
{
    messagingCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.efrederickson.reachapp.messaging.server"];

    void* handle = dlopen("/usr/lib/librocketbootstrap.dylib", RTLD_LAZY);
    if(handle)
    {
        void (*rocketbootstrap_distributedmessagingcenter_apply)(CPDistributedMessagingCenter*);
        rocketbootstrap_distributedmessagingcenter_apply = (void(*)(CPDistributedMessagingCenter*))dlsym(handle, "rocketbootstrap_distributedmessagingcenter_apply");
        rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
    }

    [messagingCenter runServerOnCurrentThread];

    [messagingCenter registerForMessageName:RAMessagingShowKeyboardMessageName target:self selector:@selector(handleMessageNamed:userInfo:)];
    [messagingCenter registerForMessageName:RAMessagingHideKeyboardMessageName target:self selector:@selector(handleMessageNamed:userInfo:)];
    [messagingCenter registerForMessageName:RAMessagingUpdateKeyboardContextIdMessageName target:self selector:@selector(handleMessageNamed:userInfo:)];
    [messagingCenter registerForMessageName:RAMessagingRetrieveKeyboardContextIdMessageName target:self selector:@selector(handleMessageNamed:userInfo:)];
    [messagingCenter registerForMessageName:RAMessagingUpdateAppInfoMessageName target:self selector:@selector(handleMessageNamed:userInfo:)];
}

-(NSDictionary*) handleMessageNamed:(NSString*)identifier userInfo:(NSDictionary*)info
{
	if ([identifier isEqual:RAMessagingShowKeyboardMessageName])
		[self receiveShowKeyboardForAppWithIdentifier:info[@"bundleIdentifier"]];
	else if ([identifier isEqual:RAMessagingHideKeyboardMessageName])
		[self receiveHideKeyboard];
	else if ([identifier isEqual:RAMessagingUpdateKeyboardContextIdMessageName])
		[self setKeyboardContextId:[info[@"contextId"] integerValue] forIdentifier:info[@"bundleIdentifier"]];
	else if ([identifier isEqual:RAMessagingRetrieveKeyboardContextIdMessageName])
		return @{ @"contexId": @([self keyboardContextIdForIdentifier:info[@"bundleIdentifier"]]) };
	else if ([identifier isEqual:RAMessagingUpdateAppInfoMessageName])
	{
		NSString *identifier = info[@"bundleIdentifier"];
		RAMessageAppData data = [self getDataForIdentifier:identifier];

		if ([waitingCompletions objectForKey:identifier] != nil)
		{
			RAMessageCompletionCallback callback = (RAMessageCompletionCallback)waitingCompletions[identifier];
			[waitingCompletions removeObjectForKey:identifier];
			callback(YES);
		}

		return @{
			@"data": [NSData dataWithBytes:&data length:sizeof(data)],
		};
	}

	return nil;
}

-(void) alertUser:(NSString*)description
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LOCALIZE(@"MULTIPLEXER") message:description delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

-(RAMessageAppData) getDataForIdentifier:(NSString*)identifier
{
	RAMessageAppData ret;
	if ([dataForApps objectForKey:identifier] != nil)
		[dataForApps[identifier] getValue:&ret];
	else
	{
		// Initialize with some default values
		ret.shouldForceSize = NO;
		ret.wantedClientSize = CGSizeMake(-1, -1);
		ret.statusBarVisibility = YES;
		ret.shouldForceStatusBar = NO;
		ret.canHideStatusBarIfWanted = NO;
		ret.forcedOrientation = UIInterfaceOrientationPortrait;
		ret.shouldForceOrientation = NO;
	}
	return ret;
}

-(void) setData:(RAMessageAppData)data forIdentifier:(NSString*)identifier
{
	if (identifier)
	{
		dataForApps[identifier] = [NSValue valueWithBytes:&data objCType:@encode(RAMessageAppData)];
	}
}

-(void) checkIfCompletionStillExitsForIdentifierAndFailIt:(NSString*)identifier
{
	if ([waitingCompletions objectForKey:identifier] != nil)
	{
		RAMessageCompletionCallback callback = (RAMessageCompletionCallback)waitingCompletions[identifier];
		[waitingCompletions removeObjectForKey:identifier];

		SBApplication *app = [[%c(SBApplicationController) sharedInstance] RA_applicationWithBundleIdentifier:identifier];
		[self alertUser:[NSString stringWithFormat:@"Unable to communicate with app %@ (%@)", app.displayName, identifier]];
		callback(NO);
	}
}

-(void) sendData:(NSDictionary*)data withCurrentTries:(int)tries toAppWithBundleIdentifier:(NSString*)identifier completion:(RAMessageCompletionCallback)callback
{
	SBApplication *app = [[%c(SBApplicationController) sharedInstance] RA_applicationWithBundleIdentifier:identifier];
	if (!app.isRunning || [app mainScene] == nil)
	{
		if (tries > 4)
		{
			[self alertUser:[NSString stringWithFormat:@"Unable to communicate with app that isn't running: %@ (%@)", app.displayName, identifier]];
			if (callback)
				callback(NO);
			return;
		}

		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[self sendData:data withCurrentTries:tries + 1 toAppWithBundleIdentifier:identifier completion:callback];
		});
		return;
	}

	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFStringRef)[NSString stringWithFormat:@"com.efrederickson.reachapp.clientupdate-%@",identifier], nil, nil, YES);
	
	if (callback == nil)
		callback = ^(BOOL _) { };

	waitingCompletions[identifier] = [callback copy];
	[self performSelector:@selector(checkIfCompletionStillExitsForIdentifierAndFailIt:) withObject:identifier afterDelay:2];
	

/*
	SBApplication *app = [[%c(SBApplicationController) sharedInstance] RA_applicationWithBundleIdentifier:identifier];

	if (!app.isRunning || [app mainScene] == nil)
	{
		if (tries > 4)
		{
			[self alertUser:[NSString stringWithFormat:@"Unable to communicate with app that isn't running: %@ (%@)", app.displayName, identifier]];
			if (callback)
				callback(NO);
			return;
		}

		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[self sendData:data toApp:center withCurrentTries:tries + 1 bundleIdentifier:identifier completion:callback];
		});
		return;
	}

	NSDictionary *success = [center sendMessageAndReceiveReplyName:RAMessagingUpdateAppInfoMessageName userInfo:data];

	if (!success || [success objectForKey:@"success"] == nil || [success[@"success"] boolValue] == NO)
	{
		if (tries <= 4)
		{
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.75 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
				[self sendData:data toApp:center withCurrentTries:tries + 1 bundleIdentifier:identifier completion:callback];
			});
		}
		else
		{
			[self alertUser:[NSString stringWithFormat:@"Unable to communicate with app %@ (%@)\n\nadditional info: %@", app.displayName, identifier, success]];
			if (callback)
				callback(NO);
		}
	}
	else
		if (callback)
			callback(YES);
*/
}

-(void) sendStoredDataToApp:(NSString*)identifier completion:(RAMessageCompletionCallback)callback
{
	if (!identifier || identifier.length == 0)
		return;

	RAMessageAppData data = [self getDataForIdentifier:identifier];

	NSDictionary *dict = @{
		@"data": [NSData dataWithBytes:&data length:sizeof(data)],
	};

	[self sendData:dict withCurrentTries:0 toAppWithBundleIdentifier:identifier completion:callback];
}

-(void) resizeApp:(NSString*)identifier toSize:(CGSize)size completion:(RAMessageCompletionCallback)callback
{
	RAMessageAppData data = [self getDataForIdentifier:identifier];
	data.wantedClientSize = size;
	data.shouldForceSize = YES;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

-(void) endResizingApp:(NSString*)identifier completion:(RAMessageCompletionCallback)callback
{
	RAMessageAppData data = [self getDataForIdentifier:identifier];
	data.wantedClientSize = CGSizeMake(-1, -1);
	data.shouldForceSize = NO;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

-(void) rotateApp:(NSString*)identifier toOrientation:(UIInterfaceOrientation)orientation completion:(RAMessageCompletionCallback)callback
{
	RAMessageAppData data = [self getDataForIdentifier:identifier];
	data.forcedOrientation = orientation;
	data.shouldForceOrientation = YES;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

-(void) unRotateApp:(NSString*)identifier completion:(RAMessageCompletionCallback)callback
{
	RAMessageAppData data = [self getDataForIdentifier:identifier];
	data.shouldForceOrientation = NO;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

-(void) forceStatusBarVisibility:(BOOL)visibility forApp:(NSString*)identifier completion:(RAMessageCompletionCallback)callback
{
	RAMessageAppData data = [self getDataForIdentifier:identifier];
	data.shouldForceStatusBar = YES;
	data.statusBarVisibility = visibility;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

-(void) unforceStatusBarVisibilityForApp:(NSString*)identifier completion:(RAMessageCompletionCallback)callback
{
	RAMessageAppData data = [self getDataForIdentifier:identifier];
	data.shouldForceStatusBar = NO;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

-(void) setShouldUseExternalKeyboard:(BOOL)value forApp:(NSString*)identifier completion:(RAMessageCompletionCallback)callback
{
	RAMessageAppData data = [self getDataForIdentifier:identifier];
	data.shouldUseExternalKeyboard = value;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

-(void) receiveShowKeyboardForAppWithIdentifier:(NSString*)identifier
{
	[RASpringBoardKeyboardActivation.sharedInstance showKeyboardForAppWithIdentifier:identifier];
}

-(void) receiveHideKeyboard
{
	[RASpringBoardKeyboardActivation.sharedInstance hideKeyboard];
}

-(void) setKeyboardContextId:(unsigned int)id forIdentifier:(NSString*)identifier
{
	contextIds[identifier] = @(id);
}

-(unsigned int) getStoredKeyboardContextIdForApp:(NSString*)identifier
{
	return [contextIds objectForKey:identifier] != nil ? [contextIds[identifier] unsignedIntValue] : 0;
}

-(NSInteger) keyboardContextIdForIdentifier:(NSString*)identifier
{
	return 0;
}
@end

%ctor
{
	IF_SPRINGBOARD {
		[RAMessagingServer sharedInstance];
	}
}