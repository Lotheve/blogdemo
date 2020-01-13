//
//  AppDelegate.m
//  MVVMRACDemo
//
//  Created by 卢旭峰 on 2019/2/10.
//  Copyright © 2019 Lotheve. All rights reserved.
//

#import "AppDelegate.h"
#import "HomeViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _window.backgroundColor = [UIColor whiteColor];
    HomeViewController *homeVC = [[HomeViewController alloc] init];
    UINavigationController *navc = [[UINavigationController alloc] initWithRootViewController:homeVC];
    navc.navigationBar.translucent = NO;
    navc.navigationBar.barTintColor = [UIColor orangeColor];
    _window.rootViewController = navc;
    [_window makeKeyAndVisible];
    
    return YES;
}

@end
