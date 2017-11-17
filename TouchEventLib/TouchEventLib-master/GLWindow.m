//
//  GLWindow.m
//  TouchEventLib-master
//
//  Created by 卢旭峰 on 2017/8/20.
//  Copyright © 2017年 StockAccount. All rights reserved.
//

#import "GLWindow.h"

@implementation GLWindow

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
//    NSLog(@"%s",__func__);
    return [super hitTest:point withEvent:event];
}

- (void)sendEvent:(UIEvent *)event
{
//    NSLog(@"%s调用时间戳 :\n%.2fms",__func__,CFAbsoluteTimeGetCurrent()*1000);
    [super sendEvent:event];
}

@end
