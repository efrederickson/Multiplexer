#import "headers.h"

@class RAAppSliderProvider;

@interface RAHostedAppView : UIView {
	SBApplication *app;
	FBWindowContextHostWrapperView *view;
}
-(id) initWithBundleIdentifier:(NSString*)bundleIdentifier;

@property (nonatomic, retain) NSString *bundleIdentifier;

-(void) preloadApp;
-(void) loadApp;
-(void) unloadApp;
@end