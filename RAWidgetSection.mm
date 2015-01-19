#import "RAWidgetSection.h"
#import "RAReachabilityManager.h"

@implementation RAWidgetSection

-(id) init
{
	if (self = [super init])
	{
		_widgets = [NSMutableArray array];
	}
	return self;
}

-(BOOL) enabled { return YES; }
-(BOOL) showTitle { return YES; }

-(NSInteger) sortOrder { return 10; }

-(NSString*) displayName 
{
	@throw @"This is an abstract method and should be overriden."; 
}

-(NSString*) identifier 
{ 
	@throw @"This is an abstract method and should be overriden.";
}

-(void) addWidget:(RAWidget*)widget
{
	[_widgets addObject:widget];
}

-(UIView*) viewForFrame:(CGRect)frame preferredIconSize:(CGSize)size iconsThatFitPerLine:(NSInteger)iconsPerLine spacing:(CGFloat)spacing
{ 
	UIView *view = [[UIView alloc] initWithFrame:frame];
	CGPoint origin = CGPointMake(10, 0);

	for (NSInteger index = 0; index < _widgets.count; index++)
	{
		RAWidget *widget = _widgets[index];

		UIView *subView = [widget iconForSize:size];
		subView.clipsToBounds = YES;
		subView.backgroundColor = [UIColor clearColor];

		UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(widgetIconTap:)];
		[subView addGestureRecognizer:tap];
		subView.tag = index;

		CGRect frame = subView.frame;
		frame.origin = origin;
		subView.frame = frame;
		origin.x += frame.size.width + spacing;

		[view addSubview:subView];
	}
	return view;
}

-(void) widgetIconTap:(UITapGestureRecognizer*)gesture
{
	NSInteger widgetIndex = gesture.view.tag;
	[[RAReachabilityManager sharedInstance] launchWidget:_widgets[widgetIndex]];
}
@end