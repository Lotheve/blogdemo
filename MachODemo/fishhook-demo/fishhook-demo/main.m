//
//  main.m
//  fishhook-demo
//
//  Created by 卢旭峰 on 2019/11/13.
//  Copyright © 2019 Lotheve. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "fishhook.h"

extern NSString *name;
NSString *myName = @"Lotheve";

void (*ori_Log)(NSString *format, ...);

void LTLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    format = [NSString stringWithFormat:@"🌺%@🌺",format];
    ori_Log(@"%@",[[NSString alloc] initWithFormat:format arguments:args]);
    va_end(args);
}

int main(int argc, const char * argv[]) {
    NSLog(@"%@",name);
    struct rebinding rebind[2] = {{"NSLog", LTLog, (void *)&ori_Log},{"name", &myName, NULL}};
    rebind_symbols(rebind, 2);
    NSLog(@"%@",name);
    return 0;
}


