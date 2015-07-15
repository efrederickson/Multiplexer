#import <UIKit/UIKit.h>
#import "RAWidgetSectionManager.h"

#define VERTICAL_PADDING (5)

@implementation RAWidgetSectionManager

+(instancetype) sharedInstance
{
	static RAWidgetSectionManager *man = nil;
	if (man == nil)
		man = [[RAWidgetSectionManager alloc] init];
	return man;
}

-(id) init
{
	if (self = [super init])
	{
		_sections = [NSMutableDictionary dictionary];
	}
	return self;
}

-(void) registerSection:(RAWidgetSection*)section
{
	if (!section || !section.identifier)
		return;
	if ([_sections.allKeys containsObject:section.identifier])
		return;

	//NSLog(@"[ReachApp] registering section %@", section.identifier);
	_sections[section.identifier] = section;
}

-(NSArray*) sections
{
	return _sections.allValues;
}

-(NSArray*) enabledSections
{
	NSMutableArray *arr = [NSMutableArray array];
	for (RAWidgetSection* section in _sections.allValues)
	{
		if ([section enabled])
			[arr addObject:section];
	}

	//[arr sortUsingComparator:^(RAWidgetSection *a, RAWidgetSection *b) {
	//	return [@(a.sortOrder) compare:@(b.sortOrder)];
	//}];
	
	[arr sortUsingComparator:^NSComparisonResult(RAWidgetSection *a, RAWidgetSection *b) {
		if (a.sortOrder < b.sortOrder)
			return NSOrderedAscending;
		else if (a.sortOrder > b.sortOrder)
			return NSOrderedDescending;
		else 
			return NSOrderedSame;
	}];

	return arr;
}

-(UIView*) createViewForEnabledSectionsWithBaseFrame:(CGRect)frame preferredIconSize:(CGSize)iconSize iconsThatFitPerLine:(NSInteger)iconsPerLine spacing:(CGFloat)spacing
{
	// vertical scroll view?
	UIView *view = [[UIView alloc] initWithFrame:frame];
	view.backgroundColor = [UIColor clearColor];
	view.clipsToBounds = YES;
	//view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	CGFloat currentY = 10;

	for (RAWidgetSection* section in [self enabledSections])
	{
		if (section.enabled == NO)
			continue;
		@try
		{
			UIView *sectionView = [section viewForFrame:CGRectMake(0, currentY, view.frame.size.width, iconSize.height + VERTICAL_PADDING) preferredIconSize:iconSize iconsThatFitPerLine:iconsPerLine spacing:spacing];
			if (sectionView)
			{
				if (section.showTitle)
				{
					UILabel *titleView = [[UILabel alloc] initWithFrame:CGRectMake(10, currentY, 300, 20)];
					titleView.text = section.displayName;
					titleView.textColor = [UIColor whiteColor];
					titleView.font = [UIFont fontWithName:@"HelveticaNeue" size:16];
					[view addSubview:titleView];
					currentY += titleView.frame.size.height;
				}
				
				//sectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
				sectionView.backgroundColor = [UIColor clearColor];
				sectionView.clipsToBounds = YES;

				CGRect frame = sectionView.frame;
				//frame.origin.x = 0;
				frame.origin.y = currentY;
				sectionView.frame = frame;
				currentY += frame.size.height + VERTICAL_PADDING;

				sectionView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
				[view addSubview:sectionView];
			}
		}
		@catch (NSException *ex)
		{
			NSLog(@"[ReachApp] an error occurred creating the view for section '%@': %@", section.identifier, ex);
		}
	}

	CGRect frame2 = view.frame;
	frame2.size.height = currentY;
	view.frame = frame2;

	return view;
}

@end