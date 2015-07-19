#import <UIKit/UIKit.h>

@interface RAHeaderView : UIView {
	UILabel *label;
	UIImageView *imageView;
}
-(void) setColors:(NSArray*)colors;
-(void) setTitle:(NSString*)title;
-(void) setImage:(UIImage*)image;
@end