#import "headers.h"

@interface RAHeaderView : UIView {
	UILabel *label;
	UIImageView *imageView;
}
@property (nonatomic) CGBlendMode blendMode;
@property (nonatomic) BOOL shouldBlend;
-(void) setColors:(NSArray*)colors;
-(void) setTitle:(NSString*)title;
-(void) setImage:(UIImage*)image;
@end