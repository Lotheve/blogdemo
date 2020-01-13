//
//  GoodsASearchViewModel.h
//  MVVMRACDemo
//
//  Created by 卢旭峰 on 2019/2/10.
//  Copyright © 2019 Lotheve. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ValueBox.h"
@class GoodsAViewModel;

NS_ASSUME_NONNULL_BEGIN

@interface GoodsASearchViewModel : NSObject

@property (nonatomic, copy) NSString *searchKey;

@property (nonatomic, strong, readonly, getter=isSearchEnable) BoolBox *searchEnable;

@property (nonatomic, strong, getter=isNeedRefresh) BoolBox *needRefresh;

@property (nonatomic, copy, readonly) NSArray<GoodsAViewModel *> *goods;

- (void)searchGoods;

@end

NS_ASSUME_NONNULL_END
