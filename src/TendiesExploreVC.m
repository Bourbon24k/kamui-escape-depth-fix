#import "TendiesExploreVC.h"
#import "BQCore.h"
#import "BQUI.h"

static NSString * const kCatalogBase = @"https://raw.githubusercontent.com/SerStars/Nugget-Wallpapers/main/";
static NSString * const kCustomCatalog = @"https://raw.githubusercontent.com/SerStars/Nugget-Wallpapers/main/wallpapers-custom.json";
static NSString * const kAppleCatalog = @"https://raw.githubusercontent.com/SerStars/Nugget-Wallpapers/main/wallpapers-apple.json";
static NSString * const kCAPlaygroundCatalog = @"https://raw.githubusercontent.com/CAPlayground/wallpapers/main/wallpapers.json";
static NSString * const kCAPlaygroundBase = @"https://raw.githubusercontent.com/CAPlayground/wallpapers/refs/heads/main/";
static NSString * const kFavoritesKey = @"BQWallpaperFavorites";
static NSString * const kWallpaperCell = @"WallpaperCardCell";

@interface WallpaperCardCell : UICollectionViewCell
@property (nonatomic, copy) void (^downloadAction)(void);
@property (nonatomic, copy) void (^favoriteAction)(void);
- (void)configureWithItem:(NSDictionary *)item favorite:(BOOL)favorite;
@end

@interface WallpaperCardCell ()
@property (nonatomic, strong) UIImageView *previewView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *authorLabel;
@property (nonatomic, strong) UIButton *favoriteButton;
@property (nonatomic, strong) UIButton *downloadButton;
@property (nonatomic, copy) NSString *previewURL;
@end

@implementation WallpaperCardCell

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.contentView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        self.contentView.layer.cornerRadius = 22;
        self.contentView.layer.masksToBounds = YES;

        self.previewView = [UIImageView new];
        self.previewView.translatesAutoresizingMaskIntoConstraints = NO;
        self.previewView.contentMode = UIViewContentModeScaleAspectFill;
        self.previewView.clipsToBounds = YES;
        self.previewView.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1];
        [self.contentView addSubview:self.previewView];

        UIVisualEffectView *footer = [[UIVisualEffectView alloc] initWithEffect:
            [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial]];
        footer.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:footer];

        self.titleLabel = [UILabel new];
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
        self.titleLabel.textColor = [UIColor colorWithRed:0.02 green:0.67 blue:0.82 alpha:1];
        self.titleLabel.numberOfLines = 1;

        self.authorLabel = [UILabel new];
        self.authorLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.authorLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        self.authorLabel.textColor = [UIColor colorWithRed:0.22 green:0.72 blue:0.82 alpha:0.72];
        self.authorLabel.numberOfLines = 1;

        self.downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.downloadButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.downloadButton setImage:[UIImage systemImageNamed:@"arrow.down.circle"] forState:UIControlStateNormal];
        self.downloadButton.tintColor = [UIColor colorWithRed:0.05 green:0.48 blue:0.95 alpha:1];
        self.downloadButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [self.downloadButton addTarget:self action:@selector(downloadTapped) forControlEvents:UIControlEventTouchUpInside];

        [footer.contentView addSubview:self.titleLabel];
        [footer.contentView addSubview:self.authorLabel];
        [footer.contentView addSubview:self.downloadButton];

        self.favoriteButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.favoriteButton.translatesAutoresizingMaskIntoConstraints = NO;
        self.favoriteButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.88];
        self.favoriteButton.layer.cornerRadius = 25;
        self.favoriteButton.tintColor = [UIColor colorWithWhite:0.4 alpha:1];
        [self.favoriteButton addTarget:self action:@selector(favoriteTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.favoriteButton];

        [NSLayoutConstraint activateConstraints:@[
            [self.previewView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
            [self.previewView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [self.previewView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [self.previewView.bottomAnchor constraintEqualToAnchor:footer.topAnchor],
            [footer.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [footer.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [footer.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
            [footer.heightAnchor constraintEqualToConstant:84],
            [self.titleLabel.leadingAnchor constraintEqualToAnchor:footer.contentView.leadingAnchor constant:15],
            [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.downloadButton.leadingAnchor constant:-4],
            [self.titleLabel.topAnchor constraintEqualToAnchor:footer.contentView.topAnchor constant:13],
            [self.authorLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
            [self.authorLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.downloadButton.leadingAnchor constant:-4],
            [self.authorLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:5],
            [self.downloadButton.trailingAnchor constraintEqualToAnchor:footer.contentView.trailingAnchor constant:-12],
            [self.downloadButton.centerYAnchor constraintEqualToAnchor:footer.contentView.centerYAnchor],
            [self.downloadButton.widthAnchor constraintEqualToConstant:44],
            [self.downloadButton.heightAnchor constraintEqualToConstant:48],
            [self.favoriteButton.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:11],
            [self.favoriteButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-11],
            [self.favoriteButton.widthAnchor constraintEqualToConstant:50],
            [self.favoriteButton.heightAnchor constraintEqualToConstant:50],
        ]];
    }
    return self;
}

- (void)configureWithItem:(NSDictionary *)item favorite:(BOOL)favorite {
    self.titleLabel.text = item[@"name"];
    NSString *author = item[@"authors"];
    self.authorLabel.text = [author isKindOfClass:[NSString class]] && author.length ? author : @"Apple Collections";
    UIImage *star = [UIImage systemImageNamed:favorite ? @"star.fill" : @"star"];
    [self.favoriteButton setImage:star forState:UIControlStateNormal];
    self.favoriteButton.tintColor = favorite ? [UIColor colorWithRed:0.05 green:0.67 blue:0.82 alpha:1] : [UIColor colorWithWhite:0.4 alpha:1];

    NSString *relativePreview = item[@"preview"];
    if (![relativePreview isKindOfClass:[NSString class]] || !relativePreview.length) {
        self.previewURL = nil;
        self.previewView.image = nil;
        return;
    }
    NSString *previewBase = [item[@"bq_preview_base"] isKindOfClass:NSString.class] ? item[@"bq_preview_base"] : kCatalogBase;
    NSURL *url = [NSURL URLWithString:relativePreview relativeToURL:[NSURL URLWithString:previewBase]].absoluteURL;
    self.previewURL = url.absoluteString;
    self.previewView.image = nil;
    UIImage *cached = [WallpaperCardCell imageForURL:self.previewURL];
    if (cached) {
        self.previewView.image = cached;
        return;
    }
    NSString *expectedURL = [self.previewURL copy];
    [[NSURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        UIImage *image = data.length ? [UIImage imageWithData:data] : nil;
        if (image) [WallpaperCardCell setImage:image forURL:expectedURL];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.previewURL isEqualToString:expectedURL] && image) self.previewView.image = image;
        });
    }] resume];
}

+ (NSCache<NSString *, UIImage *> *)previewCache {
    static NSCache<NSString *, UIImage *> *cache;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ cache = [NSCache new]; cache.countLimit = 160; });
    return cache;
}

+ (UIImage *)imageForURL:(NSString *)url { return url.length ? [[self previewCache] objectForKey:url] : nil; }
+ (void)setImage:(UIImage *)image forURL:(NSString *)url { if (image && url.length) [[self previewCache] setObject:image forKey:url]; }
- (void)downloadTapped { if (self.downloadAction) self.downloadAction(); }
- (void)favoriteTapped { if (self.favoriteAction) self.favoriteAction(); }

@end

@interface WallpaperExploreHeader : UIView
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UISegmentedControl *providerControl;
@property (nonatomic, strong) UISegmentedControl *categoryControl;
@property (nonatomic, copy) void (^onProviderSelection)(NSInteger index);
@end

@implementation WallpaperExploreHeader
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.searchBar = [UISearchBar new];
        self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
        self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
        self.searchBar.placeholder = NSLocalizedString(@"Search wallpapers", nil);
        [self addSubview:self.searchBar];

        NSArray *providerNames = @[@"Cowabunga", @"CAPlayground", @"Both"];
        self.providerControl = [[UISegmentedControl alloc] initWithItems:providerNames];
        self.providerControl.translatesAutoresizingMaskIntoConstraints = NO;
        self.providerControl.selectedSegmentIndex = 0;
        self.providerControl.selectedSegmentTintColor = UIColor.secondarySystemBackgroundColor;
        self.providerControl.backgroundColor = UIColor.tertiarySystemFillColor;
        NSDictionary *segmentTitleAttributes = @{NSForegroundColorAttributeName: UIColor.labelColor};
        [self.providerControl setTitleTextAttributes:segmentTitleAttributes forState:UIControlStateNormal];
        [self.providerControl setTitleTextAttributes:segmentTitleAttributes forState:UIControlStateSelected];
        [self.providerControl addTarget:self action:@selector(providerControlChanged) forControlEvents:UIControlEventValueChanged];
        [self addSubview:self.providerControl];

        self.categoryControl = [[UISegmentedControl alloc] initWithItems:@[NSLocalizedString(@"Custom", nil), NSLocalizedString(@"Apple", nil)]];
        self.categoryControl.translatesAutoresizingMaskIntoConstraints = NO;
        self.categoryControl.selectedSegmentIndex = 0;
        self.categoryControl.selectedSegmentTintColor = UIColor.secondarySystemBackgroundColor;
        self.categoryControl.backgroundColor = UIColor.tertiarySystemFillColor;
        [self.categoryControl setTitleTextAttributes:segmentTitleAttributes forState:UIControlStateNormal];
        [self.categoryControl setTitleTextAttributes:segmentTitleAttributes forState:UIControlStateSelected];
        [self addSubview:self.categoryControl];

        [NSLayoutConstraint activateConstraints:@[
            [self.searchBar.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:8],
            [self.searchBar.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-8],
            [self.searchBar.topAnchor constraintEqualToAnchor:self.topAnchor],
            [self.searchBar.heightAnchor constraintEqualToConstant:56],
            [self.providerControl.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16],
            [self.providerControl.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16],
            [self.providerControl.topAnchor constraintEqualToAnchor:self.searchBar.bottomAnchor constant:4],
            [self.providerControl.heightAnchor constraintEqualToConstant:44],
            [self.categoryControl.leadingAnchor constraintEqualToAnchor:self.providerControl.leadingAnchor],
            [self.categoryControl.trailingAnchor constraintEqualToAnchor:self.providerControl.trailingAnchor],
            [self.categoryControl.topAnchor constraintEqualToAnchor:self.providerControl.bottomAnchor constant:12],
            [self.categoryControl.heightAnchor constraintEqualToConstant:44],
        ]];
    }
    return self;
}
- (void)providerControlChanged {
    if (self.onProviderSelection) self.onProviderSelection(self.providerControl.selectedSegmentIndex);
}
@end

@interface TendiesExploreVC ()
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) WallpaperExploreHeader *filtersHeader;
@property (nonatomic, strong) NSArray<NSDictionary *> *items;
@property (nonatomic, strong) NSArray<NSDictionary *> *filtered;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, assign) BOOL favoritesOnly;
@property (nonatomic, assign) NSInteger categoryIndex;
@property (nonatomic, assign) NSInteger providerIndex;
- (void)providerChanged:(NSInteger)index;
@end

@implementation TendiesExploreVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Explore Wallpapers", nil);
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    // The catalog has its own filters immediately below the navigation bar.
    // An expanded large-title bar overlaps those controls on compact layouts.
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;

    UIButton *filterButton = [UIButton buttonWithType:UIButtonTypeSystem];
    filterButton.frame = CGRectMake(0, 0, 50, 50);
    filterButton.layer.cornerRadius = 25;
    filterButton.layer.borderWidth = 1;
    filterButton.layer.borderColor = [UIColor colorWithWhite:0.88 alpha:1].CGColor;
    filterButton.tintColor = [UIColor colorWithRed:0.02 green:0.67 blue:0.82 alpha:1];
    [filterButton setImage:[UIImage systemImageNamed:@"line.3.horizontal"] forState:UIControlStateNormal];
    [filterButton addTarget:self action:@selector(showFilters) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:filterButton];

    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.minimumInteritemSpacing = 14;
    layout.minimumLineSpacing = 16;
    layout.sectionInset = UIEdgeInsetsMake(12, 16, 24, 16);
    layout.headerReferenceSize = CGSizeZero;
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.backgroundColor = UIColor.systemBackgroundColor;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:WallpaperCardCell.class forCellWithReuseIdentifier:kWallpaperCell];
    self.filtersHeader = [[WallpaperExploreHeader alloc] initWithFrame:CGRectZero];
    self.filtersHeader.translatesAutoresizingMaskIntoConstraints = NO;
    self.filtersHeader.searchBar.delegate = self;
    [self.filtersHeader.categoryControl addTarget:self action:@selector(categoryChanged:) forControlEvents:UIControlEventValueChanged];
    __weak typeof(self) weakSelf = self;
    self.filtersHeader.onProviderSelection = ^(NSInteger index) { [weakSelf providerChanged:index]; };
    [self.view addSubview:self.filtersHeader];
    [self.view addSubview:self.collectionView];
    [NSLayoutConstraint activateConstraints:@[
        [self.filtersHeader.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.filtersHeader.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.filtersHeader.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.filtersHeader.heightAnchor constraintEqualToConstant:173],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.topAnchor constraintEqualToAnchor:self.filtersHeader.bottomAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    UIRefreshControl *refresh = [UIRefreshControl new];
    [refresh addTarget:self action:@selector(loadCatalog) forControlEvents:UIControlEventValueChanged];
    self.collectionView.refreshControl = refresh;
    self.items = @[];
    self.filtered = @[];
    [self loadCatalog];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    CGFloat width = CGRectGetWidth(self.collectionView.bounds);
    CGFloat cardWidth = floor((width - 32 - 14) / 2.0);
    if (cardWidth > 0) {
        CGFloat height = cardWidth * 1.60 + 84;
        if (fabs(layout.itemSize.width - cardWidth) > 0.5 || fabs(layout.itemSize.height - height) > 0.5) {
            layout.itemSize = CGSizeMake(cardWidth, height);
            [layout invalidateLayout];
        }
    }
}

- (void)loadCatalog {
    if (self.loading) { [self.collectionView.refreshControl endRefreshing]; return; }
    self.loading = YES;
    NSInteger requestedProvider = self.providerIndex;
    dispatch_group_t group = dispatch_group_create();
    __block NSMutableArray *all = [NSMutableArray array];
    __block NSString *firstError = nil;
    NSLock *errorLock = [NSLock new];

    void (^fetch)(NSString *, NSString *, NSString *, BOOL) = ^(NSString *urlString, NSString *provider, NSString *category, BOOL caPlayground) {
        dispatch_group_enter(group);
        NSURL *u = [NSURL URLWithString:urlString];
        [[NSURLSession.sharedSession dataTaskWithURL:u completionHandler:^(NSData *data, NSURLResponse *resp, NSError *error) {
            NSInteger status = [resp isKindOfClass:NSHTTPURLResponse.class] ? [(NSHTTPURLResponse *)resp statusCode] : 200;
            if (error || status < 200 || status >= 300) {
                [errorLock lock];
                if (!firstError) firstError = error.localizedDescription ?: [NSString stringWithFormat:@"HTTP %ld", (long)status];
                [errorLock unlock];
            } else if (data.length) {
                NSError *jsonError = nil;
                id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                NSArray *entries = nil;
                if (caPlayground && [obj isKindOfClass:NSDictionary.class]) {
                    id value = ((NSDictionary *)obj)[@"wallpapers"];
                    if ([value isKindOfClass:NSArray.class]) entries = value;
                } else if ([obj isKindOfClass:NSArray.class]) {
                    entries = obj;
                }
                if (entries) {
                    NSMutableArray *tagged = [NSMutableArray array];
                    for (id entry in entries) {
                        if (![entry isKindOfClass:NSDictionary.class]) continue;
                        NSMutableDictionary *copy = [entry mutableCopy];
                        if (caPlayground) {
                            copy[@"url"] = copy[@"file"] ?: @"";
                            copy[@"authors"] = copy[@"creator"] ?: @"";
                            copy[@"bq_preview_base"] = kCAPlaygroundBase;
                            copy[@"bq_download_base"] = kCAPlaygroundBase;
                        } else {
                            copy[@"bq_preview_base"] = kCatalogBase;
                            copy[@"bq_download_base"] = kCatalogBase;
                        }
                        copy[@"bq_category"] = category;
                        copy[@"bq_provider"] = provider;
                        [tagged addObject:copy];
                    }
                    @synchronized (all) { [all addObjectsFromArray:tagged]; }
                } else {
                    [errorLock lock];
                    if (!firstError) firstError = jsonError.localizedDescription ?: @"catalog has an unexpected format";
                    [errorLock unlock];
                }
            } else {
                [errorLock lock];
                if (!firstError) firstError = @"empty catalog response";
                [errorLock unlock];
            }
            dispatch_group_leave(group);
        }] resume];
    };
    if (self.providerIndex == 0 || self.providerIndex == 2) {
        fetch(kCustomCatalog, @"Cowabunga", @"Custom", NO);
        fetch(kAppleCatalog, @"Cowabunga", @"Apple", NO);
    }
    if (self.providerIndex == 1 || self.providerIndex == 2) {
        fetch(kCAPlaygroundCatalog, @"CAPlayground", @"Custom", YES);
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        self.loading = NO;
        [self.collectionView.refreshControl endRefreshing];
        if (requestedProvider != self.providerIndex) { [self loadCatalog]; return; }
        NSMutableArray *unique = [NSMutableArray array];
        NSMutableSet *seen = [NSMutableSet set];
        for (id entry in all) {
            NSDictionary *d = entry;
            NSString *url = d[@"url"];
            NSString *name = d[@"name"];
            if (![url isKindOfClass:NSString.class] || !url.length || ![name isKindOfClass:NSString.class] || !name.length) continue;
            NSString *key = [NSString stringWithFormat:@"%@|%@|%@", d[@"bq_provider"] ?: @"", d[@"bq_category"] ?: @"", url];
            if ([seen containsObject:key]) continue;
            [seen addObject:key];
            [unique addObject:d];
        }
        [unique sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
            return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]];
        }];
        self.items = unique;
        [self applyFilters];
        if (firstError && unique.count == 0) BQAlert(self, NSLocalizedString(@"Catalog failed", nil), firstError);
        BQLog(@"tendies catalog: %lu entries", (unsigned long)unique.count);
    });
}

- (void)applyFilters {
    NSString *query = self.filtersHeader.searchBar.text ?: @"";
    NSString *category = self.categoryIndex == 1 ? @"Apple" : @"Custom";
    NSSet *favorites = [NSSet setWithArray:[[NSUserDefaults standardUserDefaults] stringArrayForKey:kFavoritesKey] ?: @[]];
    NSMutableArray *matches = [NSMutableArray array];
    for (NSDictionary *item in self.items) {
        if (![item[@"bq_category"] isEqualToString:category]) continue;
        NSString *favoriteKey = [NSString stringWithFormat:@"%@|%@", item[@"bq_provider"] ?: @"Cowabunga", item[@"url"] ?: @""];
        if (self.favoritesOnly && ![favorites containsObject:favoriteKey]) continue;
        NSString *name = item[@"name"] ?: @"";
        NSString *description = item[@"description"] ?: @"";
        NSString *authors = item[@"authors"] ?: @"";
        if (query.length && ![name localizedCaseInsensitiveContainsString:query] &&
            ![description localizedCaseInsensitiveContainsString:query] &&
            ![authors localizedCaseInsensitiveContainsString:query]) continue;
        [matches addObject:item];
    }
    self.filtered = matches;
    [self.collectionView reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText { [self applyFilters]; }

- (void)showFilters {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Explore Wallpapers", nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSString *favoriteTitle = self.favoritesOnly ? NSLocalizedString(@"Show all wallpapers", nil) : NSLocalizedString(@"Show favorites", nil);
    [sheet addAction:[UIAlertAction actionWithTitle:favoriteTitle style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        self.favoritesOnly = !self.favoritesOnly;
        [self applyFilters];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Refresh catalog", nil) style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) { [self loadCatalog]; }]];
    [sheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    if (popover) { popover.barButtonItem = self.navigationItem.rightBarButtonItem; }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (BOOL)isFavorite:(NSDictionary *)item {
    NSString *key = [NSString stringWithFormat:@"%@|%@", item[@"bq_provider"] ?: @"Cowabunga", item[@"url"] ?: @""];
    return [[[NSUserDefaults standardUserDefaults] stringArrayForKey:kFavoritesKey] containsObject:key];
}

- (void)toggleFavorite:(NSDictionary *)item {
    NSMutableArray *favorites = [[[NSUserDefaults standardUserDefaults] stringArrayForKey:kFavoritesKey] mutableCopy] ?: [NSMutableArray array];
    NSString *key = [NSString stringWithFormat:@"%@|%@", item[@"bq_provider"] ?: @"Cowabunga", item[@"url"] ?: @""];
    if ([favorites containsObject:key]) [favorites removeObject:key]; else if ([item[@"url"] length]) [favorites addObject:key];
    [[NSUserDefaults standardUserDefaults] setObject:favorites forKey:kFavoritesKey];
    [self applyFilters];
}

- (void)download:(NSDictionary *)item {
    NSString *rel = item[@"url"];
    if (![rel isKindOfClass:NSString.class] || !rel.length) {
        BQAlert(self, NSLocalizedString(@"Download failed", nil), NSLocalizedString(@"The catalog entry has no valid wallpaper URL.", nil));
        return;
    }
    NSString *baseString = [item[@"bq_download_base"] isKindOfClass:NSString.class] ? item[@"bq_download_base"] : kCatalogBase;
    NSURL *base = [NSURL URLWithString:baseString];
    NSURL *url = [NSURL URLWithString:rel relativeToURL:base].absoluteURL;
    NSString *scheme = url.scheme.lowercaseString;
    if (!url || (![scheme isEqualToString:@"https"] && ![scheme isEqualToString:@"http"])) {
        BQAlert(self, NSLocalizedString(@"Download failed", nil), NSLocalizedString(@"The catalog entry has an invalid wallpaper URL.", nil));
        return;
    }
    NSString *name = item[@"name"] ?: url.lastPathComponent;
    BQBusyView *busy = [BQBusyView showInView:self.view text:[NSString stringWithFormat:NSLocalizedString(@"Downloading %@...", nil), name]];
    [[NSURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [busy hide];
            NSInteger status = [response isKindOfClass:NSHTTPURLResponse.class] ? [(NSHTTPURLResponse *)response statusCode] : 200;
            if (error || status < 200 || status >= 300) { BQAlert(self, NSLocalizedString(@"Download failed", nil), error.localizedDescription ?: [NSString stringWithFormat:NSLocalizedString(@"HTTP %ld", nil), (long)status]); return; }
            if (data.length < 4 || ((const uint8_t *)data.bytes)[0] != 'P' || ((const uint8_t *)data.bytes)[1] != 'K') {
                BQAlert(self, NSLocalizedString(@"Download failed", nil), NSLocalizedString(@"The server response is not a .tendies ZIP file.", nil));
                return;
            }
            NSString *directory = [BQDocuments() stringByAppendingPathComponent:@"tendies"];
            [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
            NSString *leaf = url.lastPathComponent.length ? url.lastPathComponent : @"wallpaper.tendies";
            NSString *destination = [directory stringByAppendingPathComponent:leaf];
            if ([[NSFileManager defaultManager] fileExistsAtPath:destination]) {
                destination = [directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@", NSUUID.UUID.UUIDString, leaf]];
            }
            NSError *writeError = nil;
            if (![data writeToURL:[NSURL fileURLWithPath:destination] options:NSDataWritingAtomic error:&writeError]) {
                BQAlert(self, NSLocalizedString(@"Save failed", nil), writeError.localizedDescription ?: NSLocalizedString(@"write error", nil));
                return;
            }
            BQLog(@"downloaded %@ (%lu bytes) -> %@", name, (unsigned long)data.length, leaf);
            if (self.onDownload) self.onDownload();
            UIAlertController *prompt = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Downloaded", nil)
                message:[NSString stringWithFormat:NSLocalizedString(@"%@ saved to Documents/tendies.\nApply now?", nil), name]
                preferredStyle:UIAlertControllerStyleAlert];
            [prompt addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Later", nil) style:UIAlertActionStyleCancel handler:nil]];
            [prompt addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Apply now", nil) style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
                BQBusyView *work = [BQBusyView showInView:self.view text:NSLocalizedString(@"Applying wallpaper...", nil)];
                dispatch_async(BQWorkQueue(), ^{
                    NSString *applyError = nil;
                    int count = 0;
                    BOOL ok = BQApplyTendies([NSURL fileURLWithPath:destination], &count, &applyError);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [work hide];
                        if (!ok) { BQAlert(self, NSLocalizedString(@"Apply failed", nil), applyError ?: NSLocalizedString(@"unknown error", nil)); return; }
                        UIAlertController *done = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Applied", nil)
                            message:[NSString stringWithFormat:NSLocalizedString(@"%d descriptor(s) written.\n\n1. Open PosterBoard once so it discovers the new wallpapers.\n2. Close PosterBoard from the App Switcher.\n3. Return to KAMUI and tap Respring.\n4. After respring, touch and hold the Lock Screen, tap +, and select the wallpaper.", nil), count]
                            preferredStyle:UIAlertControllerStyleAlert];
                        [done addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Open PosterBoard", nil) style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *x) {
                            if (!BQOpenPosterBoard()) BQAlert(self, NSLocalizedString(@"Open failed", nil), NSLocalizedString(@"Could not open com.apple.PosterBoard.", nil));
                        }]];
                        [done addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Respring", nil) style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *x) { BQRespring(); }]];
                        [done addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
                        [self presentViewController:done animated:YES completion:nil];
                    });
                });
            }]];
            [self presentViewController:prompt animated:YES completion:nil];
        });
    }] resume];
}

#pragma mark - Collection view

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section { return self.filtered.count; }

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WallpaperCardCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kWallpaperCell forIndexPath:indexPath];
    NSDictionary *item = self.filtered[indexPath.item];
    [cell configureWithItem:item favorite:[self isFavorite:item]];
    __weak typeof(self) weakSelf = self;
    cell.downloadAction = ^{ [weakSelf download:item]; };
    cell.favoriteAction = ^{ [weakSelf toggleFavorite:item]; };
    return cell;
}

- (void)providerChanged:(NSInteger)index {
    self.providerIndex = index;
    // CAPlayground only publishes custom wallpapers, so avoid leaving its catalog
    // filtered to an Apple category that cannot contain any results.
    if (index == 1) self.categoryIndex = 0;
    self.filtersHeader.categoryControl.selectedSegmentIndex = self.categoryIndex;
    [self.filtersHeader.categoryControl setEnabled:(index != 1) forSegmentAtIndex:1];
    self.favoritesOnly = NO;
    [self loadCatalog];
}

- (void)categoryChanged:(UISegmentedControl *)sender {
    if (self.providerIndex == 1 && sender.selectedSegmentIndex == 1) {
        sender.selectedSegmentIndex = 0;
        return;
    }
    self.categoryIndex = sender.selectedSegmentIndex;
    self.favoritesOnly = NO;
    [self applyFilters];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    [self download:self.filtered[indexPath.item]];
}

@end
