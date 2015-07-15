#import "headers.h"
#import "RAWindowBar.h"

@interface RAWindowOverlayView : UIView
@property (nonatomic, weak) RAWindowBar *appWindow;
-(void) show;
@end