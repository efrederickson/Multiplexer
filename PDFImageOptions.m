//
//  This is free and unencumbered software released into the public domain.
//
//  Anyone is free to copy, modify, publish, use, compile, sell, or
//  distribute this software, either in source code form or as a compiled
//  binary, for any purpose, commercial or non-commercial, and by any
//  means.
//
//  In jurisdictions that recognize copyright laws, the author or authors
//  of this software dedicate any and all copyright interest in the
//  software to the public domain. We make this dedication for the benefit
//  of the public at large and to the detriment of our heirs and
//  successors. We intend this dedication to be an overt act of
//  relinquishment in perpetuity of all present and future rights to this
//  software under copyright law.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
//  OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
//  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//
//  For more information, please refer to <http://unlicense.org/>
//

#import "PDFImageOptions.h"

@implementation PDFImageOptions

+ (instancetype)optionsWithSize:(CGSize)size
{
	PDFImageOptions *options = [self new];
	options.size = size;
	return options;
}

#pragma mark -

- (instancetype)init
{
	self = [super init];

	if (self != nil)
	{
		_contentMode = UIViewContentModeScaleToFill;
	}

	return self;
}

#pragma mark -
#pragma mark Self

- (CGRect)contentBoundsForContentSize:(CGSize)contentSize
{
	const CGSize containerSize = self.size;
	const UIViewContentMode contentMode = self.contentMode;

	CGRect rect = CGRectZero;

	BOOL shouldCenterWidth = NO;
	BOOL shouldCenterHeight = NO;

	switch (contentMode)
	{
		case UIViewContentModeScaleToFill: //	Scaled unproportionally to fill entire area (no gaps, no clipping)
		case UIViewContentModeRedraw:
			rect.size = containerSize;
			break;

		case UIViewContentModeScaleAspectFill: //	Scaled proportionally to fill entire area (no gaps, with clipping)
		case UIViewContentModeScaleAspectFit:  //	Scaled proportionally to fill entire area (with gaps, no clipping)
		{
			shouldCenterWidth = YES;
			shouldCenterHeight = YES;

			const CGFloat widthRatio = contentSize.width / containerSize.width;
			const CGFloat heightRatio = contentSize.height / containerSize.height;

			const CGFloat ratio = ((contentMode == UIViewContentModeScaleAspectFill) ? MIN(widthRatio, heightRatio) : MAX(widthRatio, heightRatio));
			rect.size = CGSizeMake(ceilf(contentSize.width / ratio), ceilf(contentSize.height / ratio));

			break;
		}

		case UIViewContentModeCenter:
		case UIViewContentModeTop:
		case UIViewContentModeBottom:
		case UIViewContentModeLeft:
		case UIViewContentModeRight:
		case UIViewContentModeTopLeft:
		case UIViewContentModeTopRight:
		case UIViewContentModeBottomLeft:
		case UIViewContentModeBottomRight:
		{
			rect.size = contentSize;

			//	X positioning
			switch (contentMode)
			{
				case UIViewContentModeCenter:
				case UIViewContentModeTop:
				case UIViewContentModeBottom:
					shouldCenterWidth = YES;
					break;

				case UIViewContentModeRight:
				case UIViewContentModeTopRight:
				case UIViewContentModeBottomRight:
					rect.origin.x = containerSize.width - rect.size.width;
					break;

				default:
					break;
			}

			//	Y positioning
			switch (contentMode)
			{
				case UIViewContentModeCenter:
				case UIViewContentModeLeft:
				case UIViewContentModeRight:
					shouldCenterHeight = YES;
					break;

				case UIViewContentModeBottom:
				case UIViewContentModeBottomLeft:
				case UIViewContentModeBottomRight:
					rect.origin.y = containerSize.height - rect.size.height;
					break;

				default:
					break;
			}

			break;
		}
	}

	if (shouldCenterWidth)
		rect.origin.x = floorf((containerSize.width - rect.size.width) / 2);

	if (shouldCenterHeight)
		rect.origin.y = floorf((containerSize.height - rect.size.height) / 2);

	return rect;
}

- (CGSize)wholeProportionalFitForContentSize:(CGSize)contentSize
{
	const CGSize containerSize = self.size;

	if (contentSize.width > containerSize.width || contentSize.height > containerSize.height)
	{
		const CGFloat ratio = ceilf(MAX(contentSize.width / containerSize.width, contentSize.height / containerSize.height));
		return CGSizeMake(contentSize.width / ratio, contentSize.height / ratio);
	}
	else
	{

		const CGFloat ratio = floorf(MIN(containerSize.width / contentSize.width, containerSize.height / contentSize.height));
		return CGSizeMake(contentSize.width * ratio, contentSize.height * ratio);
	}
}

@end