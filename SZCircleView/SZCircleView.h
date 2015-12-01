//
//  SZCircleView.h
//  SZCircleView
//
//  Created by 陈圣治 on 15/8/13.
//  Copyright (c) 2015年 shengzhichen. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SZCircleViewDelegate;

@interface SZCircleView : UIScrollView

@property (nonatomic, weak) id <SZCircleViewDelegate>circleDelegate;

// default 5s
@property (nonatomic) NSTimeInterval autoScrollInterval;

@property (nonatomic, readonly) NSInteger currentIndex;


- (void)reloadData;

@end


@protocol SZCircleViewDelegate <NSObject>

@required

- (NSInteger)numberRowInCircleView:(SZCircleView *)circleView;

- (void)circleView:(SZCircleView *)circleView configImageView:(UIImageView *)imageView atRow:(NSInteger)atRow;

@optional

- (void)circleView:(SZCircleView *)circleView tapAtRow:(NSInteger)tapRow;

- (CGPoint)circleView:(SZCircleView *)circleView pageControlOriginWithSize:(CGSize)pageControlSize;

@end