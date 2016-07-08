//
//  SZCircleView.m
//  SZCircleView
//
//  Created by 陈圣治 on 15/8/13.
//  Copyright (c) 2015年 shengzhichen. All rights reserved.
//

#import "SZCircleView.h"

#define DEBUG_RELEASE 0

typedef NS_ENUM(NSInteger, SZCircleViewDirection) {
    SZCircleViewDirectionNone,
    SZCircleViewDirectionToShowLeft,
    SZCircleViewDirectionToShowRight,
};


#pragma mark - SZCircleViewImageView -
@interface SZCircleViewImageView : UIImageView

@property (nonatomic) NSInteger index;

@end

@implementation SZCircleViewImageView

- (void)dealloc {
#if DEBUG_RELEASE
    NSLog((@" %d %s"), __LINE__, __PRETTY_FUNCTION__);
#endif
}

@end


#pragma mark - SZCircleViewTimerTarget -
@interface SZCircleViewTimerDelegate : NSObject

@property (nonatomic, copy) void (^timerHandler)(NSTimer *timer);


- (instancetype)initWithTimerHandler:(void (^)(NSTimer *timer))timerHandler;

- (void)timerActionHandler:(NSTimer *)timer;

@end

@implementation SZCircleViewTimerDelegate

- (instancetype)initWithTimerHandler:(void (^)(NSTimer *timer))timerHandler {
    if (self = [super init]) {
        self.timerHandler = timerHandler;
    }
    return self;
}

- (void)timerActionHandler:(NSTimer *)timer {
    if (_timerHandler) {
        _timerHandler(timer);
    }
}

- (void)dealloc {
#if DEBUG_RELEASE
    NSLog((@" %d %s"), __LINE__, __PRETTY_FUNCTION__);
#endif
}

@end


#pragma mark - SZCircleView -
@interface SZCircleView () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic) NSInteger rowCount;

@property (nonatomic, strong) NSMutableArray<SZCircleViewImageView *> *visiableImageViewArray;
@property (nonatomic, strong) NSMutableArray<SZCircleViewImageView *> *dequeueImageViewArray;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic) NSInteger currentIndex;

@property (nonatomic) SZCircleViewDirection direction;

@property (nonatomic) CGPoint lastOffset;

@property (nonatomic, strong) UITapGestureRecognizer *tapGesutre;

@end

@implementation SZCircleView

#pragma mark - 生命周期 -
- (void)setup {
    _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    [self addSubview:_scrollView];
    _scrollView.delegate = self;
    _scrollView.pagingEnabled = YES;
    _scrollView.scrollsToTop = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;

    _pageControl = [[UIPageControl alloc] init];
    [self addSubview:_pageControl];

    _autoScrollInterval = 5;
    
    _visiableImageViewArray = [NSMutableArray array];
    _dequeueImageViewArray = [NSMutableArray array];
    
    _tapGesutre = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandle:)];
    [self addGestureRecognizer:_tapGesutre];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [self setup];
}

- (void)dealloc {
#if DEBUG_RELEASE
    NSLog((@" %d %s"), __LINE__, __PRETTY_FUNCTION__);
#endif
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)layoutSubviews {
    _scrollView.frame = self.bounds;

    [self layoutPageControl];

    [self layoutImageViews];
}

#pragma mark - 方法重载 -
- (void)setCurrentIndex:(NSInteger)currentIndex {
    if (_currentIndex != currentIndex) {
        _currentIndex = currentIndex;
        _pageControl.currentPage = currentIndex;
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    if (newWindow) {
        [self resetTimer];
    } else {
        if (_timer && _timer.isValid) {
            [_timer invalidate];
            _timer = nil;
        }
    }
}

#pragma mark - 外部方法 -
- (void)reloadData {
    [self resetTimer];
    
    if (_circleDelegate && [_circleDelegate respondsToSelector:@selector(numberRowInCircleView:)]) {
        _rowCount = MAX(0, [_circleDelegate numberRowInCircleView:self]);
    }

    if (_rowCount <= 1) {
        [_timer invalidate];
        _timer = nil;
    }

    [self layoutPageControl];
    
    [self layoutImageViews];
}

#pragma mark - 内部方法 -
- (void)resetTimer {
    if (_timer) {
        [_timer invalidate];
    }

    __weak typeof(self) weakSelf = self;
    SZCircleViewTimerDelegate *timerDelegate = [[SZCircleViewTimerDelegate alloc] initWithTimerHandler:^(NSTimer *timer) {
        [weakSelf autoScrollForTimer:timer];
    }];

    _timer = [NSTimer timerWithTimeInterval:_autoScrollInterval target:timerDelegate selector:@selector(timerActionHandler:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)autoScrollForTimer:(NSTimer *)timer {
    if (timer != _timer) {
        [timer invalidate];
        return;
    }
    
    _currentIndex++;
    CGPoint offset = _scrollView.contentOffset;
    offset.x = _currentIndex * self.frame.size.width;
    [_scrollView setContentOffset:offset animated:YES];
}

- (void)layoutPageControl {
    _pageControl.numberOfPages = _rowCount;

    CGPoint pageControlOrigin = CGPointZero;
    if (_circleDelegate && [_circleDelegate respondsToSelector:@selector(circleView:pageControlOriginWithSize:)]) {
        pageControlOrigin = [_circleDelegate circleView:self pageControlOriginWithSize:_pageControl.frame.size];
    } else {
        pageControlOrigin = CGPointMake(self.frame.size.width/2 - _pageControl.frame.size.width/2, self.frame.size.height-_pageControl.frame.size.height);
    }
    CGRect frame = _pageControl.frame;
    frame.size = [_pageControl sizeForNumberOfPages:_rowCount];
    frame.origin = pageControlOrigin;
    _pageControl.frame = frame;
}

- (void)layoutImageViews {
    if (self.rowCount == 0) {
        [self.visiableImageViewArray enumerateObjectsUsingBlock:^(SZCircleViewImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
        }];
        [self.dequeueImageViewArray addObjectsFromArray:self.visiableImageViewArray];
        [self.visiableImageViewArray removeAllObjects];
        return;
    }

    if (_currentIndex >= _rowCount) {
        _currentIndex = _rowCount - 1;
    }
    
    _scrollView.contentOffset = CGPointMake(self.frame.size.width * _currentIndex, 0);
    _scrollView.contentSize = CGSizeMake(_rowCount * self.frame.size.width, self.frame.size.height);
    _scrollView.contentInset = UIEdgeInsetsZero;
    
    [self.visiableImageViewArray enumerateObjectsUsingBlock:^(SZCircleViewImageView *obj, NSUInteger idx, BOOL *stop) {
        obj.index = [self datasourceIndexWithIndex:obj.index];
        if (obj.index != self.currentIndex) {
            [obj removeFromSuperview];
            [self.dequeueImageViewArray addObject:obj];
        }
    }];
    
    SZCircleViewImageView *visiableImageView = [self imageViewWithIndex:_currentIndex];
    if (!visiableImageView) {
        visiableImageView = [self dequeueImageViewForIndex:_currentIndex];
        visiableImageView.index = _currentIndex;
    } else {
        if (_circleDelegate && [_circleDelegate respondsToSelector:@selector(circleView:configImageView:atRow:)]) {
            [_circleDelegate circleView:self configImageView:visiableImageView atRow:_currentIndex];
        }
    }
    CGRect imageViewFrame = visiableImageView.frame;
    imageViewFrame.origin.x = _currentIndex * self.frame.size.width;
    visiableImageView.frame = imageViewFrame;
    visiableImageView.index = _currentIndex;
}

- (void)cleanInvisiableViews {
    CGRect visiableRect = CGRectMake(_scrollView.contentOffset.x, 0, self.frame.size.width, self.frame.size.height);
    [self.visiableImageViewArray enumerateObjectsUsingBlock:^(SZCircleViewImageView *obj, NSUInteger idx, BOOL *stop) {
        if (!CGRectIntersectsRect(visiableRect, obj.frame)) {
            [obj removeFromSuperview];
            [self.dequeueImageViewArray addObject:obj];
        }
    }];
    [self.visiableImageViewArray removeObjectsInArray:self.dequeueImageViewArray];
    if (self.dequeueImageViewArray.count > 2) {
        [self.dequeueImageViewArray removeObjectsInRange:NSMakeRange(2, self.dequeueImageViewArray.count - 2)];
    }
}

- (SZCircleViewImageView *)dequeueImageViewForIndex:(NSInteger)index {
    
    SZCircleViewImageView *imageView = [self.dequeueImageViewArray lastObject];
    if (!imageView) {
        imageView = [[SZCircleViewImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    } else {
        [self.dequeueImageViewArray removeLastObject];
    }
    [_scrollView insertSubview:imageView atIndex:0];
    
    if (_circleDelegate && [_circleDelegate respondsToSelector:@selector(circleView:configImageView:atRow:)]) {
        [_circleDelegate circleView:self configImageView:imageView atRow:index];
    }
    
    [_visiableImageViewArray addObject:imageView];
    return imageView;
}

- (NSInteger)datasourceIndexWithIndex:(NSInteger)index {
    NSInteger dataCount = _rowCount;
    if (dataCount == 0) {
        return 0;
    }
    if (index >= 0) {
        index = index % dataCount;
    }
    if (index < 0) {
        index = (labs(index) % dataCount);
        if (index > 0) {
            index = dataCount - index;
        }
    }
    return index;
}

- (SZCircleViewImageView *)imageViewWithIndex:(NSInteger)index {
    for (SZCircleViewImageView *iv in self.visiableImageViewArray) {
        if (iv.index == index) {
            return iv;
        }
    }
    return nil;
}

- (void)tapHandle:(UITapGestureRecognizer *)tapGesture {
    CGPoint point = [tapGesture locationInView:self.scrollView];
    for (SZCircleViewImageView *iv in self.visiableImageViewArray) {
        if (CGRectContainsPoint(iv.frame, point)) {
            NSInteger datasourceIndex = [self datasourceIndexWithIndex:iv.index];
            if (_circleDelegate && [_circleDelegate respondsToSelector:@selector(circleView:tapAtRow:)]) {
                [_circleDelegate circleView:self tapAtRow:datasourceIndex];
            }
            return;
        }
    }
}

#pragma mark - UIScrollViewDelegate -
- (SZCircleViewImageView *)layoutImageViewForTargetIndex:(NSInteger)targetIndex {
    SZCircleViewImageView *iv = [self imageViewWithIndex:targetIndex];
    NSInteger datasourceIndex = [self datasourceIndexWithIndex:targetIndex];
    if (!iv) {
        iv = [self dequeueImageViewForIndex:datasourceIndex];
        iv.index = targetIndex;
    }

    if (_circleDelegate && [_circleDelegate respondsToSelector:@selector(circleView:configImageView:atRow:)]) {
        [_circleDelegate circleView:self configImageView:iv atRow:datasourceIndex];
    }

    CGRect ivFrame = iv.frame;
    ivFrame.origin.x = targetIndex * self.frame.size.width;
    ivFrame.origin.y = 0;
    ivFrame.size = _scrollView.frame.size;
    iv.frame = ivFrame;

    return iv;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self cleanInvisiableViews];

    if (self.rowCount == 0) {
        return;
    }

    if (!CGPointEqualToPoint(CGPointZero, _lastOffset)) {
        CGFloat xOffset = scrollView.contentOffset.x - _lastOffset.x;
        if (xOffset > 0) {
            self.direction = SZCircleViewDirectionToShowRight;
        } else {
            self.direction = SZCircleViewDirectionToShowLeft;
        }
    } else {
        self.direction = SZCircleViewDirectionNone;
    }
    
    if (self.direction == SZCircleViewDirectionToShowRight) {
        NSInteger targetIndex = (scrollView.contentOffset.x / self.frame.size.width) + 1;
        SZCircleViewImageView *iv = [self layoutImageViewForTargetIndex:targetIndex];

        if (_scrollView.contentSize.width + _scrollView.contentInset.right < CGRectGetMaxX(iv.frame)) {
            UIEdgeInsets newInset = _scrollView.contentInset;
            newInset.right = CGRectGetMaxX(iv.frame) - _scrollView.contentSize.width;
            _scrollView.contentInset = newInset;
        }
    } else if (self.direction == SZCircleViewDirectionToShowLeft) {
        NSInteger targetIndex = scrollView.contentOffset.x / self.frame.size.width;
        if (scrollView.contentOffset.x < 0) {
            targetIndex--;
        }
        SZCircleViewImageView *iv = [self layoutImageViewForTargetIndex:targetIndex];

        if (iv.frame.origin.x < 0 && _scrollView.contentInset.left < -iv.frame.origin.x) {
            UIEdgeInsets newInset = _scrollView.contentInset;
            newInset.left = -iv.frame.origin.x;
            _scrollView.contentInset = newInset;
        }
    }    
    
    _lastOffset = scrollView.contentOffset;
    NSInteger newIndex = (NSInteger)round(scrollView.contentOffset.x / scrollView.frame.size.width) % self.rowCount;
    while (newIndex < 0) {
        newIndex += self.rowCount;
    }
    self.currentIndex = newIndex;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [_timer invalidate];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self resetTimer];
        [self layoutImageViews];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self resetTimer];
    [self layoutImageViews];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self layoutImageViews];
}

@end
