#import "headers.h"

%ctor
{
	IF_SPRINGBOARD {
	#if DEBUG
		NSLog(@"[ReachApp][DRM] Not checking statistics on debug build");
	#else
	    dispatch_async(dispatch_get_main_queue(), ^(void){
		    NSString *statsPath = @"/var/mobile/Library/Preferences/.multiplexer.stats_checked";
		    if ([NSFileManager.defaultManager fileExistsAtPath:statsPath] == NO)
		    {
		        CFStringRef (*$MGCopyAnswer)(CFStringRef);

		        void *gestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY);
		        $MGCopyAnswer = (CFStringRef (*)(CFStringRef))dlsym(gestalt, "MGCopyAnswer");

			    NSString *udid = (__bridge NSString*)$MGCopyAnswer(CFSTR("UniqueDeviceID"));
			    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://elijahandandrew.com/multiplexer/stats.php?udid=%@", udid]] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60.0];
			    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
			    	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
					int code = [httpResponse statusCode];
			        if (error == nil && (code == 0 || code == 200))
			        {
			        	[NSFileManager.defaultManager createFileAtPath:statsPath contents:[NSData new] attributes:nil];
			        }
			    }];
			}
		});
	#endif
	}
}