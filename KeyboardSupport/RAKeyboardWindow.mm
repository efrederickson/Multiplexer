#import "RAKeyboardWindow.h"
#import "headers.h"
#import "RAKeyboardStateListener.h"

@implementation RAKeyboardWindow

-(void) setupForKeyboardAndShow
{
	_textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 30, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height - RAKeyboardStateListener.sharedInstance.size.height)];
	_textField.backgroundColor = [UIColor grayColor];
	_textField.alpha = 0;
	[self addSubview:_textField];

	self.frame = UIScreen.mainScreen.bounds;
	self.windowLevel = 9999;
	[self makeKeyAndVisible];
	[_textField becomeFirstResponder];
}

-(void) resignKeyboard
{
	[_textField resignFirstResponder];
}

- (BOOL)_ignoresHitTest 
{
	return YES;
}
@end
