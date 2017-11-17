//
//  LXFButton.m
//  TouchEventLib-master
//
//  Created by 卢旭峰 on 2017/8/25.
//  Copyright © 2017年 StockAccount. All rights reserved.
//

#import "LXFButton.h"

@implementation LXFButton

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    NSLog(@"%s before %zi",__func__,touch.phase);
    BOOL result = [super beginTrackingWithTouch:touch withEvent:event];
//    NSLog(@"%s later %zi",__func__,touch.phase);
    return result;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    NSLog(@"%s before %zi",__func__,touch.phase);
    BOOL result = [super continueTrackingWithTouch:touch withEvent:event];
//    NSLog(@"%s later %zi",__func__,touch.phase);
    return result;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    NSLog(@"%s before %zi",__func__,touch.phase);
    [super endTrackingWithTouch:touch withEvent:event];
//    NSLog(@"%s later %zi",__func__,touch.phase);
}

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
    NSLog(@"%s before %zi",__func__,event.allTouches.anyObject.phase);

    [super cancelTrackingWithEvent:event];
//    NSLog(@"%s later %zi",__func__,event.allTouches.anyObject.phase);
}



- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s before %zi",__func__,event.allTouches.anyObject.phase);
    [super touchesBegan:touches withEvent:event];
//    NSLog(@"%s later %zi",__func__,event.allTouches.anyObject.phase);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s before %zi",__func__,event.allTouches.anyObject.phase);
    [super touchesMoved:touches withEvent:event];
//    NSLog(@"%s later %zi",__func__,event.allTouches.anyObject.phase);
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s before %zi",__func__,event.allTouches.anyObject.phase);
    [super touchesEnded:touches withEvent:event];
//    NSLog(@"%s later %zi",__func__,event.allTouches.anyObject.phase);
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s before %zi",__func__,event.allTouches.anyObject.phase);
    [super touchesCancelled:touches withEvent:event];
//    NSLog(@"%s later %zi",__func__,event.allTouches.anyObject.phase);
}

@end
