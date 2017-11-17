//
//  GLApplication.m
//  TouchEventLib-master
//
//  Created by 卢旭峰 on 2017/8/20.
//  Copyright © 2017年 StockAccount. All rights reserved.
//

#import "GLApplication.h"

@implementation GLApplication

- (void)sendEvent:(UIEvent *)event
{
    NSLog(@"%s",__func__);
    [super sendEvent:event];
}

@end
