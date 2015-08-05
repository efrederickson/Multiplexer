#import "headers.h"

@interface RASpringBoardKeyboardActivation : NSObject
+(id) sharedInstance;
-(void) showKeyboardForAppWithIdentifier:(NSString*)identifier;
-(void) hideKeyboard;
@end
