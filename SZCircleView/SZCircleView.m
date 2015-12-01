//
//  SZCircleView.m
//  SZCircleView
//
//  Created by 陈圣治 on 15/8/13.
//  Copyright (c) 2015年 shengzhichen. All rights reserved.
//

#import "SZCircleView.h"

typedef NS_ENUM(NSInteger, SZCircleViewDirection) {
    SZCircleViewDirectionNone,
    SZCircleViewDirectionToShowLeft,
    SZCircleViewDirectionToShowRight,
};

@interface SZCircleView () <UIScrollViewDelegate>

@property (nonatomic) NSInteger rowCount;

@property (nonatomic, strong) NSMutableArray *visiableImageViewArray;
@property (nonatomic, strong) NSMutableArray *dequeueImageViewArray;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic) NSInteger currentIndex;

@property (nonatomic) SZCircleViewDirection direction;

@property (nonatomic) CGPoint lastOffset;

@property (nonatomic, strong) UIPageControl *pageControl;

@property (nonatomic) CGPoint pageControlOrigin;

@property (nonatomic, strong) UITapGestureRecognizer *tapGesutre;

@end

@implementation SZCircleView

#pragma mark - 什么周期 -
- (void)setup {
    self.delegate = self;
    self.pagingEnabled = YES;
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    
    _autoScrollInterval = 5;
    
    _visiableImageViewArray = [NSMutableArray array];
    _dequeueImageViewArray = [NSMutableArray array];
    
    _tapGesutre = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandle:)];
    [self addGestureRecognizer:_tapGesutre];
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
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
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

#pragma mark - 方法重载 -
- (void)setDelegate:(id<UIScrollViewDelegate>)delegate {
    NSAssert(delegate == self, @"scrollView's delegate should be set to itself");
    [super setDelegate:delegate];
}

- (void)setCurrentIndex:(NSInteger)currentIndex {
    if (_currentIndex != currentIndex) {
        _currentIndex = currentIndex;
        _pageControl.currentPage = currentIndex;
    }
}

#pragma mark - 外部方法 -
- (void)reloadData {
    if (_circleDelegate && [_circleDelegate respondsToSelector:@selector(numberRowInCircleView:)]) {
        _rowCount = [_circleDelegate numberRowInCircleView:self];
    }
    if (_rowCount > 1) {
        if (!_pageControl) {
            _pageControl = [[UIPageControl alloc] init];
            [self addSubview:_pageControl];
        }
        CGRect frame = _pageControl.frame;
        frame.size = [_pageControl sizeForNumberOfPages:_rowCount];
        _pageControl.frame = frame;
        _pageControl.numberOfPages = _rowCount;
    } else {
        [_pageControl removeFromSuperview];
    }
    
    if (_circleDelegate && [_circleDelegate respondsToSelector:@selector(circleView:pageControlOriginWithSize:)]) {
        _pageControlOrigin = [_circleDelegate circleView:self pageControlOriginWithSize:_pageControl.frame.size];
    } else {
        _pageControlOrigin = CGPointMake(self.frame.size.width/2 - _pageControl.frame.size.width/2, self.frame.size.height-_pageControl.frame.size.height-5);
    }
    CGRect frame = _pageControl.frame;
    frame.origin = _pageControlOrigin;
    _pageControl.frame = frame;
    
    [self resetTimer];
    
    [self relayout];
}

#pragma mark - 内部方法 -
- (void)resetTimer {
    if (_timer) {
        [_timer invalidate];
    }
    _timer = nil;
    if (_rowCount > 1) {
        _timer = [NSTimer timerWithTimeInterval:_autoScrollInterval target:self selector:@selector(autoScrollForTimer:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
}

- (void)autoScrollForTimer:(NSTimer *)timer {
    if (timer != _timer) {
        [timer invalidate];
        return;
    }
    
    _currentIndex++;
    CGPoint offset = self.contentOffset;
    offset.x = _currentIndex * self.frame.size.width;
    [self setContentOffset:offset animated:YES];
}

- (void)relayout {
    self.contentOffset = CGPointMake(self.frame.size.width * _currentIndex, 0);
    self.contentSize = CGSizeMake(_rowCount * self.frame.size.width, self.frame.size.height);
    self.contentInset = UIEdgeInsetsZero;
    
    __weak typeof(self) weakSelf = self;
    [self.visiableImageViewArray enumerateObjectsUsingBlock:^(UIImageView *obj, NSUInteger idx, BOOL *stop) {
        obj.tag = [weakSelf datasourceIndexWithTag:obj.tag];
        if (obj.tag != weakSelf.currentIndex) {
            [obj removeFromSuperview];
            [weakSelf.dequeueImageViewArray addObject:obj];
        }
    }];
    
    UIImageView *visiableImageView = [self imageViewWithTag:_currentIndex];
    if (!visiableImageView) {
        visiableImageView = [self dequeueImageViewForIndex:_currentIndex];
        visiableImageView.tag = _currentIndex;
    } else {
        if (_circleDelegate && [_circleDelegate respondsToSelector:@selector(circleView:configImageView:atRow:)]) {
            [_circleDelegate circleView:self configImageView:visiableImageView atRow:_currentIndex];
        }
    }
    CGRect visiableImageViewFrame = visiableImageView.frame;
    visiableImageViewFrame.origin.x = _currentIndex * self.frame.size.width;
    visiableImageView.frame = visiableImageViewFrame;
    visiableImageView.tag = _currentIndex;
    
    [self bringSubviewToFront:_pageControl];
    CGRect pageControlFrame = _pageControl.frame;
    pageControlFrame.origin = CGPointMake(self.contentOffset.x + _pageControlOrigin.x, _pageControlOrigin.y);
    _pageControl.frame = pageControlFrame;
}


- (void)cleanInvisiableViews {
    __weak typeof(self) weakSelf = self;
    CGRect visiableRect = CGRectMake(self.contentOffset.x, 0, self.frame.size.width, self.frame.size.height);
    [self.visiableImageViewArray enumerateObjectsUsingBlock:^(UIImageView *obj, NSUInteger idx, BOOL *stop) {
        if (!CGRectIntersectsRect(visiableRect, obj.frame)) {
            [obj removeFromSuperview];
            [weakSelf.dequeueImageViewArray addObject:obj];
        }
    }];
    [self.visiableImageViewArray removeObjectsInArray:self.dequeueImageViewArray];
    if (self.dequeueImageViewArray.count > 2) {
        [self.dequeueImageViewArray removeObjectsInRange:NSMakeRange(2, self.dequeueImageViewArray.count - 2)];
    }
}

- (UIImageView *)dequeueImageViewForIndex:(NSInteger)index {
    
    UIImageView *imageView = [self.dequeueImageViewArray lastObject];
    if (!imageView) {
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    } else {
        [self.dequeueImageViewArray removeLastObject];
    }
    [self insertSubview:imageView atIndex:0];
    
    if (_circleDelegate && [_circleDelegate respondsToSelector:@selector(circleView:configImageView:atRow:)]) {
        [_circleDelegate circleView:self configImageView:imageView atRow:index];
    }
    
    [_visiableImageViewArray addObject:imageView];
    return imageView;
}

- (NSInteger)datasourceIndexWithTag:(NSInteger)tag {
    NSInteger dataCount = _rowCount;
    if (tag >= 0) {
        tag = tag % dataCount;
    }
    if (tag < 0) {
        tag = (labs(tag) % dataCount);
        if (tag > 0) {
            tag = dataCount - tag;
        }
    }
    return tag;
}

- (UIImageView *)imageViewWithTag:(NSInteger)tag {
    for (UIImageView *iv in self.visiableImageViewArray) {
        if (iv.tag == tag) {
            return iv;
        }
    }
    return nil;
}

- (void)tapHandle:(UITapGestureRecognizer *)tapGesture {
    CGPoint point = [tapGesture locationInView:self];
    for (UIImageView *iv in self.visiableImageViewArray) {
        if (CGRectContainsPoint(iv.frame, point)) {
            NSInteger datasourceIndex = [self datasourceIndexWithTag:iv.tag];
            if (_circleDelegate && [_circleDelegate respondsToSelector:@selector(circleView:tapAtRow:)]) {
                [_circleDelegate circleView:self tapAtRow:datasourceIndex];
            }
            return;
        }
    }
}

#pragma mark - UIScrollViewDelegate -
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self cleanInvisiableViews];
    
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
    
    NSInteger targetTag = 0;
    if (self.direction == SZCircleViewDirectionToShowRight) {
        targetTag = (scrollView.contentOffset.x / self.frame.size.width) + 1;
        UIImageView *iv = (UIImageView *)[self imageViewWithTag:targetTag];
        NSInteger datasourceIndex = [self datasourceIndexWithTag:targetTag];
        if (!iv) {
            iv = [self dequeueImageViewForIndex:datasourceIndex];
            iv.tag = targetTag;
        }
        
        if (_circleDelegate && [_circleDelegate respondsToSelector:@selector(circleView:configImageView:atRow:)]) {
            [_circleDelegate circleView:self configImageView:iv atRow:datasourceIndex];
        }
        
        CGRect ivFrame = iv.frame;
        ivFrame.origin.x = targetTag * self.frame.size.width;
        iv.frame = ivFrame;
        if (self.contentSize.width + self.contentInset.right < CGRectGetMaxX(iv.frame)) {
            UIEdgeInsets newInset = self.contentInset;
            newInset.right = CGRectGetMaxX(iv.frame) - self.contentSize.width;
            self.contentInset = newInset;
        }
    } else if (self.direction == SZCircleViewDirectionToShowLeft) {
        targetTag = scrollView.contentOffset.x / self.frame.size.width;
        if (scrollView.contentOffset.x < 0) {
            targetTag--;
        }
        UIImageView *iv = (UIImageView *)[self imageViewWithTag:targetTag];
        NSInteger datasourceIndex = [self datasourceIndexWithTag:targetTag];
        if (!iv) {
            iv = [self dequeueImageViewForIndex:datasourceIndex];
            
            iv.tag = targetTag;
        }
        
        if (_circleDelegate && [_circleDelegate respondsToSelector:@selector(circleView:configImageView:atRow:)]) {
            [_circleDelegate circleView:self configImageView:iv atRow:datasourceIndex];
        }
        
        CGRect ivFrame = iv.frame;
        ivFrame.origin.x = targetTag * self.frame.size.width;
        iv.frame = ivFrame;
        if (iv.frame.origin.x < 0 && self.contentInset.left < -iv.frame.origin.x) {
            UIEdgeInsets newInset = self.contentInset;
            newInset.left = -iv.frame.origin.x;
            self.contentInset = newInset;
        }
    }    
    
    _lastOffset = scrollView.contentOffset;

    NSInteger newIndex = (NSInteger)round(scrollView.contentOffset.x / scrollView.frame.size.width) % (NSInteger)self.rowCount;
    while (newIndex < 0) {
        newIndex += self.rowCount;
    }
    self.currentIndex = newIndex;
    CGRect pageControlFrame = self.pageControl.frame;
    pageControlFrame.origin.x = self.contentOffset.x + _pageControlOrigin.x;
    self.pageControl.frame = pageControlFrame;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [_timer invalidate];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self resetTimer];
        [self relayout];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self resetTimer];
    [self relayout];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self relayout];
}

@end
