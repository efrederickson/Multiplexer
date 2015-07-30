#import "RARemoteKeyboardView.h"
#import "headers.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <Foundation/Foundation.h>

CPDistributedMessagingCenter *messagingCenter;

@implementation RARemoteKeyboardView
@synthesize layerHost = _layerHost;

-(void) connectToKeyboardWindowForApp:(NSString*)identifier
{
	if (!identifier)
    {
        self.layerHost.contextId = 0;
		return;
    }
    _identifier = identifier;

    messagingCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.efrederickson.reachapp.keyboardMessaging"];        
    void* handle = dlopen("/usr/lib/librocketbootstrap.dylib", RTLD_LAZY);
    if(handle)
    {
        void (*rocketbootstrap_distributedmessagingcenter_apply)(CPDistributedMessagingCenter*);
        rocketbootstrap_distributedmessagingcenter_apply = (void(*)(CPDistributedMessagingCenter*))dlsym(handle, "rocketbootstrap_distributedmessagingcenter_apply");
        rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
    }

    NSDictionary *reply = [messagingCenter sendMessageAndReceiveReplyName:@"getContextIdForIdentifier" userInfo:@{ @"bundleIdentifier": identifier }];
    
    NSNumber *number = [reply objectForKey:@"contextId"];
    self.layerHost.contextId = [number unsignedIntValue];
    
    NSLog(@"[ReachApp] loaded keyboard view with %@", number);
}

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        self.userInteractionEnabled = YES;
        self.layerHost = [[CALayerHost alloc] init];
        self.layerHost.anchorPoint = CGPointMake(0, 0);
        self.layerHost.transform = CATransform3DMakeScale(1/[UIScreen mainScreen].scale, 1/[UIScreen mainScreen].scale, 1);
        self.layerHost.bounds = self.bounds;
        [self.layer addSublayer:self.layerHost];
        update = NO;
    }
    
    return self;
}
-(void)dealloc
{
    self.layerHost = nil;
}
@end

%hook UIKeyboard
-(void) activate
{
    %orig;

    unsigned int contextID = UITextEffectsWindow.sharedTextEffectsWindow._contextId;

    NSNumber *number = [NSNumber numberWithUnsignedInt:contextID];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[@"contextId"] = number;
    dictionary[@"bundleIdentifier"] = NSBundle.mainBundle.bundleIdentifier;

    if (!messagingCenter)
    {
        messagingCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.efrederickson.reachapp.keyboardMessaging"];
        void* handle = dlopen("/usr/lib/librocketbootstrap.dylib", RTLD_LAZY);
        if(handle)
        {
            void (*rocketbootstrap_distributedmessagingcenter_apply)(CPDistributedMessagingCenter*);
            rocketbootstrap_distributedmessagingcenter_apply = (void(*)(CPDistributedMessagingCenter*))dlsym(handle, "rocketbootstrap_distributedmessagingcenter_apply");
            rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
        }
    }

    [messagingCenter sendMessageName:@"setContextId:forIdentifier:" userInfo:dictionary];
}
%end

