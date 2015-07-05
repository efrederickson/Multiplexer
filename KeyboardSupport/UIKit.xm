#import "headers.h"
#import <execinfo.h>

extern BOOL isTopApp;
extern NSString *bundleIdentifierThatWantsKeyboard;
BOOL shouldOverrideKeyboard = NO;
BOOL shouldSendKeyEvents;

#define SEND_CHAR(c) \
	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.handleKeyEvent"), NULL, (__bridge CFDictionaryRef)@{ @"bundleIdentifier": bundleIdentifierThatWantsKeyboard, @"keyCode": [NSNumber numberWithChar:c] }, NO);

%hook UITextField
//- (void)_becomeFirstResponder
- (BOOL)becomeFirstResponder
{
    if (isTopApp)
    	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.updateKeyboardWindow"), NULL, (__bridge CFDictionaryRef)@{ @"bundleIdentifier": NSBundle.mainBundle.bundleIdentifier, @"wantsKeyboard": @YES}, NO);

    return %orig;
}

- (void)_endedEditing
{
    %orig;
    if (isTopApp)
    	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.updateKeyboardWindow"), NULL, (__bridge CFDictionaryRef)@{ @"bundleIdentifier": NSBundle.mainBundle.bundleIdentifier, @"wantsKeyboard": @NO}, NO);
}

- (BOOL)resignFirstResponder
{
    if (isTopApp)
    	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.updateKeyboardWindow"), NULL, (__bridge CFDictionaryRef)@{ @"bundleIdentifier": NSBundle.mainBundle.bundleIdentifier, @"wantsKeyboard": @NO}, NO);
    return %orig;
}

-(void) insertText:(NSString*)text
{
    if (bundleIdentifierThatWantsKeyboard) // a.k.a. this process is SpringBoard
    {
		unichar buffer[text.length+1];
		[text getCharacters:buffer range:NSMakeRange(0, text.length)];

        for (int i = 0; i < text.length; i++)
        	SEND_CHAR(buffer[i]);
    }
    else
        %orig;
}
%end

%hook UITextView
- (BOOL)becomeFirstResponder
{
    if (isTopApp)
    {
        NSLog(@"[ReachApp] text view FR");
        CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.updateKeyboardWindow"), NULL, (__bridge CFDictionaryRef)@{ @"bundleIdentifier": NSBundle.mainBundle.bundleIdentifier, @"wantsKeyboard": @YES}, NO);
    }

    return %orig;
}

- (BOOL)resignFirstResponder
{
    if (isTopApp)
        CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.updateKeyboardWindow"), NULL, (__bridge CFDictionaryRef)@{ @"bundleIdentifier": NSBundle.mainBundle.bundleIdentifier, @"wantsKeyboard": @NO}, NO);
    return %orig;
}
%end

%hook UIKeyboardAutomatic
- (void)activate
{
    if (isTopApp)
        [%c(UIKeyboardImpl) performSelector:@selector(hardwareKeyboardAvailabilityChanged)];
    %orig;
}
%end
%hook UIKeyboardImpl
-(void) hardwareKeyboardAvailabilityChanged
{
    %orig;
    [self setInHardwareKeyboardMode:YES];
}

- (void)setInHardwareKeyboardMode:(BOOL)arg1
{
    if (isTopApp)
        arg1 = YES;
    %orig(arg1);
}
%end

%hook UITextInputController
- (void)_insertText:(NSString*)arg1 fromKeyboard:(BOOL)arg2
{
    if (bundleIdentifierThatWantsKeyboard)
    {
		unichar buffer[arg1.length+1];
		[arg1 getCharacters:buffer range:NSMakeRange(0, arg1.length)];

        for (int i = 0; i < arg1.length; i++)
        	SEND_CHAR(buffer[i]);
    }
    else
        %orig;
}

- (void)deleteBackward
{
    if (bundleIdentifierThatWantsKeyboard)
    {
        SEND_CHAR('\b');
    }
    %orig;
}
%end


void handleKeyEvent(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	NSDictionary *d = (__bridge NSDictionary*)userInfo;
	if ([d[@"bundleIdentifier"] isEqual:NSBundle.mainBundle.bundleIdentifier] == NO)
		return;
	char c = (char)[d[@"keyCode"] shortValue];
	NSString *str = [NSString stringWithFormat:@"%c" , c];
    UIPhysicalKeyboardEvent *k = [%c(UIPhysicalKeyboardEvent) _eventWithInput:nil inputFlags:0];
    k._privateInput = str;
    k._modifiedInput = str;
    k._unmodifiedInput = str;
    [UIApplication.sharedApplication _handleKeyUIEvent:k];
}

%ctor
{
    if ([NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"])
        return;

	CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, handleKeyEvent, CFSTR("com.efrederickson.reachapp.handleKeyEvent"), NULL, CFNotificationSuspensionBehaviorDrop);
	shouldSendKeyEvents = [NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"];
}
