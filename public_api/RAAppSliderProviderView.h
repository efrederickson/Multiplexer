#import <UIKit/UIKit.h>
#import "RAHostedAppView.h"

@class RAAppSliderProvider;

@interface RAAppSliderProviderView : UIView
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