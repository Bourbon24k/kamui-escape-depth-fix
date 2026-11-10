#import "LogVC.h"
#import "BQCore.h"
#import "BQUI.h"

@interface LogVC ()
@property (nonatomic, strong) UITextView *textView;
@end

@implementation LogVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Log";
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.textView.editable = NO;
    self.textView.selectable = YES;
    self.textView.alwaysBounceVertical = YES;
    self.textView.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
    self.textView.textContainerInset = UIEdgeInsetsMake(12, 12, 24, 12);
    [self.view addSubview:self.textView];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                           target:self
                                                                                           action:@selector(loadLog)];
    UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Share", nil)
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(shareLog)];
    self.navigationItem.rightBarButtonItems = @[share, self.navigationItem.rightBarButtonItem];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Clear"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(clearLog)];
    [self loadLog];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadLog];
}

- (void)loadLog {
    NSString *text = [NSString stringWithContentsOfFile:BQLogPath() encoding:NSUTF8StringEncoding error:nil] ?: @"(empty log)";
    self.textView.text = text;
    if (text.length) {
        NSRange r = NSMakeRange(text.length - 1, 1);
        [self.textView scrollRangeToVisible:r];
    }
}

- (void)clearLog {
    BQConfirm(self, NSLocalizedString(@"Clear log?", nil), NSLocalizedString(@"Truncate bqtool.log.", nil), ^{
        [[NSFileManager defaultManager] createFileAtPath:BQLogPath() contents:nil attributes:nil];
        [self loadLog];
    });
}

- (NSString *)sanitizedLogText:(NSString *)text {
    NSArray<NSArray<NSString *> *> *replacements = @[
        @[@"[0-9A-Fa-f]{8}-(?:[0-9A-Fa-f]{4}-){3}[0-9A-Fa-f]{12}", @"[UUID]"],
        @[@"/Users/[^/\\s]+", @"/Users/[REDACTED]"],
        @[@"group\\.[A-Za-z0-9._-]+", @"[APP_GROUP]"],
        @[@"0x[0-9A-Fa-f]{8,}", @"[ADDRESS]"],
    ];
    NSString *result = text ?: @"";
    for (NSArray<NSString *> *replacement in replacements) {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:replacement[0] options:0 error:nil];
        result = [regex stringByReplacingMatchesInString:result
                                                 options:0
                                                   range:NSMakeRange(0, result.length)
                                            withTemplate:replacement[1]];
    }
    return result;
}

- (void)shareLog {
    NSString *text = [self sanitizedLogText:self.textView.text];
    UIActivityViewController *share = [[UIActivityViewController alloc] initWithActivityItems:@[text]
                                                                         applicationActivities:nil];
    share.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.firstObject;
    [self presentViewController:share animated:YES completion:nil];
}

@end
