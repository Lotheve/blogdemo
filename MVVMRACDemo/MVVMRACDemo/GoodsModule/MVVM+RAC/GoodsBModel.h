//
//  GoodsBModel.h
//  MVVMRACDemo
//
//  Created by 卢旭峰 on 2019/2/10.
//  Copyright © 2019 Lotheve. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GoodsBModel : NSObject

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *des;

@property (nonatomic, assign) NSUInteger stockCount;

@end

NS_ASSUME_NONNULL_END
