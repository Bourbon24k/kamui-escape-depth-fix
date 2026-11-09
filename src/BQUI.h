#pragma once
#import <UIKit/UIKit.h>

void BQAlert(UIViewController *vc, NSString *title, NSString *message);
void BQConfirm(UIViewController *vc, NSString *title, NSString *message, void (^action)(void));
UIViewController *BQTopViewController(void);
NSString *BQLocalizedString(NSString *key);
void BQReloadRootViewController(void);

#undef NSLocalizedString
#define NSLocalizedString(key, comment) BQLocalizedString((key))

@interface BQBusyView : UIView
+ (instancetype)showInView:(UIView *)view text:(NSString *)text;
- (void)hide;
@end
