//
//  GoodsAViewModel.h
//  MVVMRACDemo
//
//  Created by 卢旭峰 on 2019/2/10.
//  Copyright © 2019 Lotheve. All rights reserved.
//

#import <Foundation/Foundation.h>
@class GoodsAModel;

NS_ASSUME_NONNULL_BEGIN

@interface GoodsAViewModel : NSObject

@property (nonatomic, copy, readonly) NSString *goodsName;

@property (nonatomic, copy, readonly) NSString *goodsDescription;

@property (nonatomic, assign, readonly, getter=isBuyEnable) BOOL buyEnable;

- (instancetype)initWithGoodsModel:(GoodsAModel *)goodsModel;

@end

NS_ASSUME_NONNULL_END
