//
//  ViewController.m
//  TouchEventLib-master
//
//  Created by 卢旭峰 on 2017/8/10.
//  Copyright © 2017年 StockAccount. All rights reserved.
//

#import "ViewController.h"
#import "GL2Window.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) IBOutlet UITableView *tableMain;
@property (nonatomic, strong) GL2Window *win;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _tableMain.tableFooterView = [UIView new];
    
    //测试事件从application——>window的window优先级
//    _win = [[GL2Window alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
//    _win.backgroundColor = [UIColor purpleColor];
//    _win.windowLevel = UIWindowLevelAlert + 1;
//    _win.hidden = NO;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellID"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CellID"];
    }
    if (indexPath.row == 0) {
        cell.textLabel.text = @"简单滑动";
    }else if (indexPath.row == 1){
        cell.textLabel.text = @"Hit-Testing";   
    }else if (indexPath.row == 2){
        cell.textLabel.text = @"手势冲突测试";
    }else if (indexPath.row == 3){
        cell.textLabel.text = @"事件拦截";
    }else if (indexPath.row == 4){
        cell.textLabel.text = @"手势 Lib";
    }else if (indexPath.row == 5){
        cell.textLabel.text = @"UIControl Lib";
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == 0) {
        [self performSegueWithIdentifier:@"PushToTestMovedVC" sender:nil];
    }else if (indexPath.row == 1){
        [self performSegueWithIdentifier:@"PushToHitTestVC" sender:nil];
    }else if (indexPath.row == 2){
        [self performSegueWithIdentifier:@"PushToGustureLib" sender:nil];
    }else if (indexPath.row == 3){
        [self performSegueWithIdentifier:@"PushToEventIntercept" sender:nil];
    }else if (indexPath.row == 4){
        [self performSegueWithIdentifier:@"PushToGesture" sender:nil];
    }else if (indexPath.row == 5){
        [self performSegueWithIdentifier:@"PushToUIControlLib" sender:nil];
    }
}

@end
