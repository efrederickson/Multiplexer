#include <dlfcn.h>
#include <notify.h>
#include <stdio.h>
#include <stdlib.h>
#import <Foundation/Foundation.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <objc/runtime.h>

@interface RAKBDaemon : NSObject {
	CPDistributedMessagingCenter *messagingCenter;
	CPDistributedMessagingCenter *springboardCenter;
	NSMutableDictionary *contexts;
}
@end

@implementation RAKBDaemon
-(id) init
{
	if (self = [super init])
	{
		contexts = [NSMutableDictionary dictionary];
        messagingCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.efrederickson.reachapp.keyboardMessaging"];

        springboardCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.efrederickson.reachapp.keyboardMessaging.springBoard"];

        void* handle = dlopen("/usr/lib/librocketbootstrap.dylib", RTLD_LAZY);
        if(handle)
        {
            void (*rocketbootstrap_distributedmessagingcenter_apply)(CPDistributedMessagingCenter*);
            rocketbootstrap_distributedmessagingcenter_apply = (void(*)(CPDistributedMessagingCenter*))dlsym(handle, "rocketbootstrap_distributedmessagingcenter_apply");
            rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
            rocketbootstrap_distributedmessagingcenter_apply(springboardCenter);
        }

        [messagingCenter runServerOnCurrentThread];
        [messagingCenter registerForMessageName:@"setContextId:forIdentifier:" target:self selector:@selector(setContextId:userInfo:)];
        [messagingCenter registerForMessageName:@"getContextIdForIdentifier" target:self selector:@selector(getContextId:userInfo:)];
	    [messagingCenter registerForMessageName:@"showKeyboardForAppWithIdentifier" target:self selector:@selector(showKeyboardForAppWithIdentifier:userInfo:)];
	    [messagingCenter registerForMessageName:@"hideKeyboardForAppWithIdentifier" target:self selector:@selector(hideKeyboardForAppWithIdentifier:userInfo:)];
	}
	return self;
}

-(NSDictionary*) setContextId:(NSString*)name userInfo:(id)userInfo
{
	NSString *bundleIdentifier = userInfo[@"bundleIdentifier"];
	NSNumber *contextId = userInfo[@"contextId"];

	if (bundleIdentifier && contextId)
		contexts[bundleIdentifier] = contextId;

	return nil;
}

-(NSDictionary*)getContextId:(NSString*)name userInfo:(id)userInfo
{
	NSString *bundleIdentifier = userInfo[@"bundleIdentifier"];
	NSNumber *number = [contexts objectForKey:bundleIdentifier];

	if (bundleIdentifier && number)
	{
    	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObject:contexts[bundleIdentifier] forKey:@"contextId"];
    	return dictionary;
    }
    return nil;
}

-(void) showKeyboardForAppWithIdentifier:(NSString*)name userInfo:(NSDictionary*)userInfo
{
	NSLog(@"[ReachApp] server received showKeyboardForAppWithIdentifier:");
	[springboardCenter sendMessageName:name userInfo:userInfo];
}

-(void) hideKeyboardForAppWithIdentifier:(NSString*)name userInfo:(NSDictionary*)userInfo
{
	NSLog(@"[ReachApp] server received hideKeyboardForAppWithIdentifier:");
	[springboardCenter sendMessageName:name userInfo:userInfo];
}

-(void) empty_:(id)arg { /* dummy method for timer */ }
@end

int main(int argc, char **argv, char **envp) {
	@autoreleasepool {
		static RAKBDaemon *daemon = [RAKBDaemon new];

		NSTimer *timer = [[NSTimer alloc] initWithFireDate:[NSDate date]
			interval:99999
			target:daemon
			selector:@selector(empty_:)
			userInfo:nil
			repeats:NO];

		NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
		[runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
		[runLoop run];
	}
	return 0;
}