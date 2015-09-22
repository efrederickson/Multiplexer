#import <dlfcn.h>
#import <substrate.h>
#import <Foundation/Foundation.h>

extern const char *__progname;

static int (*orig_BSAuditTokenTaskHasEntitlement)(id connection, NSString *entitlement);
static int hax_BSAuditTokenTaskHasEntitlement(__unsafe_unretained id connection, __unsafe_unretained NSString *entitlement) 
{
    if ([entitlement isEqualToString:@"com.apple.multitasking.unlimitedassertions"])
    {
        // We could check if the connection's pid matches SpringBoard's pid, but at this point I don't think it really matters
        // I mean, what could be the worst thing a process can do by making BKSProcessAssertions? slaughtering battery? suspending/keeping apps running?
        return true;
    }

    return orig_BSAuditTokenTaskHasEntitlement(connection, entitlement);
}

%ctor
{
    // We can never be too sure
	if (strcmp(__progname, "assertiond") == 0) 
	{
        dlopen("/System/Library/PrivateFrameworks/XPCObjects.framework/XPCObjects", RTLD_LAZY);
        void *xpcFunction = MSFindSymbol(NULL, "_BSAuditTokenTaskHasEntitlement");
        MSHookFunction(xpcFunction, (void *)hax_BSAuditTokenTaskHasEntitlement, (void **)&orig_BSAuditTokenTaskHasEntitlement);
    }
}