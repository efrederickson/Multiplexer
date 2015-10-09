#import "RAResourceImageProvider.h"
#import "PDFImage.h"

const NSString *resourcePath = RA_BASE_PATH;
NSCache *_rsImgCache = [NSCache new];

@implementation RAResourceImageProvider
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize 
{ 
    // from: https://stackoverflow.com/questions/2658738/the-simplest-way-to-resize-an-uiimage
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();    
    UIGraphicsEndImageContext();
    return newImage;
}

+(id) loadAndCacheImageWithStrippedPath:(NSString*)stripped
{
	NSString *pdfPath = [NSString stringWithFormat:@"%@/Resources/%@.pdf",resourcePath,stripped];
	NSString *pngPath = [NSString stringWithFormat:@"%@/Resources/%@.png",resourcePath,stripped];

	if ([NSFileManager.defaultManager fileExistsAtPath:pdfPath])
	{
		RAPDFImage *pdf = [RAPDFImage imageWithContentsOfFile:pdfPath];

		if (pdf)
			[_rsImgCache setObject:pdf forKey:stripped];

		return pdf;
	}
	else if ([NSFileManager.defaultManager fileExistsAtPath:pngPath])
	{
		UIImage *img = [UIImage imageWithContentsOfFile:pngPath];
		if (img)
			[_rsImgCache setObject:img forKey:stripped];

		return img;
	}

	return nil;
}

+(id) getOrCacheImageWithFilename:(NSString*)strippedPath
{
	return [_rsImgCache objectForKey:strippedPath] ?: [self loadAndCacheImageWithStrippedPath:strippedPath];
}

+(UIImage*) convertToUIImageIfNeeded:(id)arg sizeIfNeeded:(CGSize)size forceSizing:(BOOL)force
{
	if ([arg isKindOfClass:UIImage.class])
	{
		if (force)
			return [self imageWithImage:arg scaledToSize:size];
		else
			return (UIImage*)arg;
	}

	if ([arg isKindOfClass:[RAPDFImage class]])
	{
		UIImage *image = [arg imageWithOptions:[RAPDFImageOptions optionsWithSize:size]];
		return image;
	}

	return nil;
}

+(UIImage*) imageForFilename:(NSString*)filename
{
	NSString *strippedPath = [[filename lastPathComponent] stringByDeletingPathExtension];
	id img = [self getOrCacheImageWithFilename:strippedPath];

	return [self convertToUIImageIfNeeded:img sizeIfNeeded:CGSizeMake(200, 200) forceSizing:NO];
}

+(UIImage*) imageForFilename:(NSString*)filename size:(CGSize)size tintedTo:(UIColor*)tint
{
	return [[self imageForFilename:filename constrainedToSize:size] _flatImageWithColor:tint];
}

+(UIImage*) imageForFilename:(NSString*)filename constrainedToSize:(CGSize)size
{
	NSString *strippedPath = [[filename lastPathComponent] stringByDeletingPathExtension];
	id img = [self getOrCacheImageWithFilename:strippedPath];

	return [self convertToUIImageIfNeeded:img sizeIfNeeded:size forceSizing:YES];
}
@end