//
//  CLViewController.m
//  TouchEventLib-master
//
//  Created by 卢旭峰 on 2017/8/25.
//  Copyright © 2017年 StockAccount. All rights reserved.
//

#import "CLViewController.h"
#import "LXFButton.h"
#import "BlueView.h"
#import "CLTapGestureRecognizer.h"

@interface CLViewController ()
@property (strong, nonatomic) IBOutlet LXFButton *button;
@property (strong, nonatomic) IBOutlet BlueView *blueView;
@end

@implementation CLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CLTapGestureRecognizer *tap = [[CLTapGestureRecognizer alloc] initWithTarget:self action:@selector(blueViewTap)];
//    [_blueView addGestureRecognizer:tap];
    
    [_button addGestureRecognizer:tap];
    [_button addTarget:self action:@selector(actionButtonTap) forControlEvents:UIControlEventTouchUpInside];
}

- (void)actionButtonTap
{
    NSLog(@"按钮点击");
}

- (void)blueViewTap
{
    NSLog(@"手势触发");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
