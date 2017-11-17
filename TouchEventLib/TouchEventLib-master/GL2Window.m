//
//  GL2Window.m
//  TouchEventLib-master
//
//  Created by 卢旭峰 on 2017/8/20.
//  Copyright © 2017年 StockAccount. All rights reserved.
//

#import "GL2Window.h"

@implementation GL2Window

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    NSLog(@"%s %@",__func__,NSStringFromCGRect(self.frame));
    return [super hitTest:point withEvent:event];
}

- (void)sendEvent:(UIEvent *)event
{
    NSLog(@"%s",__func__);
    [super sendEvent:event];
}

@end
