@class SBWorkspace;

@interface RASBWorkspaceFetcher : NSObject
+(Class) SBWorkspaceClass;
+(SBWorkspace*) getCurrentSBWorkspaceImplementationInstanceForThisOS;
@end