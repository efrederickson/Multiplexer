#import "RAFakePhoneMode.h"
#import "RAMessagingClient.h"
#import "RAMessagingServer.h"

#define RA_4S_SIZE CGSizeMake(320, 480)
#define RA_5S_SIZE CGSizeMake(320, 512)
#define RA_6P_SIZE CGSizeMake(414, 736)


BOOL ignorePhoneMode = NO;
CGSize forcePhoneModeSize = RA_6P_SIZE;

@implementation RAFakePhoneMode
+(CGSize) fakedSize
{
	return forcePhoneModeSize;
}

+(CGSize) fakeSizeForAppWithIdentifier:(NSString*)identifier
{
	return forcePhoneModeSize;
}

+(BOOL) shouldFakeForAppWithIdentifier:(NSString*)identifier
{
	IF_SPRINGBOARD {
		return [RAMessagingServer.sharedInstance getDataForIdentifier:identifier].forcePhoneMode;
	}
	NSLog(@"[ReachApp] WARNING: +[RAFakePhoneMode shouldFakeForAppWithIdentifier:] called from outside SpringBoard!");
	return NO;
}

+(BOOL) shouldFakeForThisProcess
{
    if (!RAMessagingClient.sharedInstance.hasRecievedData)
    {
        ignorePhoneMode = YES;
        [RAMessagingClient.sharedInstance requestUpdateFromServer];
        ignorePhoneMode = NO;
    }

    return RAMessagingClient.sharedInstance.currentData.forcePhoneMode;
}
@end

/*
%hook UIApplication
/*
-(BOOL) _isClassic
{
    return %orig;

    if (IS_SPRINGBOARD || ignorePhoneMode)
        return %orig;

    if (!RAMessagingClient.sharedInstance.hasRecievedData)
    {
        ignorePhoneMode = YES;
        [RAMessagingClient.sharedInstance requestUpdateFromServer];
        ignorePhoneMode = NO;
    }

    if (RAMessagingClient.sharedInstance.currentData.forcePhoneMode)
        return YES;

    return %orig;
}

- (void)_setClassicMode:(int)arg1
{
    %orig;
    // 0 = no classic
    // 1 = standard
    // 2 = 5/5s?
    // 3 - 6 = standard
}

-(UIInterfaceOrientation) statusBarOrientation { return UIInterfaceOrientationPortrait; }
- (int)_currentExpectedInterfaceOrientation { return UIInterfaceOrientationPortrait; }
- (int)_expectedViewOrientation { return UIInterfaceOrientationPortrait; }
- (int)_frontMostAppOrientation { return UIInterfaceOrientationPortrait; }
- (int)_getSpringBoardOrientation { return UIInterfaceOrientationPortrait; }
- (int)activeInterfaceOrientation { return UIInterfaceOrientationPortrait; }
- (int)alertInterfaceOrientation { return UIInterfaceOrientationPortrait; }
%end
*/

%hook UIDevice
-(UIUserInterfaceIdiom) userInterfaceIdiom
{
    if (IS_SPRINGBOARD || ignorePhoneMode)
        return %orig;

    if ([RAFakePhoneMode shouldFakeForThisProcess])
        return UIUserInterfaceIdiomPhone;

    return %orig;
}
%end

%hook UIScreen
- (CGRect)_unjailedReferenceBounds
{
    if (IS_SPRINGBOARD || ignorePhoneMode)
        return %orig;

    if ([RAFakePhoneMode shouldFakeForThisProcess])
    {
        CGRect o = %orig;
        o.size = [RAFakePhoneMode fakedSize];
        return o;
    }

    return %orig;
}

- (CGRect)_referenceBounds
{
    if (IS_SPRINGBOARD || ignorePhoneMode)
        return %orig;

    if ([RAFakePhoneMode shouldFakeForThisProcess])
    {
        CGRect o = %orig;
        o.size = [RAFakePhoneMode fakedSize];
        return o;
    }

    return %orig;
}

- (CGRect)_interfaceOrientedBounds
{
    if (IS_SPRINGBOARD || ignorePhoneMode)
        return %orig;

    if ([RAFakePhoneMode shouldFakeForThisProcess])
    {
        CGRect o = %orig;
        o.size = [RAFakePhoneMode fakedSize];
        return o;
    }

    return %orig;
}

- (CGRect)bounds
{
    if (IS_SPRINGBOARD || ignorePhoneMode)
        return %orig;

    if ([RAFakePhoneMode shouldFakeForThisProcess])
    {
        CGRect o = %orig;
        o.size = [RAFakePhoneMode fakedSize];
        return o;
    }

    return %orig;
}

- (CGRect)nativeBounds
{
    if (IS_SPRINGBOARD || ignorePhoneMode)
        return %orig;

    if ([RAFakePhoneMode shouldFakeForThisProcess])
    {
        CGRect o = %orig;
     	o.size = CGSizeMake([RAFakePhoneMode fakedSize].width * self.scale, [RAFakePhoneMode fakedSize].height * self.scale);
        return o;
    }

    return %orig;
}

- (CGRect)applicationFrame
{
    if (IS_SPRINGBOARD || ignorePhoneMode)
        return %orig;

    if ([RAFakePhoneMode shouldFakeForThisProcess])
    {
        CGRect o = %orig;
        o.size = [RAFakePhoneMode fakedSize];
        return o;
    }

    return %orig;
}
- (CGRect)_boundsForInterfaceOrientation:(int)arg1
{
    if (IS_SPRINGBOARD || ignorePhoneMode)
        return %orig;

    if ([RAFakePhoneMode shouldFakeForThisProcess])
    {
        CGRect o = %orig;
        o.size = [RAFakePhoneMode fakedSize];
        return o;
    }

    return %orig;
}

- (CGRect)_applicationFrameForInterfaceOrientation:(int)arg1 usingStatusbarHeight:(float)arg2 ignoreStatusBar:(BOOL)arg3
{
    if (IS_SPRINGBOARD || ignorePhoneMode)
        return %orig;

    if ([RAFakePhoneMode shouldFakeForThisProcess])
    {
        CGRect o = %orig;
        o.size = [RAFakePhoneMode fakedSize];
        return o;
    }

    return %orig;
}
- (CGRect)_applicationFrameForInterfaceOrientation:(int)arg1 usingStatusbarHeight:(float)arg2
{
    if (IS_SPRINGBOARD || ignorePhoneMode)
        return %orig;

    if ([RAFakePhoneMode shouldFakeForThisProcess])
    {
        CGRect o = %orig;
        o.size = [RAFakePhoneMode fakedSize];
        return o;
    }

    return %orig;
}
- (CGRect)_applicationFrameForInterfaceOrientation:(int)arg1
{
    if (IS_SPRINGBOARD || ignorePhoneMode)
        return %orig;

    if ([RAFakePhoneMode shouldFakeForThisProcess])
    {
        CGRect o = %orig;
        o.size = [RAFakePhoneMode fakedSize];
        return o;
    }

    return %orig;
}
%end