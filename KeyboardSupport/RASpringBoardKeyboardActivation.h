#import "headers.h"
#import "RARunningAppsProvider.h"

@interface RASpringBoardKeyboardActivation : NSObject<RARunningAppsProviderDelegate>
+(instancetype) sharedInstance;

@property (nonatomic, readonly, retain) NSString *currentIdentifier;

-(void) showKeyboardForAppWithIdentifier:(NSString*)identifier;
-(void) hideKeyboard;
@end
