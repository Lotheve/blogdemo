//
//  GoodsBSearchViewController.m
//  MVVMRACDemo
//
//  Created by 卢旭峰 on 2019/2/10.
//  Copyright © 2019 Lotheve. All rights reserved.
//

#import "GoodsBSearchViewController.h"
#import "GoodsBSearchHeaderView.h"
#import "GoodsBCell.h"
#import "GoodsBSearchViewModel.h"
#import <ReactiveObjC.h>

@interface GoodsBSearchViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *goodsTable;
@property (nonatomic, strong) GoodsBSearchHeaderView *searchView;

@property (nonatomic, strong) GoodsBSearchViewModel *searchViewModel;

@property (nonatomic, strong) UIActivityIndicatorView *indicator;

@end

@implementation GoodsBSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"MVVM with RAC";
    
    _searchViewModel = [[GoodsBSearchViewModel alloc] init];
//    [self.searchViewModel addObserver:self forKeyPath:@"needRefresh" options:NSKeyValueObservingOptionNew context:NULL];
    
    [self.view addSubview:self.searchView];
    [self.view addSubview:self.goodsTable];
    [self.view addSubview:self.indicator];
    
    [self bindData];
}

- (void)bindData
{
    @weakify(self);
    // 绑定SearchViewModel的needRefresh 当需要刷新是执行刷新
//    [[RACObserve(self, searchViewModel.needRefresh) filter:^BOOL(NSNumber * _Nullable value) {
//        return value.boolValue;
//    }] subscribeNext:^(id  _Nullable x) {
//        @strongify(self);
//        [self.goodsTable reloadData];
//        self.searchViewModel.needRefresh = NO;
//    }];
    
    // 搜索商品列表完成时刷新表格
    [[_searchViewModel.searchCommand.executionSignals switchToLatest] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self.goodsTable reloadData];
    }];
    // 搜索时展示小菊花
    [[_searchViewModel.searchCommand.executing skip:1] subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        if (x.boolValue) {
            [self.indicator startAnimating];
        } else {
            [self.indicator stopAnimating];
        }
    }];
}

- (void)viewDidLayoutSubviews
{
    CGFloat naviBarHeight = [UINavigationBar appearance].frame.size.height;
    self.searchView.frame = CGRectMake(0, naviBarHeight, CGRectGetWidth(self.view.bounds), 60);
    self.goodsTable.frame = CGRectMake(0, naviBarHeight+CGRectGetHeight(self.searchView.frame), CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)-CGRectGetMaxY(self.searchView.frame));
    self.indicator.center = self.view.center;
    [super viewDidLayoutSubviews];
}

#pragma mark - KVO
//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
//{
//    /// 通过KVO绑定ViewModel中的needRefresh值
//    if ([keyPath isEqualToString:@"needRefresh"]) {
//        BOOL needRefresh = ((BoolBox *)change[NSKeyValueChangeNewKey]).value;
//        if (needRefresh) {
//            [self.goodsTable reloadData];
//            self.searchViewModel.needRefresh = BOOL_VALUE(NO);
//        }
//    } else {
//        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
//    }
//}

#pragma mark - table
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _searchViewModel.goods.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GoodsBCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([GoodsBCell class])];
    cell.goodsViewModel = _searchViewModel.goods[indexPath.row];
    return cell;
}

#pragma mark - Lazy
- (UITableView *)goodsTable
{
    if (!_goodsTable) {
        _goodsTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _goodsTable.backgroundColor = [UIColor whiteColor];
        _goodsTable.delegate = self;
        _goodsTable.dataSource = self;
        _goodsTable.rowHeight = 50;
        [_goodsTable registerClass:[GoodsBCell class] forCellReuseIdentifier:NSStringFromClass([GoodsBCell class])];
        _goodsTable.tableFooterView = [UIView new];
    }
    return _goodsTable;
}

- (GoodsBSearchHeaderView *)searchView
{
    if (!_searchView) {
        _searchView = [[GoodsBSearchHeaderView alloc] initWithViewModel:_searchViewModel];
        _searchView.backgroundColor = [UIColor whiteColor];
    }
    return _searchView;
}

- (UIActivityIndicatorView *)indicator
{
    if (!_indicator) {
        _indicator = [[UIActivityIndicatorView alloc] init];
        _indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    }
    return _indicator;
}

#pragma mark - dealloc
- (void)dealloc
{
    NSLog(@"%s",__func__);
}

@end
