#import <UIKit/UIKit.h>
#import <substrate.h>
#import <SpringBoard/SBApplication.h>
#import "headers.h"
#import "RAWidgetSectionManager.h"
#import "RASettings.h"
#import "RAMessagingClient.h"
#import "RAFakePhoneMode.h"

UIInterfaceOrientation prevousOrientation;
BOOL setPreviousOrientation = NO;
NSInteger wasStatusBarHidden = -1;

NSMutableDictionary *oldFrames = [NSMutableDictionary new];

%hook UIWindow
-(void) setFrame:(CGRect)frame
{
    if ([self.class isEqual:UITextEffectsWindow.class] == NO && [RAMessagingClient.sharedInstance shouldResize])
    {
        if ([oldFrames objectForKey:@(self.hash)] == nil)
            [oldFrames setObject:[NSValue valueWithCGRect:frame] forKey:@(self.hash)];

        frame.origin.x = RAMessagingClient.sharedInstance.currentData.wantedClientOriginX == -1 ? 0 : RAMessagingClient.sharedInstance.currentData.wantedClientOriginX;
        frame.origin.y = RAMessagingClient.sharedInstance.currentData.wantedClientOriginY == -1 ? 0 : RAMessagingClient.sharedInstance.currentData.wantedClientOriginY;
        CGFloat overrideWidth = [RAMessagingClient.sharedInstance resizeSize].width;
        CGFloat overrideHeight = [RAMessagingClient.sharedInstance resizeSize].height;
        if (overrideWidth != -1 && overrideWidth != 0)
            frame.size.width = overrideWidth;
        if (overrideHeight != -1 && overrideHeight != 0)
            frame.size.height = overrideHeight;
    }

    %orig(frame);
    if ([RAMessagingClient.sharedInstance shouldResize] && self.subviews.count > 0 && ([self.class isEqual:UITextEffectsWindow.class] == NO))
    {
        ((UIView*)self.subviews[0]).frame = frame;
    }
}

- (void)_rotateWindowToOrientation:(UIInterfaceOrientation)arg1 updateStatusBar:(BOOL)arg2 duration:(double)arg3 skipCallbacks:(BOOL)arg4
{
    if ([RAMessagingClient.sharedInstance shouldForceOrientation] && arg1 != [RAMessagingClient.sharedInstance forcedOrientation] && [UIApplication.sharedApplication _isSupportedOrientation:arg1])
        return;
    %orig;
}

- (BOOL)_shouldAutorotateToInterfaceOrientation:(int)arg1 checkForDismissal:(BOOL)arg2 isRotationDisabled:(BOOL*)arg3
{
    if ([RAMessagingClient.sharedInstance shouldForceOrientation] && arg1 != [RAMessagingClient.sharedInstance forcedOrientation] && [UIApplication.sharedApplication _isSupportedOrientation:arg1])
        return NO;
    return %orig;
}

- (void)_setWindowInterfaceOrientation:(int)arg1
{
    if ([RAMessagingClient.sharedInstance shouldForceOrientation] && arg1 != [RAMessagingClient.sharedInstance forcedOrientation] && [UIApplication.sharedApplication _isSupportedOrientation:arg1])
        return;
    %orig([RAMessagingClient.sharedInstance shouldForceOrientation] && [UIApplication.sharedApplication _isSupportedOrientation:[RAMessagingClient.sharedInstance forcedOrientation]] ? [RAMessagingClient.sharedInstance forcedOrientation] : arg1);
}

- (void)_sendTouchesForEvent:(id)arg1
{
    %orig;
    if (!IS_SPRINGBOARD)
        [RAMessagingClient.sharedInstance notifySpringBoardOfFrontAppChangeToSelf];
}
%end

%hook UIApplication
- (void)applicationDidResume
{
    %orig;
    if (!IS_SPRINGBOARD)
    {
        [RAMessagingClient.sharedInstance requestUpdateFromServer];
        [RAFakePhoneMode updateAppSizing];
    }
}

+ (void)_startWindowServerIfNecessary
{
    %orig;
    if (!IS_SPRINGBOARD)
    {
        //[RAMessagingClient.sharedInstance requestUpdateFromServer];
        [RAFakePhoneMode updateAppSizing];
    }
}

- (void)_setStatusBarHidden:(BOOL)arg1 animationParameters:(unsafe_id)arg2 changeApplicationFlag:(BOOL)arg3
{
	//if ([RASettings.sharedInstance unifyStatusBar])
    if ([RAMessagingClient.sharedInstance shouldHideStatusBar])
    {
        arg1 = YES;
        arg3 = YES;
    }
    else if ([RAMessagingClient.sharedInstance shouldShowStatusBar])
    {
        arg1 = NO;
        arg3 = YES;
    }
    //arg1 = ((forcingRotation&&NO) || overrideDisplay) ? (isTopApp ? NO : YES) : arg1;
     
    %orig(arg1, arg2, arg3);
}

/*
- (void)_notifySpringBoardOfStatusBarOrientationChangeAndFenceWithAnimationDuration:(double)arg1
{
    if (overrideViewControllerDismissal)
        return;
    %orig;
}
*/

%new -(void) RA_forceRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation isReverting:(BOOL)reverting
{
    if (!reverting)
    {
        if (setPreviousOrientation == NO)
        {
            setPreviousOrientation = YES;
            prevousOrientation = UIApplication.sharedApplication.statusBarOrientation;
            if (wasStatusBarHidden == -1)
                wasStatusBarHidden = UIApplication.sharedApplication.statusBarHidden;
        }
    }
    else if (setPreviousOrientation)
    {
        orientation = prevousOrientation;

        setPreviousOrientation = NO;
    }

    if (![UIApplication.sharedApplication _isSupportedOrientation:orientation])
    {
        return;
    }

    for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
        [window _setRotatableViewOrientation:orientation updateStatusBar:YES duration:0.25 force:YES];
    }
}

%new -(void) RA_forceStatusBarVisibility:(BOOL)visible orRevert:(BOOL)revert
{
    if (revert)
    {
        if (wasStatusBarHidden != -1)
        {
            [UIApplication.sharedApplication _setStatusBarHidden:wasStatusBarHidden animationParameters:nil changeApplicationFlag:YES];
        }
    }
    else
    {
        if (wasStatusBarHidden == -1)
            wasStatusBarHidden = UIApplication.sharedApplication.statusBarHidden;
        [UIApplication.sharedApplication _setStatusBarHidden:visible animationParameters:nil changeApplicationFlag:YES];
    }
}

%new -(void) RA_updateWindowsForSizeChange:(CGSize)size isReverting:(BOOL)revert
{
    if (revert)
    {
        for (UIWindow *window in [[UIApplication sharedApplication] windows]) 
        {
            CGRect frame = window.frame;
            if ([oldFrames objectForKey:@(window.hash)] != nil)
            {
                frame = [[oldFrames objectForKey:@(window.hash)] CGRectValue];
                [oldFrames removeObjectForKey:@(window.hash)];
            }

            [UIView animateWithDuration:0.4 animations:^{
                [window setFrame:frame];
            }];
        }
        
        if ([oldFrames objectForKey:@"statusBar"] != nil)
            UIApplication.sharedApplication.statusBar.frame = [oldFrames[@"statusBar"] CGRectValue];

        return;
    }

    if (size.width != -1)
    {
        if ([oldFrames objectForKey:@"statusBar"] == nil)
            [oldFrames setObject:[NSValue valueWithCGRect:UIApplication.sharedApplication.statusBar.frame] forKey:@"statusBar"];
        UIApplication.sharedApplication.statusBar.frame = CGRectMake(0, 0, size.width, UIApplication.sharedApplication.statusBar.frame.size.height);
    }

    for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
        if ([oldFrames objectForKey:@(window.hash)] == nil)
            [oldFrames setObject:[NSValue valueWithCGRect:window.frame] forKey:@(window.hash)];

        [UIView animateWithDuration:0.3 animations:^{
            [window setFrame:window.frame]; // updates with client message app data in the setFrame: hook
        }];
    }
}

-(BOOL) isNetworkActivityIndicatorVisible
{
    if ([RAMessagingClient.sharedInstance isBeingHosted])
        return [objc_getAssociatedObject(self, @selector(RA_networkActivity)) boolValue];
    else
        return %orig;
}

-(void) setNetworkActivityIndicatorVisible:(BOOL)arg1
{
    %orig(arg1);
    if ([RAMessagingClient.sharedInstance isBeingHosted])
    {
        objc_setAssociatedObject(self, @selector(RA_networkActivity), @(arg1), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        StatusBarData *data = [UIStatusBarServer getStatusBarData];
        data->itemIsEnabled[24] = arg1; // 24 = activity indicator
        [UIApplication.sharedApplication.statusBar forceUpdateToData:data animated:YES];   
    }
}

-(BOOL) openURL:(NSURL*)url
{
    if ([RAMessagingClient.sharedInstance isBeingHosted] || [RASettings.sharedInstance openLinksInWindows])
    {
        return [RAMessagingClient.sharedInstance notifyServerToOpenURL:url openInWindow:[RASettings.sharedInstance openLinksInWindows]];
    }
    return %orig;
}
%end

%hook UIStatusBar
-(void) statusBarServer:(unsafe_id)arg1 didReceiveStatusBarData:(StatusBarData*)arg2 withActions:(int)arg3
{
    if ([RAMessagingClient.sharedInstance isBeingHosted])
        arg2->itemIsEnabled[24] = [UIApplication.sharedApplication isNetworkActivityIndicatorVisible];
    %orig;
}
%end

void reloadSettings(CFNotificationCenterRef center,
                    void *observer,
                    CFStringRef name,
                    const void *object,
                    CFDictionaryRef userInfo)
{
    [RASettings.sharedInstance reloadSettings];
}

%ctor
{
    %init;

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &reloadSettings, CFSTR("com.efrederickson.reachapp.settings/reloadSettings"), NULL, 0);
    reloadSettings(NULL, NULL, NULL, NULL, NULL);
}
