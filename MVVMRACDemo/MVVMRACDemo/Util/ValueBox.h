//
//  ValueBox.h
//  MVVMRACDemo
//
//  Created by 卢旭峰 on 2019/2/10.
//  Copyright © 2019 Lotheve. All rights reserved.
//

#import <Foundation/Foundation.h>

#define BOOL_VALUE(value) [BoolBox valueWithBool:value]
@interface BoolBox : NSObject
@property (nonatomic, assign) BOOL value;
+ (instancetype)valueWithBool:(BOOL)value;
@end
