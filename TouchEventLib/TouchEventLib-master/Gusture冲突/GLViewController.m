//
//  GLViewController.m
//  TouchEventLib-master
//
//  Created by 卢旭峰 on 2017/8/10.
//  Copyright © 2017年 StockAccount. All rights reserved.
//

#import "GLViewController.h"
#import "BackView.h"

@interface GLViewController ()<UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet BackView *backView;
@property (strong, nonatomic) IBOutlet UITableView *tableMain;
@property (strong, nonatomic) IBOutlet UIButton *button;

@end

@implementation GLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    _tableMain.tableFooterView = [UIView new];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionTapView)];
    tap.delegate = self;
    [_backView addGestureRecognizer:tap];
    
//    _tableMain.delaysContentTouches = NO;
    
//    [_button addTarget:self action:@selector(buttonTap) forControlEvents:UIControlEventTouchUpInside];
}

- (void)actionTapView
{
    NSLog(@"backview taped");
}

//- (void)buttonTap {
//    NSLog(@"button clicked!");
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSLog(@"cell selected!");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellID"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CellID"];
    }
    cell.backgroundColor = [UIColor orangeColor];
    cell.textLabel.text = @"点我~";
    return cell;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([gestureRecognizer.view isDescendantOfView:_tableMain]) {
        NSLog(@"NO");
        return NO;
    }
    return YES;
}

@end
