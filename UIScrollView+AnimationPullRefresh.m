//
//  UIScrollView+AnimationPullRefresh.m
//  AnimationPUll
//
//  Created by ccbo on 14-5-1.
//  Copyright (c) 2014年 ccbo. All rights reserved.
//

#import "UIScrollView+AnimationPullRefresh.h"
#import <objc/runtime.h>

#define monitorProperty @"contentOffset"

static CGFloat const AnimationPullToRefreshViewHeight = 60;
static char UIScrollViewAnimationPullToRefreshView;
@implementation UIScrollView (AnimationPullRefresh)

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler
{
    if (!self.pullToRefreshView) {
        AnimationPullToRefreshView *view = [[AnimationPullToRefreshView alloc] initWithFrame:CGRectMake(0, -AnimationPullToRefreshViewHeight, self.bounds.size.width, AnimationPullToRefreshViewHeight)];
        view.backgroundColor = [UIColor clearColor];
        view.pullToRefreshActionHandler = actionHandler;
        view.scrollView = self;
        view.originalTopInset = self.contentInset.top;
        [self addSubview:view];
        self.pullToRefreshView = view;
        self.showsPullToRefresh = YES;
    }
}

- (void)triggerPullToRefresh
{
    if (self.pullToRefreshView) {
        [self.pullToRefreshView setCurrentState:AnimationPullToRefreshStateLoading];
    }
}

- (void)setPullToRefreshView:(AnimationPullToRefreshView *)pullToRefreshView
{
    [self willChangeValueForKey:@"AnimationPullToRefreshView"];
    objc_setAssociatedObject(self, &UIScrollViewAnimationPullToRefreshView, pullToRefreshView, OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"AnimationPullToRefreshView"];
}

- (AnimationPullToRefreshView *)pullToRefreshView
{
    return objc_getAssociatedObject(self, &UIScrollViewAnimationPullToRefreshView);
}

- (BOOL)showsPullToRefresh
{
    return ![self.pullToRefreshView isHidden];
}

- (void)setShowsPullToRefresh:(BOOL)isShow
{
    [self.pullToRefreshView setHidden:!isShow];
}

@end

////////////////////////////////pull view/////////////////////////////
@implementation AnimationPullToRefreshView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.currentState = AnimationPullToRefreshStateStopped;
        self.contentMode = UIViewContentModeCenter;
        self.animationDuration = 0.5;
        self.animationRepeatCount = 0;
        self.loadingAnimationImages = [NSMutableArray array];
        self.triggerAnimationImages = [NSMutableArray array];
        self.stopAnimationImages = [NSMutableArray array];
    }
    return self;
}

- (void)setScrollView:(UIScrollView *)scrollView
{
    if (_scrollView) {
        [_scrollView removeObserver:self forKeyPath:monitorProperty];
    }
    _scrollView = scrollView;
    [_scrollView addObserver:self forKeyPath:monitorProperty options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (!newSuperview) {
        [self.superview removeObserver:self forKeyPath:monitorProperty];
    }
}

- (void)setCurrentState:(AnimationPullToRefreshState)currentState
{
    if (_currentState == currentState) {
        return;
    }
    if (currentState == AnimationPullToRefreshStateLoading) {
        _currentState = currentState;
        if (self.isAnimating) {
            [self stopAnimating];
        }
        if (self.loadingAnimationImages && self.loadingAnimationImages.count > 0) {
            if (self.loadingAnimationDuration > 0) {
                self.animationDuration = self.loadingAnimationDuration;
            }
            self.animationImages = self.loadingAnimationImages;
            [self startAnimating];
        }
        [UIView animateWithDuration:0.3 animations:^{
            UIEdgeInsets originInset = self.scrollView.contentInset;
            [self.scrollView setContentInset:UIEdgeInsetsMake(AnimationPullToRefreshViewHeight + self.originalTopInset, originInset.left, originInset.bottom, originInset.right)];
        } completion:^(BOOL finished) {
            self.pullToRefreshActionHandler();
        }];
    }
    else if (currentState == AnimationPullToRefreshStateTriggered){
        _currentState = currentState;
        if (self.isAnimating) {
            [self stopAnimating];
        }
        if (self.triggerAnimationImages && self.triggerAnimationImages.count > 0) {
            if (self.triggerAnimationDuration > 0) {
                self.animationDuration = self.triggerAnimationDuration;
            }
            self.animationImages = self.triggerAnimationImages;
            [self startAnimating];
        }
    }
    else {
        if (self.isAnimating) {
            [self stopAnimating];
        }
        if (self.stopAnimationImages && self.stopAnimationImages.count > 0) {
            if (self.stopAnimationDuration > 0) {
                self.animationDuration = self.stopAnimationDuration;
            }
            self.animationImages = self.stopAnimationImages;
            [self startAnimating];
        }
        [UIView animateWithDuration:0.5 animations:^{
            UIEdgeInsets originInset = self.scrollView.contentInset;
            [self.scrollView setContentInset:UIEdgeInsetsMake(self.originalTopInset, originInset.left, originInset.bottom, originInset.right)];
        } completion:^(BOOL finished) {
            _currentState = currentState;
            if (self.isAnimating) {
                [self stopAnimating];
            }
        }];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (self.scrollView && [keyPath isEqualToString:monitorProperty] && object == self.scrollView) {
        CGFloat offsetY = self.scrollView.contentOffset.y - self.scrollView.contentInset.top;
        if (!self.scrollView.isDragging && offsetY <= -AnimationPullToRefreshViewHeight) {
            [self setCurrentState:AnimationPullToRefreshStateLoading];
        }
        else if (offsetY < -self.scrollView.contentInset.top) {
            if (self.currentState == AnimationPullToRefreshStateStopped) {
                [self setCurrentState:AnimationPullToRefreshStateTriggered];
            }
        }
        else if (self.currentState == AnimationPullToRefreshStateTriggered){
            [self setCurrentState:AnimationPullToRefreshStateStopped];
        }
    }
}

- (void)finishTask
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setCurrentState:AnimationPullToRefreshStateStopped];
    });
}

@end