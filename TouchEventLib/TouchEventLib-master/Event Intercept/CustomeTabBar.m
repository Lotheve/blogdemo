//
//  CustomeTabBar.m
//  TouchEventLib-master
//
//  Created by 卢旭峰 on 2017/8/14.
//  Copyright © 2017年 StockAccount. All rights reserved.
//

#import "CustomeTabBar.h"
#import "CircleButton.h"

@interface CustomeTabBar ()
{
    CircleButton *_CircleButton;
}

@end

@implementation CustomeTabBar

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        for (id subView in self.subviews) {
            if ([subView isKindOfClass:[CircleButton class]]) {
                _CircleButton = subView;
                break;
            }
        }
    }
    return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    //将触摸点坐标转换到在CircleButton上的坐标
    CGPoint pointTemp = [self convertPoint:point toView:_CircleButton];
    //若触摸点在CricleButton上则返回YES
    if ([_CircleButton pointInside:pointTemp withEvent:event]) {
        return YES;
    }
    //否则返回默认的操作
    return [super pointInside:point withEvent:event];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s",__func__);
    [super touchesBegan:touches withEvent:event];
}

@end
