#import <UIKit/UIKit.h>
#import "RAWidgetSection.h"

@interface RAWidgetSectionManager : NSObject
+(instancetype) sharedInstance;

-(void) registerSection:(RAWidgetSection*)section;

-(NSArray*) sections;
-(NSArray*) enabledSections;

-(UIView*) createViewForEnabledSectionsWithBaseFrame:(CGRect)frame preferredIconSize:(CGSize)size iconsThatFitPerLine:(NSInteger)iconsPerLine spacing:(CGFloat)spacing;
@end