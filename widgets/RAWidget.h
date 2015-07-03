#import <UIKit/UIKit.h>

@interface RAWidget : NSObject

-(NSString*) identifier;

// actual view for showing in Reachability
-(UIView*) view;

// Similar to an app icon with the image/title
-(UIView*) iconForSize:(CGSize)size; 

-(CGFloat) preferredHeight;
@end