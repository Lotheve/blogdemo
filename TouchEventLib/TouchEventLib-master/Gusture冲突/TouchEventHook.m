//
//  TouchEventHook.m
//  TouchEventLib-master
//
//  Created by 卢旭峰 on 2017/8/21.
//  Copyright © 2017年 StockAccount. All rights reserved.
//

#import "TouchEventHook.h"
#import <objc/runtime.h>

@implementation TouchEventHook

+ (void)load
{
    Class aClass = objc_getClass("UIScrollViewDelayedTouchesBeganGestureRecognizer");
    SEL sel = @selector(hook_sendTouchesShouldBeginForDelayedTouches:);
    Method method = class_getClassMethod([self class], sel);
    class_addMethod(aClass, sel, class_getMethodImplementation([self class], sel), method_getTypeEncoding(method));
    // 交换实现
    exchangeMethod(aClass, @selector(sendTouchesShouldBeginForDelayedTouches:), sel);
}

- (void)hook_sendTouchesShouldBeginForDelayedTouches:(id)arg1
{
//    NSLog(@"%s调用时间戳 :\n%.2fms",__func__,CFAbsoluteTimeGetCurrent()*1000);
    [self hook_sendTouchesShouldBeginForDelayedTouches:arg1];
}

void exchangeMethod(Class aClass, SEL oldSEL, SEL newSEL) {
    Method oldMethod = class_getInstanceMethod(aClass, oldSEL);
    Method newMethod = class_getInstanceMethod(aClass, newSEL);
    method_exchangeImplementations(oldMethod, newMethod);
}

@end
