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

#import "PDFImage.h"

#import "PDFImageOptions.h"

static NSCache *sharedPDFImageCache = nil;

@interface PDFImage ()
{
	NSCache *_imageCache;
	dispatch_once_t _imageCacheOnceToken;
}

@property (nonatomic, readonly) CGPDFDocumentRef document;
@property (nonatomic, readonly) CGPDFPageRef page;

@end

@implementation PDFImage

+ (instancetype)imageNamed:(NSString *)name
{
	return [self imageNamed:name inBundle:[NSBundle mainBundle]];
}

+ (instancetype)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle
{
	//	Defaults
	NSString *pathName = name;
	NSString *pathType = @"pdf";

	NSString *suffix = @".pdf";
	const NSUInteger suffixLength = suffix.length;

	//	Enough room for the suffix
	if (name.length >= suffix.length)
	{
		const NSRange suffixRange = NSMakeRange(name.length - suffixLength, suffixLength);

		//	It has it's own suffix provided in the name, split the extension (type) from the name
		if ([name rangeOfString:suffix options:(NSCaseInsensitiveSearch)range:suffixRange].location != NSNotFound)
		{
			NSString *extensionSeparator = @".";
			const NSUInteger extensionSeparatorLength = extensionSeparator.length;

			const NSRange extensionRange = NSMakeRange(suffixRange.location + extensionSeparatorLength, suffixRange.length - extensionSeparatorLength);
			NSString *extension = [name substringWithRange:extensionRange];

			//	Make sure we use what's provided in case it's not the same (lower)case as we expect
			pathName = [name substringToIndex:suffixRange.location];
			pathType = extension;
		}
	}

	return [self imageResource:pathName ofType:pathType inBundle:bundle];
}

+ (instancetype)imageResource:(NSString *)name ofType:(NSString *)type inBundle:(NSBundle *)bundle
{
	NSString *filepath = [bundle pathForResource:name ofType:type];
	NSString *cacheKey = filepath;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
	  sharedPDFImageCache = [NSCache new];
	});

	PDFImage *result = [sharedPDFImageCache objectForKey:cacheKey];

	if (result == nil)
	{
		result = [(PDFImage *)[self alloc] initWithContentsOfFile:filepath];

		if (result != nil)
		{
			[sharedPDFImageCache setObject:result forKey:cacheKey];
		}
	}

	return result;
}

+ (instancetype)imageWithContentsOfFile:(NSString *)path
{
	return [(PDFImage *)[self alloc] initWithContentsOfFile:path];
}

+ (instancetype)imageWithData:(NSData *)data
{
	return [(PDFImage *)[self alloc] initWithData:data];
}

- (instancetype)initWithContentsOfFile:(NSString *)path
{
	NSData *data = [[NSData alloc] initWithContentsOfFile:path];
	return [self initWithData:data];
}

- (instancetype)initWithData:(NSData *)data
{
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
	CGPDFDocumentRef document = CGPDFDocumentCreateWithProvider(provider);
	CGDataProviderRelease(provider);

	id result = [self initWithDocument:document];

	if (document != nil)
		CGPDFDocumentRelease(document);

	return result;
}

- (instancetype)initWithDocument:(CGPDFDocumentRef)document
{
	if (document == nil)
		return nil;

	self = [super init];

	if (self != nil)
	{
		_document = CGPDFDocumentRetain(document);
		_page = CGPDFDocumentGetPage(_document, 1);

		_size = CGPDFPageGetBoxRect(_page, kCGPDFMediaBox).size;
	}

	return self;
}

#pragma mark -
#pragma mark Self

- (UIImage *)imageWithOptions:(PDFImageOptions *)options
{
	//	Where to draw the image
	const CGRect rect = [options contentBoundsForContentSize:self.size];

	const CGFloat scale = options.scale;
	UIColor *tintColor = [options.tintColor copy];
	const CGSize containerSize = options.size;

	NSString *cacheKey = [NSString stringWithFormat:@"%@-%0.2f-%@-%@", NSStringFromCGRect(rect), scale, tintColor.description, NSStringFromCGSize(containerSize)];

	dispatch_once(&_imageCacheOnceToken, ^{
	  _imageCache = [NSCache new];
	});

	UIImage *image = [_imageCache objectForKey:cacheKey];

	if (image == nil)
	{
		UIGraphicsBeginImageContextWithOptions(containerSize, NO, scale);

		CGContextRef ctx = UIGraphicsGetCurrentContext();

		[self drawInRect:rect];

		if (tintColor != nil)
		{
			CGContextSaveGState(ctx);

			//	Color the image
			CGContextSetBlendMode(ctx, kCGBlendModeSourceIn);
			CGContextSetFillColorWithColor(ctx, tintColor.CGColor);
			CGContextFillRect(ctx, CGRectMake(0, 0, containerSize.width, containerSize.height));

			CGContextRestoreGState(ctx);
		}

		image = UIGraphicsGetImageFromCurrentImageContext();

		UIGraphicsEndImageContext();

		if (image != nil)
		{
			[_imageCache setObject:image forKey:cacheKey];
		}
	}

	return image;
}

- (void)drawInRect:(CGRect)rect
{
	const CGSize drawSize = rect.size;
	const CGSize size = self.size;
	const CGSize sizeRatio = CGSizeMake(size.width / drawSize.width, size.height / drawSize.height);

	CGContextRef ctx = UIGraphicsGetCurrentContext();

	CGContextSaveGState(ctx);

	//	Flip and crop to the correct position and size
	CGContextScaleCTM(ctx, 1 / sizeRatio.width, 1 / -sizeRatio.height);
	CGContextTranslateCTM(ctx, rect.origin.x * sizeRatio.width, (-drawSize.height - rect.origin.y) * sizeRatio.height);

	CGContextDrawPDFPage(ctx, self.page);

	CGContextRestoreGState(ctx);
}

#pragma mark -
#pragma mark Cleanup

- (void)dealloc
{
	if (_document != nil)
	{
		CGPDFDocumentRelease(_document);
		_document = nil;
	}
}

@end