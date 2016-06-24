//
//  ViewController.m
//  SZCircleViewDemo
//
//  Created by 陈圣治 on 15/8/13.
//  Copyright (c) 2015年 shengzhichen. All rights reserved.
//

#import "ViewController.h"
#import "SZCircleView.h"

@interface ViewController () <SZCircleViewDelegate>

@property (nonatomic, strong) SZCircleView *circleView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];

    _circleView = [[SZCircleView alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, 200)];
    _circleView.circleDelegate = self;
    [self.view addSubview:_circleView];
    [_circleView reloadData];

    self.navigationItem.rightBarButtonItems = @[
                                                [[UIBarButtonItem alloc] initWithTitle:@"push"
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:self
                                                                                action:@selector(pushActionHandler)],
                                                [[UIBarButtonItem alloc] initWithTitle:@"relolad    "
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:_circleView
                                                                                action:@selector(reloadData)]
                                                ];
}

- (void)pushActionHandler {
    [self.navigationController pushViewController:[[ViewController alloc] init] animated:YES];
}

#pragma mark - SZCircleViewDelegate -
- (NSInteger)numberRowInCircleView:(SZCircleView *)circleView  {
    return arc4random() % 4;
}

- (void)circleView:(SZCircleView *)circleView configImageView:(UIImageView *)imageView atRow:(NSInteger)atRow {
    imageView.backgroundColor = [UIColor colorWithWhite:0.2 + 0.2*atRow alpha:1];
}

- (void)circleView:(SZCircleView *)circleView tapAtRow:(NSInteger)tapRow {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, @(tapRow));
}

@end
