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

    ESCOpenGLView *openGLView = [[ESCOpenGLView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:openGLView];

}


@end
