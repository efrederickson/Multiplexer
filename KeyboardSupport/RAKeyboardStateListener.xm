#import "RAKeyboardStateListener.h"
#import "headers.h"
#import <execinfo.h>
#import <AppSupport/CPDistributedMessagingCenter.h>

extern BOOL overrideDisplay;
BOOL isShowing = NO;
extern CPDistributedMessagingCenter *messagingCenter;

@implementation RAKeyboardStateListener
+ (instancetype)sharedInstance
{
    SHARED_INSTANCE(RAKeyboardStateListener);
}

- (void)didShow:(NSNotification*)notif
{
    NSLog(@"[ReachApp] keyboard didShow");
    _visible = YES;
    _size = [[notif.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.keyboard.didShow"), NULL, (__bridge CFDictionaryRef)@{ @"size": NSStringFromCGSize(_size) }, true);

    if (overrideDisplay)
    {
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

        [messagingCenter sendMessageName:@"showKeyboardForAppWithIdentifier" userInfo:@{ @"bundleIdentifier": NSBundle.mainBundle.bundleIdentifier }];
        isShowing = YES;
    }
}

- (void)didHide
{
    NSLog(@"[ReachApp] keyboard didHide");
    _visible = NO;
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.reachapp.keyboard.didHide"), NULL, NULL, true);

    if (overrideDisplay || isShowing)
    {
        isShowing = NO;
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

        [messagingCenter sendMessageName:@"hideKeyboardForAppWithIdentifier" userInfo:@{ @"bundleIdentifier": NSBundle.mainBundle.bundleIdentifier }];
    }
}

- (id)init
{
    if ((self = [super init])) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(didShow:) name:UIKeyboardDidShowNotification object:nil];
        [center addObserver:self selector:@selector(didHide) name:UIKeyboardWillHideNotification object:nil];
        [center addObserver:self selector:@selector(didHide) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

-(void) _setVisible:(BOOL)val { _visible = val; }
-(void) _setSize:(CGSize)size { _size = size; }
@end

void externalKeyboardDidShow(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
    //NSLog(@"[ReachApp] externalKeyboardDidShow");
    CGSize size = CGSizeFromString(((__bridge NSDictionary*)userInfo)[@"size"]);

    [RAKeyboardStateListener.sharedInstance _setVisible:YES];
    [RAKeyboardStateListener.sharedInstance _setSize:size];
}

void externalKeyboardDidHide(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
    //NSLog(@"[ReachApp] externalKeyboardDidHide");
    [RAKeyboardStateListener.sharedInstance _setVisible:NO];
}

%ctor
{
    // Any process
    [RAKeyboardStateListener sharedInstance];

    // Just SpringBoard
    if ([NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"])
    {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, externalKeyboardDidShow, CFSTR("com.efrederickson.reachapp.keyboard.didShow"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, externalKeyboardDidHide, CFSTR("com.efrederickson.reachapp.keyboard.didHide"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    }
}