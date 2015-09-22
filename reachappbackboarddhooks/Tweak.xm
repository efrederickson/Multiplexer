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
#define D_KEY 7
#define P_KEY 19
#define BKSPCE_KEY 42
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

// TODO: Ensure all keyboard commands do not conflict with
// https://support.apple.com/en-us/HT201236

void handle_event(void *target, void *refcon, IOHIDServiceRef service, IOHIDEventRef event) 
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
		else if (isDown && isWindowsKeyDown && isControlKeyDown)
		{
			if (key == ARROW_LEFT_KEY)
			{
				[center sendMessageName:RAMessagingGoToDesktopOnTheLeftMessageName userInfo:nil];
			}
			else if (key == ARROW_RIGHT_KEY)
			{
				[center sendMessageName:RAMessagingGoToDesktopOnTheRightMessageName userInfo:nil];
			}
			else if (key == BKSPCE_KEY)
			{
				[center sendMessageName:RAMessagingDetachCurrentAppMessageName userInfo:nil];
			}
			else if (key == D_KEY || key == EQUALS_OR_PLUS_KEY)
			{

				[center sendMessageName:RAMessagingAddNewDesktopMessageName userInfo:nil];
			}
		}
		else if (isDown && isWindowsKeyDown && isAltKeyDown)
		{
			if (key == ARROW_LEFT_KEY)
			{
				[center sendMessageName:RAMessagingSnapFrontMostWindowLeftMessageName userInfo:nil];
			}
			else if (key == ARROW_RIGHT_KEY)
			{
				[center sendMessageName:RAMessagingSnapFrontMostWindowRightMessageName userInfo:nil];
			}
			else if (key == ARROW_UP_KEY)
			{
				[center sendMessageName:RAMessagingMaximizeAppMessageName userInfo:nil];
			}
			else if (key == ARROW_DOWN_KEY)
			{
				[center sendMessageName:RAMessagingCloseAppMessageName userInfo:nil];	
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
	NSDictionary *response = [center sendMessageAndReceiveReplyName:RAMessagingGetFrontMostAppInfoMessageName userInfo:nil];

	if (response)
	{
		int pid = [response[@"pid"] unsignedIntValue];
		NSString *clientId = response[@"bundleIdentifier"];

		if (pid && clientId)
			return [[[objc_getClass("BKEventDestination") alloc] initWithPid:pid clientID:clientId] autorelease];
	}
	return %orig;
}
%end

/*
%hook CAWindowServerDisplay
- (unsigned int)contextIdAtPosition:(CGPoint)point
{
    unsigned int cid = %orig;

    if (keyboardWindow)
    {
        if (cid == keyboardWindow.contextId)
        {
            UIGraphicsBeginImageContextWithOptions(keyboardWindow.bounds.size, keyboardWindow.opaque, 0.0);
            [keyboardWindow drawViewHierarchyInRect:keyboardWindow.bounds afterScreenUpdates:NO];
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();

            unsigned char pixel[1] = {0};
            CGContextRef context = CGBitmapContextCreate(pixel,
                                                         1, 1, 8, 1, NULL,
                                                         kCGImageAlphaOnly);
            UIGraphicsPushContext(context);
            [image drawAtPoint:CGPointMake(-point.x, -point.y)];
            UIGraphicsPopContext();
            CGContextRelease(context);
            CGFloat alpha = pixel[0]/255.0f;
            BOOL transparent = alpha < 1.f; 
            if (!transparent)
                return cid;
        }
    }
    return cid;
}
%end
*/

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