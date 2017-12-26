//
//  ViewController.m
//  ESCOpenGLStudy
//
//  Created by g on 2017/12/13.
//  Copyright © 2017年 xiang. All rights reserved.
//

#import "ViewController.h"
#import "ESCOpenGLView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];


    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;

    CGFloat viewW = 10;
    CGFloat viewH = 10;
    for (int i = 0; i < width; i+= viewW) {
        for (int j = 0; j < height; j+= viewH) {
            dispatch_async(dispatch_get_main_queue(), ^{
                CGRect frame = CGRectMake(i, j, viewW, viewH);
                ESCOpenGLView *openGLView1 = [[ESCOpenGLView alloc] initWithFrame:frame];
                [self.view addSubview:openGLView1];
            });
        }
    }
}


@end
