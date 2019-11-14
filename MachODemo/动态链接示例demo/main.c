//
//  main.c
//  aaa
//
//  Created by 卢旭峰 on 2019/11/8.
//  Copyright © 2019 Lotheve. All rights reserved.
//

#include <stdio.h>
extern int global_var;
void print(int num);

static int incre = 2;
int add(int num) {
    num+=incre;
    return num;
}

int main() {
    int added = add(global_var);
    print(added);
    return 0;
}
