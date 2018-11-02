//
//  Dog.m
//  DeallocExporeDemo
//
//  Created by 卢旭峰 on 2018/11/1.
//  Copyright © 2018 Lotheve. All rights reserved.
//

#import "Dog.h"

@implementation Dog

- (void)dealloc
{
    NSLog(@"%s",__func__);
}

@end
