//
//  main.m
//  TouchEventLib-master
//
//  Created by 卢旭峰 on 2017/8/10.
//  Copyright © 2017年 StockAccount. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "GLApplication.h"

int main(int argc, char * argv[]) {
    @autoreleasepool {
        
        NSString *app = nil;
//        NSString *app = NSStringFromClass([GLApplication class]);
        return UIApplicationMain(argc, argv, app, NSStringFromClass([AppDelegate class]));
    }
}
