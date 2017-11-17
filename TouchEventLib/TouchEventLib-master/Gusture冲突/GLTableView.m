//
//  GLTableView.m
//  TouchEventLib-master
//
//  Created by 卢旭峰 on 2017/8/16.
//  Copyright © 2017年 StockAccount. All rights reserved.
//

#import "GLTableView.h"

@implementation GLTableView

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
//    NSLog(@"%s",__func__);
//    NSLog(@"%s调用时间戳 :\n%.2fms",__func__,CFAbsoluteTimeGetCurrent()*1000);
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s",__func__);
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s",__func__);
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s",__func__);
    [super touchesCancelled:touches withEvent:event];
}

@end
