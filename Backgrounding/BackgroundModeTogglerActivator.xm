#import <libactivator/libactivator.h>
#import "RABackgrounder.h"

@interface RAActivatorBackgrounderToggleModeListener : NSObject <LAListener, UIAlertViewDelegate>
@end

static RAActivatorBackgrounderToggleModeListener *sharedInstance$RAActivatorBackgrounderToggleModeListener;

@implementation RAActivatorBackgrounderToggleModeListener
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event
{
    SBApplication *app = [UIApplication sharedApplication]._accessibilityFrontMostApplication;

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Multiplexer" message:[NSString stringWithFormat:@"Which backgrounding mode would you like to enable for %@?",app.displayName] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Force Foreground", @"Native", @"Suspend Immediately", @"Disable", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    SBApplication *app = [UIApplication sharedApplication]._accessibilityFrontMostApplication;

    if (buttonIndex == 0)
    {
        // Force foreground
        [RABackgrounder.sharedInstance temporarilyApplyBackgroundingMode:RABackgroundModeForcedForeground forApplication:app andCloseForegroundApp:YES];
    }
    else if (buttonIndex == 1)
    {
        // Native
        [RABackgrounder.sharedInstance temporarilyApplyBackgroundingMode:RABackgroundModeNative forApplication:app andCloseForegroundApp:YES];
    }
    else if (buttonIndex == 2)
    {
        // Disabled
        [RABackgrounder.sharedInstance temporarilyApplyBackgroundingMode:RABackgroundModeForceNone forApplication:app andCloseForegroundApp:YES];
        
    }
    else if (buttonIndex == 3)
    {
        // Suspend Immediately
        [RABackgrounder.sharedInstance temporarilyApplyBackgroundingMode:RABackgroundModeSuspendImmediately forApplication:app andCloseForegroundApp:YES];
        
    }
    else
    {

    }
}
@end

%ctor
{
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"])
    {
        sharedInstance$RAActivatorBackgrounderToggleModeListener = [[RAActivatorBackgrounderToggleModeListener alloc] init];
        [[%c(LAActivator) sharedInstance] registerListener:sharedInstance$RAActivatorBackgrounderToggleModeListener forName:@"com.efrederickson.reachapp.backgrounder.togglemode"];
    }
}