#import "BQDepthFix.h"

NSString *const BQDepthFixEnabledKey = @"BQDepthFixEnabled";
static NSString *const kRenderingFile = @"com.apple.posterkit.provider.instance.renderingConfiguration.plist";
static NSString *const kRenderingBase64 = @"YnBsaXN0MDDUAQIDBAUGBwpZJGFyY2hpdmVyWCR2ZXJzaW9uVCR0b3BYJG9iamVjdHNfEA9OU0tleWVkQXJjaGl2ZXISAAGGoNEICVRyb290gAGjCwwSVSRudWxs0w0ODxAREVYkY2xhc3NfEBNkZXB0aEVmZmVjdERpc2FibGVkXxAPcGFyYWxsYXhFbmFibGVkgAII0hMUFRZYJGNsYXNzZXNaJGNsYXNzbmFtZaIWF18QHlBSUG9zdGVyUmVuZGVyaW5nQ29uZmlndXJhdGlvblhOU09iamVjdAgRGyQpMkRJTFFTV11ka4GTlZabpK+y0wAAAAAAAAEBAAAAAAAAABgAAAAAAAAAAAAAAAAAAADc";

static BOOL FixValue(id value, NSString *bundle, NSMutableDictionary<NSString *, NSString *> *moves, NSUInteger *count, NSString **error) {
    if ([value isKindOfClass:[NSMutableDictionary class]]) {
        NSMutableDictionary *dict = value;
        if ([dict[@"type"] isEqual:@"LayeredAnimation"] && [dict[@"floatingAnimationFileNameKey"] isKindOfClass:[NSString class]]) {
            NSString *old = dict[@"floatingAnimationFileNameKey"];
            if ([old hasSuffix:@".ca"]) {
                if (![old isEqualToString:old.lastPathComponent] || [old isEqualToString:@"."] || [old isEqualToString:@".."] || [old containsString:@"\\"]) {
                    if (error) *error = @"Invalid floating layer name";
                    return NO;
                }
                NSString *source = [bundle stringByAppendingPathComponent:old];
                NSString *name = [old containsString:@"Clownfish"] ? old : [@"Clownfish_" stringByAppendingString:old];
                NSString *dest = [bundle stringByAppendingPathComponent:name];
                BOOL isDir = NO;
                if (![[NSFileManager defaultManager] fileExistsAtPath:source isDirectory:&isDir] || !isDir) {
                    if (error) *error = [NSString stringWithFormat:@"Floating layer not found: %@", old];
                    return NO;
                }
                if (![source isEqualToString:dest] && [[NSFileManager defaultManager] fileExistsAtPath:dest]) {
                    if (error) *error = @"Floating layer destination already exists";
                    return NO;
                }
                if (moves[source] && ![moves[source] isEqualToString:dest]) {
                    if (error) *error = @"Conflicting floating layer paths";
                    return NO;
                }
                moves[source] = dest;
                dict[@"floatingAnimationFileNameKey"] = name;
                (*count)++;
            }
        }
        for (id child in dict.allValues) if (!FixValue(child, bundle, moves, count, error)) return NO;
    } else if ([value isKindOfClass:[NSArray class]]) {
        for (id child in value) if (!FixValue(child, bundle, moves, count, error)) return NO;
    }
    return YES;
}

BOOL BQDepthFixDescriptor(NSString *descriptorPath, NSUInteger *changedCount, NSString **error) {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSDirectoryEnumerator *en = [fm enumeratorAtPath:descriptorPath];
    NSMutableArray<NSString *> *plists = [NSMutableArray array];
    for (NSString *rel in en) {
        if ([rel.pathComponents containsObject:@"__MACOSX"]) { [en skipDescendants]; continue; }
        if ([rel.lastPathComponent isEqualToString:@"Wallpaper.plist"]) [plists addObject:[descriptorPath stringByAppendingPathComponent:rel]];
    }
    NSUInteger total = 0;
    for (NSString *path in plists) {
        NSData *input = [NSData dataWithContentsOfFile:path];
        NSError *plistError = nil;
        NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
        id obj = input ? [NSPropertyListSerialization propertyListWithData:input options:NSPropertyListMutableContainersAndLeaves format:&format error:&plistError] : nil;
        if (![obj isKindOfClass:[NSMutableDictionary class]]) {
            if (error) *error = [NSString stringWithFormat:@"Invalid Wallpaper.plist: %@", plistError.localizedDescription ?: path.lastPathComponent];
            return NO;
        }
        NSMutableDictionary *dict = obj;
        NSString *bundle = path.stringByDeletingLastPathComponent;
        NSMutableDictionary<NSString *, NSString *> *moves = [NSMutableDictionary dictionary];
        NSUInteger count = 0;
        if (!FixValue(dict[@"assets"], bundle, moves, &count, error)) return NO;
        if (!count) continue;
        dict[@"family"] = @"Clownfish";
        for (NSString *source in moves) {
            NSString *dest = moves[source];
            if (![source isEqualToString:dest] && ![fm moveItemAtPath:source toPath:dest error:&plistError]) {
                if (error) *error = [NSString stringWithFormat:@"Could not rename floating layer: %@", plistError.localizedDescription];
                return NO;
            }
        }
        NSData *output = [NSPropertyListSerialization dataWithPropertyList:dict format:format options:0 error:&plistError];
        if (!output || ![output writeToFile:path options:NSDataWritingAtomic error:&plistError]) {
            if (error) *error = [NSString stringWithFormat:@"Could not update Wallpaper.plist: %@", plistError.localizedDescription];
            return NO;
        }
        NSString *contents = bundle.stringByDeletingLastPathComponent;
        if ([contents.lastPathComponent isEqualToString:@"contents"]) {
            NSString *cfg = [contents.stringByDeletingLastPathComponent stringByAppendingPathComponent:kRenderingFile];
            if (![fm fileExistsAtPath:cfg]) {
                NSData *data = [[NSData alloc] initWithBase64EncodedString:kRenderingBase64 options:0];
                if (!data || ![data writeToFile:cfg options:NSDataWritingAtomic error:&plistError]) {
                    if (error) *error = [NSString stringWithFormat:@"Could not write rendering configuration: %@", plistError.localizedDescription];
                    return NO;
                }
            }
        }
        total += count;
    }
    if (changedCount) *changedCount = total;
    return YES;
}
