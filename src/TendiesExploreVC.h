#pragma once
#import <UIKit/UIKit.h>

@interface TendiesExploreVC : UIViewController <UISearchResultsUpdating, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, copy) void (^onDownload)(void);
@end
