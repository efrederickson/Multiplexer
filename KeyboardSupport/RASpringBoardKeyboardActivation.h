#import "headers.h"

@interface RASpringBoardKeyboardActivation : NSObject
+(instancetype) sharedInstance;

@property (nonatomic, readonly, retain) NSString *currentIdentifier;

-(void) showKeyboardForAppWithIdentifier:(NSString*)identifier;
-(void) hideKeyboard;
@end
