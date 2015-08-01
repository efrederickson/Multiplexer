#include <dlfcn.h>
#include <notify.h>
#include <stdio.h>
#include <stdlib.h>
#import <Foundation/Foundation.h>
#import "headers.h"
#import <objc/runtime.h>

int main(int argc, char **argv, char **envp) {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];

	NSString *filePath = @"/User/Library/.reachapp.uiappexitsonsuspend.wantstochangerootapp";
    if ([NSFileManager.defaultManager fileExistsAtPath:filePath] == NO)
    {
        NSLog(@"[ReachApp] FS Daemon: plist does not exist");
        return 0;
    }

	NSDictionary *contents = [NSDictionary dictionaryWithContentsOfFile:filePath];

    LSApplicationProxy *appInfo = [objc_getClass("LSApplicationProxy") applicationProxyForIdentifier:contents[@"bundleIdentifier"]];
    NSString *path = [NSString stringWithFormat:@"%@/Info.plist",appInfo.bundleURL.absoluteString];
    NSMutableDictionary *infoPlist = [NSMutableDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:path]];
    infoPlist[@"UIApplicationExitsOnSuspend"] = contents[@"UIApplicationExitsOnSuspend"];
    BOOL success = [infoPlist writeToURL:[NSURL URLWithString:path] atomically:YES];

    if (!success)
    	NSLog(@"[ReachApp] FS Daemon: error writing to plist: %@", path);
    else
    	[NSFileManager.defaultManager removeItemAtPath:path error:nil];

	[pool release];
	return 0;
}