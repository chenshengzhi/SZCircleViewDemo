//
//  SZCircleView.m
//  SZCircleView
//
//  Created by 陈圣治 on 15/8/13.
//  Copyright (c) 2015年 shengzhichen. All rights reserved.
//

#import "SZCircleView.h"
#import "UIView+SZFrameHelper.h"

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

#pragma mark - 生命周期 -
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
    [self resetTimer];
    
    if (_circleDelegate && [_circleDelegate respondsToSelector:@selector(numberRowInCircleView:)]) {
        _rowCount = [_circleDelegate numberRowInCircleView:self];
    }
    if (_rowCount > 1) {
        if (!_pageControl) {
            _pageControl = [[UIPageControl alloc] init];
            [self addSubview:_pageControl];
        }
        _pageControl.size = [_pageControl sizeForNumberOfPages:_rowCount];
        _pageControl.numberOfPages = _rowCount;
    } else {
        [_pageControl removeFromSuperview];
    }
    
    if (_circleDelegate && [_circleDelegate respondsToSelector:@selector(circleView:pageControlOriginWithSize:)]) {
        _pageControlOrigin = [_circleDelegate circleView:self pageControlOriginWithSize:_pageControl.size];
    } else {
        _pageControlOrigin = CGPointMake(self.width/2 - _pageControl.width/2, self.height-_pageControl.height);
    }
    _pageControl.top = _pageControlOrigin.y;
    
    [self relayout];
}

#pragma mark - 内部方法 -
- (void)resetTimer {
    if (_timer) {
        [_timer invalidate];
    }
    _timer = [NSTimer timerWithTimeInterval:_autoScrollInterval target:self selector:@selector(autoScrollForTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)autoScrollForTimer:(NSTimer *)timer {
    if (timer != _timer) {
        [timer invalidate];
        return;
    }
    
    _currentIndex++;
    CGPoint offset = self.contentOffset;
    offset.x = _currentIndex * self.width;
    [self setContentOffset:offset animated:YES];
}

- (void)relayout {
    self.contentOffset = CGPointMake(self.width * _currentIndex, 0);
    self.contentSize = CGSizeMake(_rowCount * self.width, self.height);
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
    visiableImageView.left = _currentIndex * self.width;
    visiableImageView.tag = _currentIndex;
    
    [self bringSubviewToFront:_pageControl];
    self.pageControl.left = self.contentOffset.x + _pageControlOrigin.x;
}


- (void)cleanInvisiableViews {
    __weak typeof(self) weakSelf = self;
    CGRect visiableRect = CGRectMake(self.contentOffset.x, 0, self.width, self.height);
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
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.width, self.height)];
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
        targetTag = (scrollView.contentOffset.x / self.width) + 1;
        UIImageView *iv = (UIImageView *)[self imageViewWithTag:targetTag];
        NSInteger datasourceIndex = [self datasourceIndexWithTag:targetTag];
        if (!iv) {
            iv = [self dequeueImageViewForIndex:datasourceIndex];
            iv.tag = targetTag;
        }
        
        if (_circleDelegate && [_circleDelegate respondsToSelector:@selector(circleView:configImageView:atRow:)]) {
            [_circleDelegate circleView:self configImageView:iv atRow:datasourceIndex];
        }
        
        iv.left = targetTag * self.width;
        if (self.contentSize.width + self.contentInset.right < iv.right) {
            UIEdgeInsets newInset = self.contentInset;
            newInset.right = iv.right - self.contentSize.width;
            self.contentInset = newInset;
        }
    } else if (self.direction == SZCircleViewDirectionToShowLeft) {
        targetTag = scrollView.contentOffset.x / self.width;
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
        
        iv.left = targetTag * self.width;
        if (iv.left < 0 && self.contentInset.left < -iv.left) {
            UIEdgeInsets newInset = self.contentInset;
            newInset.left = -iv.left;
            self.contentInset = newInset;
        }
    }    
    
    _lastOffset = scrollView.contentOffset;

    NSInteger newIndex = (NSInteger)round(scrollView.contentOffset.x / scrollView.width) % (NSInteger)self.rowCount;
    while (newIndex < 0) {
        newIndex += self.rowCount;
    }
    self.currentIndex = newIndex;
    self.pageControl.left = self.contentOffset.x + _pageControlOrigin.x;
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
