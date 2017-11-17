//
//  MovedView.m
//  TouchEventLib-master
//
//  Created by 卢旭峰 on 2017/8/10.
//  Copyright © 2017年 StockAccount. All rights reserved.
//

#import "MovedView.h"

@implementation MovedView

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s",__func__);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s",__func__);
    
    UITouch *touch = [touches anyObject];
    
    CGPoint prePoint = [touch previousLocationInView:self];
    CGPoint curPoint = [touch locationInView:self];
    
    CGFloat offsetX = curPoint.x - prePoint.x;
    CGFloat offsetY = curPoint.y - prePoint.y;
    
    self.transform = CGAffineTransformTranslate(self.transform, offsetX, offsetY);
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s",__func__);
    

    
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s",__func__);

}

@end
