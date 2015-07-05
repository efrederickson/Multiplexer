#import "headers.h"

@class RAAppSliderProvider;

@interface RAAppSliderProviderView : UIView {
	UISwipeGestureRecognizer *leftSwipeGestureRecognizer, *rightSwipeGestureRecognizer;
}
@property (nonatomic, retain) RAAppSliderProvider *swipeProvider;
@property (nonatomic) BOOL isSwipeable;

-(CGRect) clientFrame;
-(NSString*) currentBundleIdentifier;

-(void) goToTheLeft;
-(void) goToTheRight;

-(void) load;
-(void) unload;
-(void) updateCurrentView;
@end