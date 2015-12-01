//
//  ViewController.m
//  SZCircleViewDemo
//
//  Created by 陈圣治 on 15/8/13.
//  Copyright (c) 2015年 shengzhichen. All rights reserved.
//

#import "ViewController.h"
#import "SZCircleView.h"
#import "UIView+Frame.h"

@interface ViewController () <SZCircleViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    SZCircleView *scrollView = [[SZCircleView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 200)];
    scrollView.circleDelegate = self;
    [self.view addSubview:scrollView];
    [scrollView reloadData];
}

#pragma mark - SZCircleViewDelegate -
- (NSInteger)numberRowInCircleView:(SZCircleView *)circleView  {
    return 3;
}

- (void)circleView:(SZCircleView *)circleView configImageView:(UIImageView *)imageView atRow:(NSInteger)atRow {
    imageView.backgroundColor = [UIColor colorWithWhite:0.3 + 0.2*atRow alpha:1];
}

@end
