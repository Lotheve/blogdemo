
//
//  CLTapGestureRecognizer.m
//  TouchEventLib-master
//
//  Created by 卢旭峰 on 2017/8/25.
//  Copyright © 2017年 StockAccount. All rights reserved.
//

#import "CLTapGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation CLTapGestureRecognizer

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s before state: %zi",__func__,self.state);
    [super touchesBegan:touches withEvent:event];
//    NSLog(@"%s later state: %zi",__func__,self.state);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s before state: %zi",__func__,self.state);
    [super touchesMoved:touches withEvent:event];
//    NSLog(@"%s later state: %zi",__func__,self.state);
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s before state: %zi",__func__,self.state);
    [super touchesEnded:touches withEvent:event];
//    NSLog(@"%s later state: %zi",__func__,self.state);
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s before state: %zi",__func__,self.state);
    [super touchesCancelled:touches withEvent:event];
//    NSLog(@"%s later state: %zi",__func__,self.state);
}

@end
