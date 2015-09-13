#import "RAWindowSorter.h"
#import "headers.h"
#import "RAWindowBar.h"
#import "RAWindowSnapDataProvider.h"

@implementation RAWindowSorter
+(void) sortWindowsOnDesktop:(RADesktopWindow*)desktop resizeIfNecessary:(BOOL)resize
{
	NSInteger numberOfWindows = desktop.hostedWindows.count;

	if (numberOfWindows == 0)
		return;

	NSMutableArray *windows = [NSMutableArray array];
	for (UIView *view in desktop.subviews)
		if ([view isKindOfClass:[RAWindowBar class]])
			[windows addObject:view];

	if (numberOfWindows == 1)
	{
		if (resize)
			[windows[0] scaleTo:0.7 animated:YES derotate:YES];
		[RAWindowSnapDataProvider snapWindow:windows[0] toLocation:RAWindowSnapLocationLeftTop animated:YES];
	}
	else if (numberOfWindows == 2)
	{
		RAWindowBar *window1 = windows[0];
		RAWindowBar *window2 = windows[1];

		if (resize)
		{
			[window1 scaleTo:0.5 animated:YES derotate:YES];
			[window2 scaleTo:0.5 animated:YES derotate:YES];
		}

		[RAWindowSnapDataProvider snapWindow:window1 toLocation:RAWindowSnapLocationLeftTop animated:YES];
		[RAWindowSnapDataProvider snapWindow:window2 toLocation:RAWindowSnapLocationRightTop animated:YES];
	}
	else if (numberOfWindows == 3)
	{
		RAWindowBar *window1 = windows[0];
		RAWindowBar *window2 = windows[1];
		RAWindowBar *window3 = windows[2];

		if (resize)
		{
			[window1 scaleTo:0.5 animated:YES derotate:YES];
			[window2 scaleTo:0.5 animated:YES derotate:YES];
			[window3 scaleTo:0.4 animated:YES derotate:YES];
		}

		[RAWindowSnapDataProvider snapWindow:window1 toLocation:RAWindowSnapLocationLeftTop animated:YES];
		[RAWindowSnapDataProvider snapWindow:window2 toLocation:RAWindowSnapLocationRightTop animated:YES];
		[RAWindowSnapDataProvider snapWindow:window3 toLocation:RAWindowSnapLocationBottomCenter animated:YES];
	}
	else if (NO && numberOfWindows == 4)
	{
		RAWindowBar *window1 = windows[0];
		RAWindowBar *window2 = windows[1];
		RAWindowBar *window3 = windows[2];
		RAWindowBar *window4 = windows[3];

		if (resize)
		{
			[window1 scaleTo:0.45 animated:YES derotate:YES];
			[window2 scaleTo:0.45 animated:YES derotate:YES];
			[window3 scaleTo:0.45 animated:YES derotate:YES];
			[window4 scaleTo:0.45 animated:YES derotate:YES];
		}
		
		[RAWindowSnapDataProvider snapWindow:window1 toLocation:RAWindowSnapLocationLeftTop animated:YES];
		[RAWindowSnapDataProvider snapWindow:window2 toLocation:RAWindowSnapLocationRightTop animated:YES];
		[RAWindowSnapDataProvider snapWindow:window3 toLocation:RAWindowSnapLocationBottomLeft animated:YES];
		[RAWindowSnapDataProvider snapWindow:window4 toLocation:RAWindowSnapLocationBottomRight animated:YES];
	}
	else
	{
		if (resize)
		{
			//CGFloat maxScale = 1.0 / numberOfWindows; // (numberOfWindows / 2.0);
			//CGFloat maxScale = (desktop.frame.size.width / (numberOfWindows/2.0)) / desktop.frame.size.width;
			CGFloat factor = desktop.frame.size.height - 20;
			CGFloat maxScale = factor / (ceil(sqrt(numberOfWindows)) * [windows[0] bounds].size.height);
			
			CGFloat x = 0, y = 0;
			int panesPerLine = floor(1.0 / maxScale);// (numberOfWindows & ~1) /* round down to nearest even number */
			int currentPane = 0;

			for (RAWindowBar *bar in windows)
			{
				[bar scaleTo:maxScale animated:YES derotate:YES];

				if (y == 0) // 20 = statusbar
					y = 20 + (bar.frame.size.height / 2.0);
				if (x == 0)
					x = bar.frame.size.width / 2.0;

				bar.center = CGPointMake(x, y);

				if (++currentPane == panesPerLine)
				{
					currentPane = 0;
					x = 0;
					y += bar.frame.size.height;
				}
				else
					x += bar.frame.size.width;
			}
		}
		else
		{

		}
	}

	for (RAWindowBar *bar in windows)
		[bar saveWindowInfo];
}
@end