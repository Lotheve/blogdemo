//
//  GoodsASearchHeaderView.m
//  MVVMRACDemo
//
//  Created by 卢旭峰 on 2019/2/10.
//  Copyright © 2019 Lotheve. All rights reserved.
//

#import "GoodsASearchHeaderView.h"
#import "GoodsASearchViewModel.h"
#import "ValueBox.h"

@interface GoodsASearchHeaderView ()

@property (nonatomic, strong) UITextField *searchTextField;
@property (nonatomic, strong) UIButton *searchBtn;
@property (nonatomic, strong) UIView *seperateLine;

@property (nonatomic, strong) GoodsASearchViewModel *searchViewModel;

@end

@implementation GoodsASearchHeaderView

- (instancetype)initWithViewModel:(GoodsASearchViewModel *)viewModel
{
    self = [super init];
    if (self) {
        _searchViewModel = viewModel;
        [self.searchViewModel addObserver:self forKeyPath:@"searchEnable" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:NULL];
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    [self addSubview:self.searchTextField];
    [self addSubview:self.searchBtn];
    [self addSubview:self.seperateLine];
}

- (void)layoutSubviews
{
    CGRect frame = self.bounds;
    self.searchTextField.frame = CGRectMake(16, 8, CGRectGetWidth(frame)-32-44-8, CGRectGetHeight(frame)-16);
    self.searchBtn.frame = CGRectMake(CGRectGetMaxX(self.searchTextField.frame)+8, 8, 44, CGRectGetHeight(frame)-16);
    self.seperateLine.frame = CGRectMake(0, frame.size.height-0.5, frame.size.width, 0.5);
    [super layoutSubviews];
}

#pragma mark - Event
/// 通过target-action绑定搜索按钮事件
- (void)actionSearch:(UIButton *)sender
{
    [_searchViewModel searchGoods];
}

/// 通过notification绑定搜索框输入事件
- (void)textDidChangeNotification:(NSNotification *)notification
{
    UITextField *tf = (UITextField *)notification.object;
    _searchViewModel.searchKey = tf.text;
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    /// 通过KVO绑定ViewModel中的searchEnable值
    if ([keyPath isEqualToString:@"searchEnable"]) {
        BOOL searchEnable = ((BoolBox *)change[NSKeyValueChangeNewKey]).value;
        self.searchBtn.enabled = searchEnable;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Lazy
- (UITextField *)searchTextField
{
    if (!_searchTextField) {
        _searchTextField = [[UITextField alloc] init];
        _searchTextField.textAlignment = NSTextAlignmentLeft;
        _searchTextField.font = [UIFont systemFontOfSize:16.0f];
        _searchTextField.textColor = [UIColor colorWithRed:32/256.0 green:32/256.0 blue:32/256.0 alpha:1];
        _searchTextField.borderStyle = UITextBorderStyleRoundedRect;
        _searchTextField.placeholder = @"请输入商品关键字";
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChangeNotification:) name:UITextFieldTextDidChangeNotification object:_searchTextField];
    }
    return _searchTextField;
}

- (UIButton *)searchBtn
{
    if (!_searchBtn) {
        _searchBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_searchBtn setTitle:@"搜索" forState:UIControlStateNormal];
        [_searchBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
        [_searchBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        _searchBtn.enabled = NO;
        [_searchBtn addTarget:self action:@selector(actionSearch:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _searchBtn;
}

- (UIView *)seperateLine
{
    if (!_seperateLine) {
        _seperateLine = [[UIView alloc] init];
        _seperateLine.backgroundColor = [UIColor lightGrayColor];
    }
    return _seperateLine;
}

@end
