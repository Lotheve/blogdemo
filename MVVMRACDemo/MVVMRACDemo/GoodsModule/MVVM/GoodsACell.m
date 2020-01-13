//
//  GoodsACell.m
//  MVVMRACDemo
//
//  Created by 卢旭峰 on 2019/2/10.
//  Copyright © 2019 Lotheve. All rights reserved.
//

#import "GoodsACell.h"
#import "GoodsAViewModel.h"

@interface GoodsACell()

@property (nonatomic, strong) UILabel *nameLabel;

@property (nonatomic, strong) UILabel *desLabel;

@end

@implementation GoodsACell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    [self.contentView addSubview:self.nameLabel];
    [self.contentView addSubview:self.desLabel];
}

- (void)layoutSubviews
{
    CGSize size = self.frame.size;
    self.nameLabel.frame = CGRectMake(16, 8, 80, size.height-16);
    self.desLabel.frame = CGRectMake(CGRectGetMaxX(self.nameLabel.frame)+12, 8, size.width-CGRectGetMaxX(self.nameLabel.frame)-12-16, size.height-16);
    [super layoutSubviews];
}

- (void)setGoodsViewModel:(GoodsAViewModel *)goodsViewModel
{
    _goodsViewModel = goodsViewModel;
    _nameLabel.text = goodsViewModel.goodsName;
    _desLabel.text = goodsViewModel.goodsDescription;
    self.contentView.backgroundColor = goodsViewModel.buyEnable ? [UIColor whiteColor] : [UIColor colorWithRed:0xdd/256.0 green:0xdd/256.0 blue:0xdd/256.0 alpha:1];
}

#pragma mark - Lazy
- (UILabel *)nameLabel
{
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.numberOfLines = 1;
        _nameLabel.textAlignment = NSTextAlignmentLeft;
        _nameLabel.font = [UIFont systemFontOfSize:16.0f];
        _nameLabel.textColor = [UIColor orangeColor];
    }
    return _nameLabel;
}

- (UILabel *)desLabel
{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc] init];
        _desLabel.numberOfLines = 0;
        _desLabel.textAlignment = NSTextAlignmentLeft;
        _desLabel.font = [UIFont systemFontOfSize:14.0f];
        _desLabel.textColor = [UIColor lightGrayColor];
    }
    return _desLabel;
}

@end
