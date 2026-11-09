#import "FilesVC.h"
#import "BQCore.h"
#import "BQUI.h"

@interface ContainerListVC : UITableViewController
@property (nonatomic, copy) NSString *rootPath;
@property (nonatomic, strong) NSArray<NSDictionary *> *entries;
@end

@interface ContainerBrowseVC : UITableViewController <UIDocumentPickerDelegate>
@property (nonatomic, copy) NSString *container;
@property (nonatomic, copy) NSString *rel;
@property (nonatomic, strong) NSArray<NSDictionary *> *entries;
@end

@interface FileViewVC : UIViewController
@property (nonatomic, copy) NSString *container;
@property (nonatomic, copy) NSString *rel;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, assign) BOOL editable;
@end

@implementation FilesVC

- (instancetype)init { return [super initWithStyle:UITableViewStyleInsetGrouped]; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Files", nil);
}

- (NSArray<NSDictionary *> *)roots {
    return @[
        @{@"title": NSLocalizedString(@"App Data", nil), @"path": @"/var/mobile/Containers/Data/Application"},
        @{@"title": NSLocalizedString(@"App Groups", nil), @"path": @"/var/mobile/Containers/Shared/AppGroup"},
        @{@"title": NSLocalizedString(@"System Groups", nil), @"path": @"/var/containers/Shared/SystemGroup"},
        @{@"title": NSLocalizedString(@"System Data", nil), @"path": @"/var/containers/Data/System"},
        @{@"title": NSLocalizedString(@"Internal Daemons", nil), @"path": @"/var/mobile/Containers/Data/InternalDaemon"},
        @{@"title": NSLocalizedString(@"Plugins", nil), @"path": @"/var/mobile/Containers/Data/PluginKitPlugin"},
    ];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.roots.count; }

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return NSLocalizedString(@"Full MCM container access: app data, app groups, system groups and system data.", nil);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"root"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"root"];
    NSDictionary *r = self.roots[indexPath.row];
    cell.textLabel.text = r[@"title"];
    cell.detailTextLabel.text = r[@"path"];
    cell.detailTextLabel.font = [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightRegular];
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ContainerListVC *vc = [[ContainerListVC alloc] init];
    vc.rootPath = self.roots[indexPath.row][@"path"];
    [self.navigationController pushViewController:vc animated:YES];
}

@end

@implementation ContainerListVC

- (instancetype)init { return [super initWithStyle:UITableViewStyleInsetGrouped]; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.rootPath.lastPathComponent;
    self.entries = @[];
    [self load];
}

- (void)load {
    NSString *root = self.rootPath;
    dispatch_async(BQWorkQueue(), ^{
        NSArray *paths = BQListContainers(root);
        NSMutableArray *out = [NSMutableArray array];
        for (NSString *p in paths) {
            NSDictionary *info = BQContainerInfo(p);
            NSString *ident = info[@"MCMMetadataIdentifier"];
            [out addObject:@{@"path": p, @"id": ident.length ? ident : p.lastPathComponent}];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.entries = out;
            [self.tableView reloadData];
        });
    });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.entries.count; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.entries.count ? NSLocalizedString(@"Containers", nil) : NSLocalizedString(@"Loading...", nil);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"container"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"container"];
    NSDictionary *e = self.entries[indexPath.row];
    cell.textLabel.text = e[@"id"];
    cell.detailTextLabel.text = e[@"path"];
    cell.detailTextLabel.font = [UIFont monospacedSystemFontOfSize:9 weight:UIFontWeightRegular];
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    cell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ContainerBrowseVC *vc = [[ContainerBrowseVC alloc] init];
    vc.container = self.entries[indexPath.row][@"path"];
    vc.rel = @"";
    [self.navigationController pushViewController:vc animated:YES];
}

@end

@implementation ContainerBrowseVC

- (instancetype)init { return [super initWithStyle:UITableViewStyleInsetGrouped]; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.rel.length ? self.rel.lastPathComponent : NSLocalizedString(@"Container", nil);
    self.entries = @[];
    UIBarButtonItem *imp = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Import", nil)
                                                             style:UIBarButtonItemStylePlain
                                                            target:self action:@selector(importFile)];
    self.navigationItem.rightBarButtonItem = imp;
    [self load];
}

- (void)load {
    NSString *container = self.container;
    NSString *rel = self.rel;
    dispatch_async(BQWorkQueue(), ^{
        NSMutableArray *out = [NSMutableArray array];
        NSArray *names = BQListPath(container, rel, NULL);
        for (NSString *name in names) {
            NSString *child = rel.length ? [rel stringByAppendingPathComponent:name] : name;
            NSDictionary *st = BQStatPath(container, child, NULL);
            if (!st) continue;
            [out addObject:@{@"name": name, @"rel": child, @"dir": st[@"isDir"], @"size": st[@"size"]}];
        }
        [out sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
            BOOL da = [a[@"dir"] boolValue], db = [b[@"dir"] boolValue];
            if (da != db) return da ? NSOrderedAscending : NSOrderedDescending;
            return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]];
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.entries = out;
            [self.tableView reloadData];
        });
    });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.entries.count; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.entries.count ? (self.rel.length ? self.rel : NSLocalizedString(@"Container", nil)) : NSLocalizedString(@"Empty", nil);
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return self.container;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"entry"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"entry"];
    NSDictionary *e = self.entries[indexPath.row];
    BOOL isDir = [e[@"dir"] boolValue];
    cell.textLabel.text = e[@"name"];
    cell.accessoryType = isDir ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    cell.detailTextLabel.text = isDir ? NSLocalizedString(@"Directory", nil)
                                      : [NSByteCountFormatter stringFromByteCount:[e[@"size"] longLongValue]
                                                                       countStyle:NSByteCountFormatterCountStyleFile];
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *e = self.entries[indexPath.row];
    if ([e[@"dir"] boolValue]) {
        ContainerBrowseVC *vc = [[ContainerBrowseVC alloc] init];
        vc.container = self.container;
        vc.rel = e[@"rel"];
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        FileViewVC *vc = [[FileViewVC alloc] init];
        vc.container = self.container;
        vc.rel = e[@"rel"];
        vc.displayName = e[@"name"];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIContextualAction *del = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                     title:NSLocalizedString(@"Delete", nil)
                                                                   handler:^(UIContextualAction *a, UIView *v, void (^done)(BOOL)) {
        NSDictionary *e = self.entries[indexPath.row];
        BQConfirm(self, NSLocalizedString(@"Delete file?", nil), e[@"rel"], ^{
            NSString *err = nil;
            if (!BQDeletePath(self.container, e[@"rel"], &err)) BQAlert(self, NSLocalizedString(@"Delete failed", nil), err ?: @"-");
            [self load];
        });
        done(YES);
    }];
    return [UISwipeActionsConfiguration configurationWithActions:@[del]];
}

- (void)importFile {
    UIDocumentPickerViewController *p = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.data"]
                                                                                                inMode:UIDocumentPickerModeImport];
    p.delegate = self;
    p.allowsMultipleSelection = NO;
    [self presentViewController:p animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *u = urls.firstObject;
    if (!u) return;
    BOOL access = [u startAccessingSecurityScopedResource];
    NSData *data = [NSData dataWithContentsOfURL:u];
    if (access) [u stopAccessingSecurityScopedResource];
    if (!data.length) { BQAlert(self, NSLocalizedString(@"Import failed", nil), @"empty file"); return; }
    NSString *name = u.lastPathComponent.length ? u.lastPathComponent : @"file";
    NSString *rel = self.rel.length ? [self.rel stringByAppendingPathComponent:name] : name;
    NSString *err = nil;
    if (!BQWritePath(self.container, rel, data, &err)) {
        BQAlert(self, NSLocalizedString(@"Import failed", nil), err ?: @"-");
        return;
    }
    [self load];
}

@end

@implementation FileViewVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = self.displayName ?: NSLocalizedString(@"File", nil);
    self.textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.textView.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
    self.textView.alwaysBounceVertical = YES;
    [self.view addSubview:self.textView];

    NSString *err = nil;
    NSData *data = BQReadPath(self.container, self.rel, &err);
    if (!data) { self.textView.text = err ?: @"read failed"; return; }
    id plist = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:nil];
    if (plist) {
        self.textView.text = [plist description];
    } else {
        NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (s.length) {
            self.textView.text = s;
            self.editable = YES;
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", nil)
                                                                                     style:UIBarButtonItemStyleDone
                                                                                    target:self action:@selector(save)];
        } else {
            NSMutableString *hex = [NSMutableString string];
            const uint8_t *b = data.bytes;
            NSUInteger n = MIN(data.length, (NSUInteger)4096);
            for (NSUInteger i = 0; i < n; i++) {
                [hex appendFormat:@"%02x ", b[i]];
                if ((i + 1) % 16 == 0) [hex appendString:@"\n"];
            }
            self.textView.text = [NSString stringWithFormat:@"%@\n%@", NSLocalizedString(@"Binary file", nil), hex];
        }
    }
}

- (void)save {
    NSData *data = [self.textView.text dataUsingEncoding:NSUTF8StringEncoding];
    NSString *err = nil;
    if (!BQWritePath(self.container, self.rel, data, &err)) {
        BQAlert(self, NSLocalizedString(@"Save failed", nil), err ?: @"-");
        return;
    }
    BQAlert(self, NSLocalizedString(@"Saved", nil), self.rel);
}

@end
