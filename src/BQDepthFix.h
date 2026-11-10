#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const BQDepthFixEnabledKey;
// Mutates only an extracted temporary descriptor. Returns NO before installation on errors.
BOOL BQDepthFixDescriptor(NSString *descriptorPath, NSUInteger *changedCount, NSString **error);
