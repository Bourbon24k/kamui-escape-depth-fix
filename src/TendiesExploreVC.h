#pragma once
#import <UIKit/UIKit.h>

@interface TendiesExploreVC : UIViewController <UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, copy) void (^onDownload)(void);
@end
