#import "RAKeyboardWindow.h"
#import "headers.h"
#import "RAKeyboardStateListener.h"
#import "RADesktopManager.h"

@implementation RAKeyboardWindow
-(void) setupForKeyboardAndShow:(NSString*)identifier
{
	self.userInteractionEnabled = YES;
	
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

-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    NSEnumerator *objects = [self.subviews reverseObjectEnumerator];
    UIView *subview;
    while ((subview = [objects nextObject])) 
    {
        UIView *success = [subview hitTest:[self convertPoint:point toView:subview] withEvent:event];
        if (success)
            return success;
    }
    return [super hitTest:point withEvent:event];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event 
{
	BOOL isContained = NO;
	for (UIView *view in self.subviews)
	{
		if (CGRectContainsPoint(view.frame, point) || CGRectContainsPoint(view.frame, [view convertPoint:point fromView:self])) // [self convertPoint:point toView:view]))
			isContained = YES;
	}
	return isContained;
}
@end
