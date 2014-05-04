//
//  UIScrollView+AnimationPullRefresh.h
//  AnimationPUll
//
//  Created by ccbo on 14-5-1.
//  Copyright (c) 2014年 ccbo. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AnimationPullToRefreshView;

typedef NS_ENUM(NSInteger, AnimationPullToRefreshState){
    AnimationPullToRefreshStateStopped = 0,
    AnimationPullToRefreshStateTriggered,
    AnimationPullToRefreshStateLoading
} ;

@interface UIScrollView (AnimationPullRefresh)

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler;
- (void)triggerPullToRefresh;

@property (nonatomic, strong, readonly) AnimationPullToRefreshView *pullToRefreshView;
@property (nonatomic, assign) BOOL showsPullToRefresh;

@end

@interface AnimationPullToRefreshView : UIImageView

@property (nonatomic, copy) void (^pullToRefreshActionHandler)(void);
@property (nonatomic, assign) AnimationPullToRefreshState currentState;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat originalTopInset;
@property (nonatomic, strong) NSMutableArray *loadingAnimationImages;
@property (nonatomic, strong) NSMutableArray *triggerAnimationImages;
@property (nonatomic, strong) NSMutableArray *stopAnimationImages;
@property (nonatomic, assign) CGFloat loadingAnimationDuration;
@property (nonatomic, assign) CGFloat triggerAnimationDuration;
@property (nonatomic, assign) CGFloat stopAnimationDuration;

- (void)finishTask;

@end