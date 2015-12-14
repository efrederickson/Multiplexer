#import "RASBWorkspaceFetcher.h"
#import <objc/runtime.h>

// IMPORTANT: DO NOT IMPORT HEADERS.H
// REASON: HEADERS.H IMPORTS THIS FILE

@interface __SBWorkspace__class_impl_dummy : NSObject
+(id) sharedInstance;
@end

Class SBWorkspace_class_implementation_class = nil;

@implementation RASBWorkspaceFetcher
+(Class) SBWorkspaceClass
{
	return SBWorkspace_class_implementation_class;
}

+(SBWorkspace*) getCurrentSBWorkspaceImplementationInstanceForThisOS
{
	if ([SBWorkspace_class_implementation_class respondsToSelector:@selector(sharedInstance)])
		return [SBWorkspace_class_implementation_class sharedInstance];
	NSLog(@"[ReachApp] \"SBWorkspace\" class '%s' does not have '+sharedInstance' method", class_getName(SBWorkspace_class_implementation_class));
	return nil;
}
@end

%ctor
{
	// SBMainWorkspace: iOS 9
	// SBWorkspace: iOS 8
	SBWorkspace_class_implementation_class = objc_getClass("SBMainWorkspace") ?: objc_getClass("SBWorkspace");
}