#import "RAKeyboardStateListener.h"

@implementation RAKeyboardStateListener
+ (instancetype)sharedInstance
{
    SHARED_INSTANCE(RAKeyboardStateListener);
}

- (void)didShow:(NSNotification*)notif
{
    _visible = YES;
    _size = [[notif.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.keyboard.didShow"), NULL, (__bridge CFDictionaryRef)@{ @"size": NSStringFromCGSize(_size) }, true);
}

- (void)didHide
{
    _visible = NO;
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.reachapp.keyboard.didHide"), NULL, NULL, true);
}

- (id)init
{
    if ((self = [super init])) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(didShow:) name:UIKeyboardDidShowNotification object:nil];
        [center addObserver:self selector:@selector(didHide) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

-(void) _setVisible:(BOOL)val { _visible = val; }
-(void) _setSize:(CGSize)size { _size = size; }
@end

void externalKeyboardDidShow(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
    NSLog(@"[ReachApp] externalKeyboardDidShow");
    CGSize size = CGSizeFromString(((__bridge NSDictionary*)userInfo)[@"size"]);

    [RAKeyboardStateListener.sharedInstance _setVisible:YES];
    [RAKeyboardStateListener.sharedInstance _setSize:size];
}

void externalKeyboardDidHide(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
    NSLog(@"[ReachApp] externalKeyboardDidHide");
    [RAKeyboardStateListener.sharedInstance _setVisible:NO];
}

%ctor
{
    if ([NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"])
    {
        [RAKeyboardStateListener sharedInstance];

        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, externalKeyboardDidShow, CFSTR("com.efrederickson.reachapp.keyboard.didShow"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, externalKeyboardDidHide, CFSTR("com.efrederickson.reachapp.keyboard.didHide"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    }
}