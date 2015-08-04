#import "headers.h"

@interface RAWidgetBase : UIView
-(NSString*) identifier;
-(NSString*) displayName;

-(void) didAppear;
-(void) didDisappear;
@end