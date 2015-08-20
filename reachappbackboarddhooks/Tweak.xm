#import <IOKit/hid/IOHIDEventSystem.h>
#import <IOKit/IOKit.h>
#import <substrate.h>
#import "RAMessaging.h"
#import <AppSupport/CPDistributedMessagingCenter.h>

#define CTRL_KEY 224
#define CMD_KEY 231 
#define CMD_KEY2 227
#define SHIFT_KEY 229
#define SHIFT_KEY2 225
#define ALT_KEY 226 
#define ALT_KEY2 230

#define ARROW_RIGHT_KEY 79
#define ARROW_LEFT_KEY 80
#define ARROW_UP_KEY 82
#define ARROW_DOWN_KEY 81
#define EQUALS_OR_PLUS_KEY 46

IOHIDEventSystemCallback eventCallback = NULL;
BOOL isControlKeyDown = NO;
BOOL isWindowsKeyDown = NO;
BOOL isShiftKeyDown = NO;
BOOL isAltKeyDown = NO;

CPDistributedMessagingCenter *center;

void handle_event (void* target, void* refcon, IOHIDServiceRef service, IOHIDEventRef event) 
{
	if (IOHIDEventGetType(event) == kIOHIDEventTypeKeyboard)
	{
		IOHIDEventRef event2 = IOHIDEventCreateCopy(kCFAllocatorDefault, event);

		BOOL isDown = IOHIDEventGetIntegerValue(event2, kIOHIDEventFieldKeyboardDown);
		int key = IOHIDEventGetIntegerValue(event2, kIOHIDEventFieldKeyboardUsage);

		if (key == CTRL_KEY)
			isControlKeyDown = isDown;
		else if (key == CMD_KEY || key == CMD_KEY2)
			isWindowsKeyDown = isDown;
		else if (key == SHIFT_KEY || key == SHIFT_KEY2)
			isShiftKeyDown = isDown;
		else if (key == ALT_KEY || key == ALT_KEY2)
			isAltKeyDown = isDown;
		else if (isDown && isControlKeyDown && isAltKeyDown)
		{
			// Snap
			if (key == ARROW_LEFT_KEY)
			{
				[center sendMessageName:RAMessagingCTRLLeftMessageName userInfo:nil];
			}
			else if (key == ARROW_RIGHT_KEY)
			{
				[center sendMessageName:RAMessagingCTRLRightMessageName userInfo:nil];
			}
			else if (key == ARROW_UP_KEY)
			{
				[center sendMessageName:RAMessagingCTRLUpMessageName userInfo:nil];
			}
			else if (key == ARROW_DOWN_KEY)
			{
				[center sendMessageName:RAMessagingCTRLDownMessageName userInfo:nil];	
			}
		}
		else if (isDown && isWindowsKeyDown)
		{
			if (key == ARROW_LEFT_KEY)
			{
				[center sendMessageName:RAMessagingWINLeftMessageName userInfo:nil];
			}
			else if (key == ARROW_RIGHT_KEY)
			{
				[center sendMessageName:RAMessagingWINRightMessageName userInfo:nil];
			}
			else if (isShiftKeyDown && key == EQUALS_OR_PLUS_KEY)
			{
				[center sendMessageName:RAMessagingWINSHIFTPlusMessageName userInfo:nil];	
			}
		}
	}

	eventCallback(target, refcon, service, event);
}

Boolean (*orig$IOHIDEventSystemOpen)(IOHIDEventSystemRef system, IOHIDEventSystemCallback callback, void* target, void* refcon, void* unused);
Boolean hook$IOHIDEventSystemOpen(IOHIDEventSystemRef system, IOHIDEventSystemCallback callback, void* target, void* refcon, void* unused)
{
	eventCallback = callback;
	return orig$IOHIDEventSystemOpen(system, handle_event, target, refcon, unused);	
}

%hook BKEventFocusManager
@interface BKEventDestination
-(id ) initWithPid:(unsigned int)arg1 clientID:(NSString*)arg2;
@end

-(id) destinationForFocusedEventWithDisplay:(__unsafe_unretained id)arg1 
{
	NSDictionary *response = [center sendMessageAndReceiveReplyName:RAMessagingFrontMostAppInfo userInfo:nil];

	if (response)
	{
		int pid = [response[@"pid"] unsignedIntValue];
		NSString *clientId = response[@"bundleIdentifier"];

		return [[[objc_getClass("BKEventDestination") alloc] initWithPid:pid clientID:clientId] autorelease];
	}
	return %orig;
}
%end


%ctor
{
	MSHookFunction(&IOHIDEventSystemOpen, hook$IOHIDEventSystemOpen, &orig$IOHIDEventSystemOpen);

	center = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.efrederickson.reachapp.messaging.server"];

	void* handle = dlopen("/usr/lib/librocketbootstrap.dylib", RTLD_LAZY);
	if(handle)
	{
	    void (*rocketbootstrap_distributedmessagingcenter_apply)(CPDistributedMessagingCenter*);
	    rocketbootstrap_distributedmessagingcenter_apply = (void(*)(CPDistributedMessagingCenter*))dlsym(handle, "rocketbootstrap_distributedmessagingcenter_apply");
	    rocketbootstrap_distributedmessagingcenter_apply(center);
	    dlclose(handle);
	}
}