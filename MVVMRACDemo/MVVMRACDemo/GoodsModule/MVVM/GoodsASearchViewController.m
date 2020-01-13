//
//  GoodsASearchViewController.m
//  MVVMRACDemo
//
//  Created by 卢旭峰 on 2019/2/10.
//  Copyright © 2019 Lotheve. All rights reserved.
//

#import "GoodsASearchViewController.h"
#import "GoodsASearchHeaderView.h"
#import "GoodsACell.h"
#import "GoodsASearchViewModel.h"
#import "ValueBox.h"

@interface GoodsASearchViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *goodsTable;
@property (nonatomic, strong) GoodsASearchHeaderView *searchView;

@property (nonatomic, strong) GoodsASearchViewModel *searchViewModel;

@end

@implementation GoodsASearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"MVVM without RAC";
    
    _searchViewModel = [[GoodsASearchViewModel alloc] init];
    [self.searchViewModel addObserver:self forKeyPath:@"needRefresh" options:NSKeyValueObservingOptionNew context:NULL];
    
    [self.view addSubview:self.searchView];
    [self.view addSubview:self.goodsTable];
}

- (void)viewDidLayoutSubviews
{
    CGFloat naviBarHeight = [UINavigationBar appearance].frame.size.height;
    self.searchView.frame = CGRectMake(0, naviBarHeight, CGRectGetWidth(self.view.bounds), 60);
    self.goodsTable.frame = CGRectMake(0, naviBarHeight+CGRectGetHeight(self.searchView.frame), CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)-CGRectGetMaxY(self.searchView.frame));
    [super viewDidLayoutSubviews];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    /// 通过KVO绑定ViewModel中的needRefresh值
    if ([keyPath isEqualToString:@"needRefresh"]) {
        BOOL needRefresh = ((BoolBox *)change[NSKeyValueChangeNewKey]).value;
        if (needRefresh) {
            [self.goodsTable reloadData];
            self.searchViewModel.needRefresh = BOOL_VALUE(NO);
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - table
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _searchViewModel.goods.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GoodsACell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([GoodsACell class])];
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
        [_goodsTable registerClass:[GoodsACell class] forCellReuseIdentifier:NSStringFromClass([GoodsACell class])];
        _goodsTable.tableFooterView = [UIView new];
    }
    return _goodsTable;
}

- (GoodsASearchHeaderView *)searchView
{
    if (!_searchView) {
        _searchView = [[GoodsASearchHeaderView alloc] initWithViewModel:_searchViewModel];
        _searchView.backgroundColor = [UIColor whiteColor];
    }
    return _searchView;
}

#pragma mark - dealloc
- (void)dealloc
{
    NSLog(@"%s",__func__);
}

@end
