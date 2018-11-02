//
//  Animal.h
//  DeallocExporeDemo
//
//  Created by 卢旭峰 on 2018/11/1.
//  Copyright © 2018 Lotheve. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Skill.h"

NS_ASSUME_NONNULL_BEGIN

@interface Animal : NSObject

@property (nonatomic, strong) Skill *skill;

@end

NS_ASSUME_NONNULL_END
