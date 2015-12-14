#import "RAKeyboardWindow.h"
#import "headers.h"
#import "RAKeyboardStateListener.h"
#import "RADesktopManager.h"

@implementation RAKeyboardWindow
-(void) setupForKeyboardAndShow:(NSString*)identifier
{
	self.userInteractionEnabled = YES;
	self.backgroundColor = UIColor.clearColor;
	
	if (kbView)
		[self removeKeyboard];

	kbView = [[RARemoteKeyboardView alloc] initWithFrame:UIScreen.mainScreen.bounds];
	[kbView connectToKeyboardWindowForApp:identifier];
	[self addSubview:kbView];

	self.windowLevel = 9999;
	self.frame = UIScreen.mainScreen.bounds;
	[self makeKeyAndVisible];
}

-(void) removeKeyboard
{
	[kbView connectToKeyboardWindowForApp:nil];
	[kbView removeFromSuperview];
	kbView = nil;
}

-(unsigned int) contextId { return kbView.layerHost.contextId; }
@end
