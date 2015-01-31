#import <RAWidget.h>
#import <dlfcn.h>
#import <objc/runtime.h>

#define CHECK_FOR_REACHAPP \
if ([NSFileManager.defaultManager fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/ReachApp.dylib"]) \
	dlopen("/Library/MobileSubstrate/DynamicLibraries/ReachApp.dylib", RTLD_NOW | RTLD_GLOBAL); \

#define IF_REACHAPP if (objc_getClass("RAWidget") != nil)