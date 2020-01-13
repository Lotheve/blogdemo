//
//  GoodsACell.h
//  MVVMRACDemo
//
//  Created by 卢旭峰 on 2019/2/10.
//  Copyright © 2019 Lotheve. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GoodsAViewModel;

NS_ASSUME_NONNULL_BEGIN

@interface GoodsACell : UITableViewCell

@property (nonatomic, strong) GoodsAViewModel *goodsViewModel;

@end

NS_ASSUME_NONNULL_END
