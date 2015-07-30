#import <UIKit/UIKit.h>
#import "RARemoteKeyboardView.h"

@interface RAKeyboardWindow : UIWindow {
	RARemoteKeyboardView *kbView;
}

-(void) setupForKeyboardAndShow:(NSString*)identifier;
-(void) removeKeyboard;
@end
