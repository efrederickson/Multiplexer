#import "RAHeaderView.h"

@implementation RAHeaderView
+ (Class)layerClass 
{
	return [CAGradientLayer class];
}

-(id) initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		CAGradientLayer *gradient = (CAGradientLayer*)self.layer;
	    gradient.colors = @[ (id)[UIColor colorWithRed:255/255.0f green:124/255.0f blue:111/255.0f alpha:1.0f].CGColor, (id)[UIColor colorWithRed:231/255.0f green:76/255.0f blue:60/255.0f alpha:1.0f].CGColor ];
	    gradient.locations = @[ @0, @1 ];
	    gradient.bounds = CGRectMake(0, 0, frame.size.width, frame.size.height);

	    label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 200, frame.size.height - 20)];
	    label.textColor = [UIColor whiteColor];
	    label.font = [UIFont systemFontOfSize:36];
	    label.adjustsFontSizeToFitWidth = YES;
	    label.clipsToBounds = NO;
	    [self addSubview:label];

	    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(frame.size.width - 210, 0, 200, 75)];
	    [self addSubview:imageView];
	}
	return self;
}

-(void) setFrame:(CGRect)frame
{
	[super setFrame:frame];
	((CAGradientLayer*)self.layer).frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
}

-(void) setColors:(NSArray*)c
{
	((CAGradientLayer*)self.layer).colors = c;
}

-(void) setTitle:(NSString*)title
{
	label.text = title;
}

-(void) setImage:(UIImage*)image
{
	if (label.text.length > 0)
		imageView.frame = (CGRect) { { self.frame.size.width - image.size.width - 20, (self.frame.size.height - image.size.height) / 2.0 }, image.size };
	else
		imageView.frame = (CGRect) { { (self.frame.size.width - image.size.width) / 2.0, (self.frame.size.height - image.size.height) / 2.0 }, image.size };
	imageView.image = image;
}
@end
