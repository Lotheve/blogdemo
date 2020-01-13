//
//  GoodsAViewModel.m
//  MVVMRACDemo
//
//  Created by 卢旭峰 on 2019/2/10.
//  Copyright © 2019 Lotheve. All rights reserved.
//

#import "GoodsAViewModel.h"
#import "GoodsAModel.h"

@interface GoodsAViewModel ()

@property (nonatomic, copy, readwrite) NSString *goodsName;

@property (nonatomic, copy, readwrite) NSString *goodsDescription;

@property (nonatomic, assign, readwrite) BOOL buyEnable;

@property (nonatomic, strong) GoodsAModel *goodsModel;

@end

@implementation GoodsAViewModel

- (instancetype)initWithGoodsModel:(GoodsAModel *)goodsModel;
{
    self = [super init];
    if (self) {
        _goodsModel = goodsModel;
    }
    return self;
}

- (BOOL)isBuyEnable
{
    return _goodsModel.stockCount > 0;
}

- (NSString *)goodsName
{
    return _goodsModel.name;
}

- (NSString *)goodsDescription
{
    NSString *des = _goodsModel.des && _goodsModel.des.length > 0 ? _goodsModel.des : @"无商品描述";
    if (_goodsModel.stockCount == 0) {
        des = [NSString stringWithFormat:@"%@（缺货）", des];
    }
    return des;
}


@end
