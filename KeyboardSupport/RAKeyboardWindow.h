#import <UIKit/UIKit.h>

@interface RAKeyboardWindow : UIWindow {
	UITextField *_textField;
}

-(void) setupForKeyboardAndShow;
-(void) resignKeyboard;
@end
