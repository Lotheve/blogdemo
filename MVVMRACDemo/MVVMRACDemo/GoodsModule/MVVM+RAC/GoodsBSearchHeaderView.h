//
//  GoodsBSearchHeaderView.h
//  MVVMRACDemo
//
//  Created by 卢旭峰 on 2019/2/10.
//  Copyright © 2019 Lotheve. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GoodsBSearchViewModel;

NS_ASSUME_NONNULL_BEGIN

@interface GoodsBSearchHeaderView : UIView

- (instancetype)initWithViewModel:(GoodsBSearchViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
