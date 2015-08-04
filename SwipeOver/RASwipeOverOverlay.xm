#import "RASwipeOverOverlay.h"
#import "RASwipeOverManager.h"
#import "RAWidgetSectionManager.h"

@implementation RASwipeOverOverlay
@synthesize grabberView;

-(id) initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		//self.backgroundColor = [UIColor blueColor];
		//self.alpha = 0.4;
		self.windowLevel = UIWindowLevelStatusBar + 1;

		UIPanGestureRecognizer *g = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
		g.delegate = self;
		[self addGestureRecognizer:g];

		UILongPressGestureRecognizer *g2 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
		g2.delegate = self;
		[self addGestureRecognizer:g2];

		CGFloat knobWidth = 10;
	    CGFloat knobHeight = 30;
	    grabberView = [[UIView alloc] initWithFrame:CGRectMake(2, (self.frame.size.height / 2) - (knobHeight / 2), knobWidth - 4, knobHeight)];
	    grabberView.alpha = 0.5;
	    grabberView.layer.cornerRadius = knobWidth / 2;
	    grabberView.backgroundColor = [UIColor whiteColor];
	    [self addSubview:grabberView];
	}
	return self;
}

-(BOOL) isHidingUnderlyingApp { return isHidingUnderlyingApp; }

-(void) showEnoughToDarkenUnderlyingApp
{
	if (isHidingUnderlyingApp)
		return;
	isHidingUnderlyingApp = YES;

	// TODO: use UIBlurEffect?
	darkenerView = [[UIView alloc] initWithFrame:self.frame];
	darkenerView.backgroundColor = [UIColor blackColor];
	darkenerView.alpha = 0.35;
	darkenerView.userInteractionEnabled = YES;
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(darkenerViewTap:)];
	[darkenerView addGestureRecognizer:tap];
	[self addSubview:darkenerView];
	grabberView.hidden = YES;
}

-(void) removeOverlayFromUnderlyingApp
{
	if (!isHidingUnderlyingApp)
		return;
	isHidingUnderlyingApp = NO;

	[UIView animateWithDuration:0.3 animations:^{
		darkenerView.alpha = 0;
	} completion:^(BOOL _) {
		grabberView.hidden = NO;
		[darkenerView removeFromSuperview];
		darkenerView = nil;
	}];
}

-(void) removeOverlayFromUnderlyingAppImmediately
{
	if (!isHidingUnderlyingApp)
		return;
	isHidingUnderlyingApp = NO;

	[darkenerView removeFromSuperview];
	darkenerView = nil;
}

-(void) showAppSelector
{
	[self longPress:nil];
}

-(UIView*) currentView
{
	return [self viewWithTag:RASWIPEOVER_VIEW_TAG];
}

-(BOOL) isShowingAppSelector
{
	return [[self currentView] isKindOfClass:[UIScrollView class]];
}

-(void) darkenerViewTap:(UITapGestureRecognizer*)gesture
{
	[RASwipeOverManager.sharedInstance convertSwipeOverViewToSideBySide];
}

-(void) handlePan:(UIPanGestureRecognizer*)gesture
{
	CGPoint newPoint = [gesture translationInView:gesture.view];
    [RASwipeOverManager.sharedInstance sizeViewForTranslation:newPoint state:gesture.state];
}

-(void) longPress:(UILongPressGestureRecognizer*)gesture
{
	[RASwipeOverManager.sharedInstance closeCurrentView];
   
    static CGSize fullSize = [%c(SBIconView) defaultIconSize];
    fullSize.height = fullSize.width;
    CGFloat padding = 20;

    NSInteger numIconsPerLine = 0;
    CGFloat tmpWidth = 10;
    while (tmpWidth + fullSize.width <= self.frame.size.width)
    {
        numIconsPerLine++;
        tmpWidth += fullSize.width + 20;
    }
    padding = (self.frame.size.width - (numIconsPerLine * fullSize.width)) / (numIconsPerLine + 1);

    UIScrollView *allAppsView = [[UIScrollView alloc] initWithFrame:CGRectMake(isHidingUnderlyingApp ? 0 : 10, 0, self.frame.size.width - (isHidingUnderlyingApp ? 0 : 10), self.frame.size.height)];
    grabberView.alpha = 0;
    allAppsView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];

	CGSize contentSize = CGSizeMake(padding, 10);
	SBApplication *app = nil;
	int horizontal = 0;

	//allAppsView.backgroundColor = [UIColor clearColor];
	// TODO: doesn't work as well to having vertical paging...
	//allAppsView.pagingEnabled = [RASettings.sharedInstance pagingEnabled];

	static NSMutableArray *allApps = nil;
	if (!allApps)
	{
		allApps = [[[[%c(SBIconViewMap) homescreenMap] iconModel] visibleIconIdentifiers] mutableCopy];
	    [allApps sortUsingComparator: ^(NSString* a, NSString* b) {
	    	NSString *a_ = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:a].displayName;
	    	NSString *b_ = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:b].displayName;
	        return [a_ caseInsensitiveCompare:b_];
		}];
		//[allApps removeObject:currentBundleIdentifier];
	}
	for (NSString *str in allApps)
	{
		app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:str];
        SBIcon *icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForBundleIdentifier:app.bundleIdentifier];
        SBIconView *iconView = [[%c(SBIconViewMap) homescreenMap] _iconViewForIcon:icon];
        if (!iconView || [icon isKindOfClass:[%c(SBApplicationIcon) class]] == NO)
        	continue;
        
        iconView.frame = CGRectMake(contentSize.width, contentSize.height, iconView.frame.size.width, iconView.frame.size.height);
        contentSize.width += iconView.frame.size.width + padding;

        horizontal++;
        if (horizontal >= numIconsPerLine)
        {
        	horizontal = 0;
        	contentSize.width = padding;
        	contentSize.height += iconView.frame.size.height + 10;
        }

        iconView.restorationIdentifier = app.bundleIdentifier;
        UITapGestureRecognizer *iconViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(appViewItemTap:)];
        [iconView addGestureRecognizer:iconViewTapGestureRecognizer];
        [allAppsView addSubview:iconView];
	}
	contentSize.width = allAppsView.frame.size.width;
	contentSize.height += fullSize.height;
	[allAppsView setContentSize:contentSize];
	allAppsView.tag = RASWIPEOVER_VIEW_TAG;
	[self addSubview:allAppsView];
}

-(void) appViewItemTap:(UITapGestureRecognizer*)recognizer
{
	grabberView.alpha = 1;
	[RASwipeOverManager.sharedInstance showApp:recognizer.view.restorationIdentifier];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	UIView *v = [self viewWithTag:RASWIPEOVER_VIEW_TAG];
	if ([v isKindOfClass:[UIScrollView class]])
		return NO;
	if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]])
		return NO;
	return YES;
}
@end