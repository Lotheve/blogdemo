//
//  ValueBox.m
//  MVVMRACDemo
//
//  Created by 卢旭峰 on 2019/2/10.
//  Copyright © 2019 Lotheve. All rights reserved.
//

#import "ValueBox.h"

@implementation BoolBox

+ (instancetype)valueWithBool:(BOOL)value
{
    BoolBox *v = [[self alloc] init];
    if (v) {
        v.value = value;
    }
    return v;
}
@end
