#import "headers.h"

@class RAHostedAppView;

@interface RAAppSliderProvider : NSObject
@property (nonatomic, retain) NSArray *availableIdentifiers;
@property (nonatomic) NSInteger currentIndex;

-(BOOL) canGoLeft;
-(BOOL) canGoRight;

-(RAHostedAppView*) viewToTheLeft;
-(RAHostedAppView*) viewToTheRight;
-(RAHostedAppView*) viewAtCurrentIndex;

-(void) goToTheLeft;
-(void) goToTheRight;
@end
