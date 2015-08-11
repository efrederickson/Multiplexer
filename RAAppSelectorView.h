#import "headers.h"

@class RAAppSelectorView;

@protocol RAAppSelectorViewDelegate
-(void) appSelector:(RAAppSelectorView*)view appWasSelected:(NSString*)bundleIdentifier;
@end

@interface RAAppSelectorView : UIScrollView
@property (nonatomic, weak) NSObject<RAAppSelectorViewDelegate> *target;

-(void) relayoutApps;
@end