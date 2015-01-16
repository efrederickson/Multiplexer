#import <UIKit/UIKit.h>
#import "RAWidget.h"

@interface RAWidgetSection : NSObject {
	NSMutableArray *_widgets;
}

-(BOOL) enabled;

-(NSInteger) sortOrder;
-(NSString*) displayName;
-(NSString*) identifier;

// The view should cache, if possible, to speed up loading times. 
// It should NOT show the title view. 
-(UIView*) viewForFrame:(CGRect)frame preferredIconSize:(CGSize)size iconsThatFitPerLine:(NSInteger)iconsPerLine spacing:(CGFloat)spacing;

-(void) addWidget:(RAWidget*)widget;
@end