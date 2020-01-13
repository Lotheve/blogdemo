
//
//  GoodsBSearchViewModel.m
//  MVVMRACDemo
//
//  Created by 卢旭峰 on 2019/2/10.
//  Copyright © 2019 Lotheve. All rights reserved.
//

#import "GoodsBSearchViewModel.h"
#import "ValueBox.h"
#import "GoodsBViewModel.h"
#import "GoodsBModel.h"

@interface GoodsBSearchViewModel ()

//@property (nonatomic, assign, readwrite) BOOL searchEnable;

@property (nonatomic, copy, readwrite) NSArray<GoodsBViewModel *> *goods;

@property (nonatomic, strong, readwrite) RACCommand *searchCommand;

@end

@implementation GoodsBSearchViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
//        _searchEnable = NO;
//        _needRefresh = NO;
        
        RACSignal *searchEnableSignal = [RACObserve(self, searchKey) map:^id _Nullable(NSString *_Nullable value) {
            return @(value && value.length > 0);
        }];
        @weakify(self);
        _searchCommand = [[RACCommand alloc] initWithEnabled:searchEnableSignal signalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
            @strongify(self);
            return [self singalForRequestGoods];
        }];
    }
    return self;
}

//- (void)setSearchKey:(NSString *)searchKey
//{
//    _searchKey = searchKey;
//    BOOL searchEnable = _searchKey && _searchKey.length > 0;
//    if (searchEnable != _searchEnable) {
//        self.searchEnable = searchEnable;
//    }
//}

//- (void)searchGoods
//{
//    @weakify(self);
//    [[self singalForRequestGoods] subscribeNext:^(NSArray <GoodsBViewModel *>*  _Nullable goods) {
//        @strongify(self);
//        self.goods = goods;
//        self.needRefresh = YES;
//    }];
//}

- (RACSignal *)singalForRequestGoods
{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        //模拟API请求
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSMutableArray *goods = [NSMutableArray array];
            for (int i = 0; i<20; i++) {
                GoodsBModel *model = [[GoodsBModel alloc] init];
                model.name = [NSString stringWithFormat:@"%@-%d",self.searchKey,i];
                model.des = [NSString stringWithFormat:@"商品%@，请认准！",model.name];
                model.stockCount = i%5;
                GoodsBViewModel *goodsVM = [[GoodsBViewModel alloc] initWithGoodsModel:model];
                [goods addObject:goodsVM];
            }
            self.goods = [goods copy];
            [subscriber sendNext:[goods copy]];
            [subscriber sendCompleted];
        });
        return nil;
    }];
}

//- (void)requestGoodsWithKey:(NSString *)key
//{
//    //模拟API请求
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        NSMutableArray *goods = [NSMutableArray array];
//        for (int i = 0; i<20; i++) {
//            GoodsBModel *model = [[GoodsBModel alloc] init];
//            model.name = [NSString stringWithFormat:@"%@-%d",key,i];
//            model.des = [NSString stringWithFormat:@"商品%@，请认准！",model.name];
//            model.stockCount = i%5;
//            GoodsBViewModel *goodsVM = [[GoodsBViewModel alloc] initWithGoodsModel:model];
//            [goods addObject:goodsVM];
//        }
//        self.goods = [goods copy];
//        self.needRefresh = YES;
//    });
//}

@end
