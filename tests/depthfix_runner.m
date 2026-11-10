#import <Foundation/Foundation.h>
#import "../src/BQDepthFix.h"
int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc != 2) return 2;
        NSString *error = nil;
        NSUInteger count = 0;
        BOOL ok = BQDepthFixDescriptor([NSString stringWithUTF8String:argv[1]], &count, &error);
        if (!ok) { fprintf(stderr, "%s\n", (error ?: @"unknown").UTF8String); return 1; }
        printf("%lu\n", (unsigned long)count);
        return 0;
    }
}
