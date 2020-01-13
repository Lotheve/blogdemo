//
//  HomeViewController.m
//  MVVMRACDemo
//
//  Created by 卢旭峰 on 2019/2/10.
//  Copyright © 2019 Lotheve. All rights reserved.
//

#import "HomeViewController.h"
#import "GoodsASearchViewController.h"
#import "GoodsBSearchViewController.h"

@interface HomeViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableMain;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"MVVM&RAC";
    [self.view addSubview:self.tableMain];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.tableMain.frame = self.view.bounds;
}

- (NSArray<NSString *> *)items
{
    return @[@"MVVM without RAC", @"MVVM with RAC"];
}

- (NSArray<Class> *)vcs
{
    return @[[GoodsASearchViewController class], [GoodsBSearchViewController class]];
}

#pragma mark - table
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self items].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([UITableViewCell class])];
    cell.textLabel.text = [self items][indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Class class = [self vcs][indexPath.row];
    UIViewController *vc = (UIViewController *)[[class alloc] init];
    [self.navigationController showViewController:vc sender:nil];
}

#pragma mark - Lazy
- (UITableView *)tableMain
{
    if (!_tableMain) {
        _tableMain = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableMain.backgroundColor = [UIColor whiteColor];
        _tableMain.delegate = self;
        _tableMain.dataSource = self;
        _tableMain.rowHeight = 60;
        [_tableMain registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass([UITableViewCell class])];
        _tableMain.tableFooterView = [UIView new];
    }
    return _tableMain;
}

@end
