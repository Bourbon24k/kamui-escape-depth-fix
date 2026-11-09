#import "AppDelegate.h"
#import "BQCore.h"
#import "BQUI.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BQCoreInit();

    if (!BQGroupID().length) {
        BQLog(@"no app group; class7 path unavailable, class13/class12 fallbacks only");
    }

    if ([[NSProcessInfo processInfo].arguments containsObject:@"--bqfileselftest"]) {
        dispatch_async(BQWorkQueue(), ^{
            for (NSString *root in BQContainerRoots()) {
                NSArray *ids = BQListContainers(root);
                BQLog(@"fileselftest root=%@ count=%lu first=%@", root, (unsigned long)ids.count, ids.firstObject ?: @"-");
            }
            NSString *pb = BQFindPosterBoardContainer(NULL);
            if (pb.length) {
                NSArray *items = BQListPath(pb, @"", NULL);
                BQLog(@"fileselftest PB=%@ items=%lu first=%@", pb, (unsigned long)items.count, items.firstObject ?: @"-");
            }
        });
    }

    if ([[NSProcessInfo processInfo].arguments containsObject:@"--bqselftest"]) {
        dispatch_async(BQWorkQueue(), ^{
            BQLog(@"selftest args=%@", [NSProcessInfo processInfo].arguments);
            NSDictionary *probe = BQProbeEscapeClasses(@"/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches");
            BQLog(@"selftest probe=%@", probe);
            NSDictionary *parts = BQProbeClass2Parts(@"/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches");
            BQLog(@"selftest class2 parts=%@", parts);
            NSString *mgErr = nil;
            NSMutableDictionary *mg = BQLoadGestalt(&mgErr);
            BQLog(@"selftest MG=%@ err=%@ keys=%lu",
                  mg ? @"OK" : @"FAIL", mgErr ?: @"-",
                  (unsigned long)[mg[@"CacheExtra"] count]);
            NSString *pbErr = nil;
            NSString *pb = BQFindPosterBoardContainer(&pbErr);
            BQLog(@"selftest PB=%@ err=%@", pb ?: @"nil", pbErr ?: @"-");
            if ([[[NSProcessInfo processInfo] arguments] containsObject:@"--bqapplyfirst"] ||
                [[NSFileManager defaultManager] fileExistsAtPath:[BQDocuments() stringByAppendingPathComponent:@"ApplyFirst"]]) {
                NSString *dir = [BQDocuments() stringByAppendingPathComponent:@"tendies"];
                NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:nil] ?: @[];
                for (NSString *f in files) {
                    NSString *l = f.lowercaseString;
                    if (![l hasSuffix:@".tendies"] && ![l hasSuffix:@".zip"]) continue;
                    NSString *err = nil;
                    int c = 0;
                    BOOL ok = BQApplyTendies([NSURL fileURLWithPath:[dir stringByAppendingPathComponent:f]], &c, &err);
                    BQLog(@"selftest apply %@ ok=%d count=%d err=%@", f, ok, c, err ?: @"-");
                    break;
                }
            }
            BQLog(@"selftest done");
        });
    }
    return YES;
}

@end
