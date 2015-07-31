#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@class SBApplication;

__attribute__((visibility("hidden")))
@interface BioLockdownController : NSObject

+ (BioLockdownController *)sharedController;

- (BOOL)requiresAuthenticationForIdentifier:(NSString *)identifier;
- (BOOL)requiresAuthenticationForApplication:(SBApplication *)application;
- (BOOL)requiresAuthenticationForRecord:(ABRecordRef)record;

- (BOOL)authenticateForIdentifier:(NSString *)identifier actionDescription:(NSString *)actionDescription completion:(dispatch_block_t)completion failure:(dispatch_block_t)failure;
- (BOOL)authenticateForApplication:(SBApplication *)application actionText:(NSString *)actionText completion:(dispatch_block_t)completion failure:(dispatch_block_t)failure;
- (BOOL)authenticateForSwitchIdentifier:(NSString *)switchIdentifier actionText:(NSString *)actionText completion:(dispatch_block_t)completion failure:(dispatch_block_t)failure;
- (BOOL)authenticateForRecord:(ABRecordRef)record actionText:(NSString *)actionText completion:(dispatch_block_t)completion failure:(dispatch_block_t)failure;

@end


#define HAS_BIOLOCKDOWN (objc_getClass("BioLockdownController") != nil)
#define IF_BIOLOCKDOWN  if (HAS_BIOLOCKDOWN)

#define BIOLOCKDOWN_AUTHENTICATE_APP(ident, success, failure_) \
	if ([[objc_getClass("BioLockdownController") sharedController] requiresAuthenticationForIdentifier:ident]) \
	{ \
		[[objc_getClass("BioLockdownController") sharedController] authenticateForIdentifier:ident actionDescription:LOCALIZE(@"BIOLOCKDOWN_AUTH_DESCRIPTION") completion:success failure:failure_]; \
	} \
	else \
		success()