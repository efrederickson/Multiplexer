#import <substrate.h>
#import <objc/runtime.h>
#import "RACompatibilitySystem.h"
#include <execinfo.h>
#include <stdio.h>
#include <stdlib.h>

#if IBUG

void dump_info_before_crash(NSString *str)
{
	FILE *f = fopen("/User/Library/com.efrederickson.multiplexer.crashinfo", "w");
	if (f == NULL)
	{
	    NSLog(@"[ReachApp][iBug] error opening crashinfo file for writing");
	    return;
	}

	fprintf(f, "%s", [str UTF8String]);

	fclose(f);
}

@interface DummyClass_ibug : NSObject
@property (nonatomic) char *name;
@end

@implementation DummyClass_ibug
- (NSMethodSignature*)methodSignatureForSelector:(SEL)sel
{
    NSLog(@"[ReachApp][iBug] invoking unknown (non-NSObject) selector '%@' on nil class '%s'", NSStringFromSelector(sel), _name);
    return nil;
}

- (void)forwardInvocation:(NSInvocation*)inv
{
    NSLog(@"[ReachApp][iBug] forwardInvocation: %@", NSStringFromSelector(inv.selector));
}

-(BOOL) isKindOfClass:(Class)cls
{
	NSLog(@"[ReachApp][iBug] attempt to determine if nil class '%s' is '%s'", _name, class_getName(cls));
	return YES;
}
@end

%hook NSObject
- (NSMethodSignature*)methodSignatureForSelector:(SEL)sel
{
	NSMethodSignature *o = %orig;
	if (!o)
	{
	    NSLog(@"[ReachApp][iBug] methodSignatureForSelector: unknown selector '%@' on class '%s'", NSStringFromSelector(sel), class_getName(self.class));
	}
    return o;
}

- (void)forwardInvocation:(NSInvocation*)inv
{
    NSLog(@"[ReachApp][iBug] forwardInvocation: %@", NSStringFromSelector(inv.selector));
}

-(IMP)methodForSelector:(SEL)selector
{
	IMP o = %orig;
	if (!o)
	{
	    NSLog(@"[ReachApp][iBug] methodForSelector: unknown selector '%@' on class '%s'", NSStringFromSelector(selector), class_getName(self.class));
	}
    return o;
}

-(void)doesNotRecognizeSelector:(SEL)selector
{
	NSMutableString *info = [[NSMutableString alloc] init];

	NSLog(@"[ReachApp][iBug] doesNotRecognizeSelector: selector '%@' on class '%s'", NSStringFromSelector(selector), class_getName(self.class));
	[info appendString:[NSString stringWithFormat:@"Invocation of unknown selector '%@' on class '%s'\n", NSStringFromSelector(selector), class_getName(self.class)]];

	void *array[10];
	size_t size;
	char **strings;
	size_t i;

	size = backtrace (array, 10);
	strings = backtrace_symbols (array, size);

	NSLog(@"[ReachApp][iBug] Obtained %zd stack frames.\n", size);
	[info appendString:[NSString stringWithFormat:@"\nGot %zd stack trace methods\n", size]];

	for (i = 0; i < size; i++)
	{
		NSLog(@"[ReachApp][iBug] %s\n", strings[i]);
		[info appendString:[NSString stringWithFormat:@"%s\n",strings[i]]];
	}

	free(strings);

	dump_info_before_crash(info);

	//[RACompatibilitySystem showError:[NSString stringWithFormat:@"Selector '%@' not found on class '%s'", NSStringFromSelector(selector), class_getName(self.class)]];
	%orig; 
}
%end

BOOL ibug_shouldWatchClass(const char *name)
{
	const char *hook[] = { "FBWindowContextHostWrapperView", "FBWindowContextHostManager" };
	int lengths[] = { 30, 30 };
	int len = sizeof(lengths) / sizeof(lengths[0]);
	int i;

	for (i = 0; i < len; i++)
	{
	    if (strcmp(hook[i], name) == 0)
	    {
	    	return YES;
	    }
	}
	return NO;
}

Class dummyClass;

Class (*orig$objc_getClass)(const char *name);
Class hook$objc_getClass(const char *name)
{
	Class cls = orig$objc_getClass(name);
	if (!cls)
	{
		NSLog(@"[ReachApp][iBug] attempted access to nil class '%s'", name);
		if (ibug_shouldWatchClass(name))
		{
			NSLog(@"[ReachApp][iBug] faking class '%s'", name);
			cls = dummyClass;
		}
	}
	return cls;
}

%hook SpringBoard
-(void) _performDeferredLaunchWork
{
	%orig;

	char *buffer = 0;
	long length;
	FILE *f = fopen("/User/Library/com.efrederickson.multiplexer.crashinfo", "rb");

	if (f)
	{
		fseek(f, 0, SEEK_END);
		length = ftell(f);
		fseek(f, 0, SEEK_SET);
		buffer = (char*)malloc(length);
		if (buffer)
		{
			fread(buffer, 1, length, f);
		}
		fclose(f);
		remove("/User/Library/com.efrederickson.multiplexer.crashinfo");

		if (buffer)
		{
			NSString *info = [NSString stringWithFormat:@"%s",buffer];
			[RACompatibilitySystem showError:info];
		}
	}
}
%end

%ctor
{
	MSHookFunction((void*)objc_getClass, (void*)hook$objc_getClass, (void**)&orig$objc_getClass);
	dummyClass = orig$objc_getClass("DummyClass_ibug");
	NSLog(@"[ReachApp][iBug] initializing");
}
#endif