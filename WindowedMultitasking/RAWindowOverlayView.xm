#import "RAWindowOverlayView.h"
#import "RAResourceImageProvider.h"

@implementation RAWindowOverlayView
-(void) show
{
	_UIBackdropView *blurView = [[%c(_UIBackdropView) alloc] initWithStyle:0];
	blurView.frame = self.frame;

	UITapGestureRecognizer *dismissGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
	[blurView addGestureRecognizer:dismissGesture];
	blurView.userInteractionEnabled = YES;

	[self addSubview:blurView];

	UIButton *closeButton = [[UIButton alloc] init];
	closeButton.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.3];
	closeButton.titleLabel.textColor = [UIColor whiteColor];
	closeButton.frame = CGRectMake((self.frame.size.width / 2) - (125/2), (self.frame.size.height / 3) - (125), 125, 125);
	[closeButton setImage:[[RAResourceImageProvider imageForFilename:@"Close" constrainedToSize:CGSizeMake(30, 30)] _flatImageWithColor:[UIColor whiteColor]] forState:UIControlStateNormal];
	closeButton.titleLabel.font = [UIFont systemFontOfSize:36];
	[closeButton addTarget:self action:@selector(closeButtonTap) forControlEvents:UIControlEventTouchUpInside];
	closeButton.layer.cornerRadius = 125/2;
	[self addSubview:closeButton];

	UIButton *maximizeButton = [[UIButton alloc] init];
	maximizeButton.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.3];
	maximizeButton.titleLabel.textColor = [UIColor whiteColor];
	maximizeButton.frame = CGRectMake((self.frame.size.width / 2) - (125/2), (self.frame.size.height / 2) - (125/2), 125, 125);
	[maximizeButton setImage:[[RAResourceImageProvider imageForFilename:@"Plus" constrainedToSize:CGSizeMake(30, 30)] _flatImageWithColor:[UIColor whiteColor]] forState:UIControlStateNormal];
	maximizeButton.titleLabel.font = [UIFont systemFontOfSize:36];
	[maximizeButton addTarget:self action:@selector(maximizeButtonTap) forControlEvents:UIControlEventTouchUpInside];
	maximizeButton.layer.cornerRadius = 125/2;
	[self addSubview:maximizeButton];

	UIButton *minimizeButton = [[UIButton alloc] init];
	minimizeButton.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.3];
	minimizeButton.titleLabel.textColor = [UIColor whiteColor];
	minimizeButton.frame = CGRectMake((self.frame.size.width / 2) - (125/2), ((self.frame.size.height / 3) * 2) - (0), 125, 125);
	[minimizeButton setImage:[[RAResourceImageProvider imageForFilename:@"Minus" constrainedToSize:CGSizeMake(30, 30)] _flatImageWithColor:[UIColor whiteColor]] forState:UIControlStateNormal];
	minimizeButton.titleLabel.font = [UIFont systemFontOfSize:36];
	[minimizeButton addTarget:self action:@selector(minimizeButtonTap) forControlEvents:UIControlEventTouchUpInside];
	minimizeButton.layer.cornerRadius = 125/2;
	[self addSubview:minimizeButton];
}

-(void) dismiss
{
	[UIView animateWithDuration:0.5 animations:^{
		self.alpha = 0;
	} completion:^(BOOL _) {
		[self removeFromSuperview];
	}];
}

-(void) closeButtonTap
{
	[self.appWindow close];
}

-(void) maximizeButtonTap
{
	[self.appWindow maximize];
}

-(void) minimizeButtonTap
{
	[self.appWindow minimize];
}
@end
