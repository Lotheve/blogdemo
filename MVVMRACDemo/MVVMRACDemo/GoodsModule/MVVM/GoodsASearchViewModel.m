
//
//  GoodsASearchViewModel.m
//  MVVMRACDemo
//
//  Created by 卢旭峰 on 2019/2/10.
//  Copyright © 2019 Lotheve. All rights reserved.
//

#import "GoodsASearchViewModel.h"
#import "ValueBox.h"
#import "GoodsAViewModel.h"
#import "GoodsAModel.h"

@interface GoodsASearchViewModel ()

@property (nonatomic, strong, readwrite) BoolBox *searchEnable;

@property (nonatomic, copy, readwrite) NSArray<GoodsAViewModel *> *goods;

@end

@implementation GoodsASearchViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _searchEnable = BOOL_VALUE(NO);
        _needRefresh = BOOL_VALUE(NO);
    }
    return self;
}

- (void)setSearchKey:(NSString *)searchKey
{
    _searchKey = searchKey;
    BOOL searchEnable = _searchKey && _searchKey.length > 0;
    if (searchEnable != _searchEnable.value) {
        self.searchEnable = BOOL_VALUE(searchEnable);
    }
}

- (void)searchGoods
{
    [self requestGoodsWithKey:_searchKey];
}

- (void)requestGoodsWithKey:(NSString *)key
{
    //模拟API请求
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSMutableArray *goods = [NSMutableArray array];
        for (int i = 0; i<20; i++) {
            GoodsAModel *model = [[GoodsAModel alloc] init];
            model.name = [NSString stringWithFormat:@"%@-%d",key,i];
            model.des = [NSString stringWithFormat:@"商品%@，请认准！",model.name];
            model.stockCount = i%5;
            GoodsAViewModel *goodsVM = [[GoodsAViewModel alloc] initWithGoodsModel:model];
            [goods addObject:goodsVM];
        }
        self.goods = [goods copy];
        self.needRefresh = BOOL_VALUE(YES);
    });
}

@end
