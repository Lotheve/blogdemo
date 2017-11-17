//
//  LXFViewController.m
//  TouchEventLib-master
//
//  Created by 卢旭峰 on 2017/8/23.
//  Copyright © 2017年 StockAccount. All rights reserved.
//

#import "LXFViewController.h"
#import "YellowView.h"
#import "LXFTapGestureRecognizer.h"

@interface LXFViewController ()
@property (strong, nonatomic) IBOutlet YellowView *yellowView;
@end

@implementation LXFViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    LXFTapGestureRecognizer *tap = [[LXFTapGestureRecognizer alloc] initWithTarget:self action:@selector(actionTap)];
//    [self.view addGestureRecognizer:tap];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(actionPan)];
//    pan.cancelsTouchesInView = NO;
//    pan.delaysTouchesBegan = YES;
    pan.delaysTouchesEnded = YES;
    [self.view addGestureRecognizer:pan];
}

- (void)actionTap
{
    NSLog(@"View Taped");
}

- (void)actionPan
{
    NSLog(@"View panned");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
