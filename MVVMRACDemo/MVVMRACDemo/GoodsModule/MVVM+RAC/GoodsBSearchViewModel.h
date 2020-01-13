//
//  GoodsBSearchViewModel.h
//  MVVMRACDemo
//
//  Created by 卢旭峰 on 2019/2/10.
//  Copyright © 2019 Lotheve. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveObjC.h>
@class GoodsBViewModel;

NS_ASSUME_NONNULL_BEGIN

@interface GoodsBSearchViewModel : NSObject

@property (nonatomic, copy) NSString *searchKey;

//@property (nonatomic, assign, readonly, getter=isSearchEnable) BOOL searchEnable;

//@property (nonatomic, assign, getter=isNeedRefresh) BOOL needRefresh;

@property (nonatomic, copy, readonly) NSArray<GoodsBViewModel *> *goods;

@property (nonatomic, strong, readonly) RACCommand *searchCommand;

//- (void)searchGoods;

@end

NS_ASSUME_NONNULL_END
