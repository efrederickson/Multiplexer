#import <substrate.h>
#import <objc/runtime.h>
#import "RACompatibilitySystem.h"
#include <execinfo.h>
#include <stdio.h>
#include <stdlib.h>
#import "headers.h"

%hook NSObject
-(void)doesNotRecognizeSelector:(SEL)selector
{
	NSLog(@"[ReachApp] doesNotRecognizeSelector: selector '%@' on class '%s' (image: %s)", NSStringFromSelector(selector), class_getName(self.class), class_getImageName(self.class));

	void *array[10];
	size_t size;
	char **strings;
	size_t i;

	size = backtrace (array, 10);
	strings = backtrace_symbols (array, size);

	NSLog(@"[ReachApp] Obtained %zd stack frames:\n", size);

	for (i = 0; i < size; i++)
	{
		NSLog(@"[ReachApp] %s\n", strings[i]);
	}

	free(strings);

	%orig; 
}
%end

/*Class (*orig$objc_getClass)(const char *name);
Class hook$objc_getClass(const char *name)
{
	Class cls = orig$objc_getClass(name);
	if (!cls)
	{
		NSLog(@"[ReachApp] something attempted to access nil class '%s'", name);
	}
	return cls;
}*/

%ctor
{
	IF_SPRINGBOARD {
		
		// Causes cycript to not function
		//MSHookFunction((void*)objc_getClass, (void*)hook$objc_getClass, (void**)&orig$objc_getClass);
		
		%init;
	}
	//NSLog(@"[ReachApp] %s", class_getImageName(orig$objc_getClass("RAMissionControlManager")));
}
