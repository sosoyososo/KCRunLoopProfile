//
//  ViewController.m
//  RunloopProfile-example
//
//  Created by karsa on 2018/7/2.
//  Copyright © 2018年 karsa. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(100, 100, 100, 100);
    btn.backgroundColor = [UIColor redColor];
    [self.view addSubview:btn];
    [btn  addTarget:self action:@selector(testAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)testAction:(id)sender {
    for (int i = 0; i < 10000; i ++) {
        UIView *view = [[UIView alloc]  init];
        [self.view addSubview:view];
        [view removeFromSuperview];
    }
}


@end
