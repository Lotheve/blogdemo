//
//  CircleButton.m
//  TouchEventLib-master
//
//  Created by 卢旭峰 on 2017/8/14.
//  Copyright © 2017年 StockAccount. All rights reserved.
//

#import "CircleButton.h"

@implementation CircleButton

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.backgroundColor = [UIColor lightGrayColor];
        self.layer.cornerRadius = ceilf(self.bounds.size.width/2.0);
        self.layer.borderColor = [UIColor purpleColor].CGColor;
        self.layer.borderWidth = 2.0;
    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s",__func__);
//    [[[UIAlertView alloc] initWithTitle:@"CircleButton:" message:@"你成功点了我" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
//    [self printResponderChain];
    [super touchesBegan:touches withEvent:event];
}

- (void)printResponderChain
{
    UIResponder *responder = self;
    printf("%s",[NSStringFromClass([responder class]) UTF8String]);
    while (responder.nextResponder) {
        responder = responder.nextResponder;
        printf(" --> %s",[NSStringFromClass([responder class]) UTF8String]);
    }
}

@end
