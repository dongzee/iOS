//
//  WYAnimation.h
//  WYCore
//
//  Created by wanglidong on 13-4-23.
//  Copyright (c) 2013年 ksyun. All rights reserved.
//
//  动画控制类，默认动画播放时间为系统动画时间。

#import <UIKit/UIKit.h>

@interface WYAnimation : NSObject

/** 
-- english comment:
 * Add an self-rotate animation on view. Remove it manually by call:
   + (void)removeAnimation:(UIView *)view forKey:(NSString *)key;
     
 * @param view     target view
 * @param key      animation's key
 * @param duration one cycle duration

-- 中文注释:
 * 添加一个自转动画到视图上, 移除时需要手动调用:
   + (void)removeAnimation:(UIView *)view forKey:(NSString *)key;

 * @param view     动画承载者
 * @param key      动画key, 移除时用
 * @param duration 自转一圈时间
*/
+ (void)addRotateAnimation:(UIView *)view forKey:(NSString *)key withDuration:(CFTimeInterval)duration;

/**
-- english comment:
 * Remove animation by key

 * @param view     target view
 * @param key      animation's key

-- 中文注释:
 * 通过key移除view上的动画
 
 * @param view     动画承载者
 * @param key      标识该动画的关键字
 */
+ (void)removeAnimation:(UIView *)view forKey:(NSString *)key;

/**
-- english comment:
 * show image with fade animation
 
 * @param imageView target imageView
 * @param image     UIImage to show

-- 中文注释:
 * 淡入淡出效果显示一个图片
 
 * @param imageView 动画承载者
 * @param image     要显示的图片
 */
+ (void)fadeAnimation:(UIImageView *)imageView withImage:(UIImage *)image;

/**
-- english comment:
 * zoom in - then out animation
 * @param view       target view
 * @param completion animation completely block

-- 中文注释:
 * 先小后大效果
 * @param view       动画承载者
 * @param completion 动画结束后的回调block
 */
+ (void)zoomInAndOutAnimation:(UIView *)view completion:(void (^)(BOOL finished))completion NS_AVAILABLE_IOS(4_0);

/**
-- english comment:
 * zoom in - then hide
 * @param view       target view
 * @delay            delay between animations
 * @param completion animation completely block
 
-- 中文注释:
 * 缩小消失效果
 * @param view       动画承载者
 * @delay            动画之间间隔
 * @param completion 动画结束后的回调block
 */
+ (void)zoomInAnimation:(UIView *)view delay:(NSTimeInterval)delay completion:(void (^)(BOOL finished))completion NS_AVAILABLE_IOS(4_0);
/**
-- english comment:
 * zoom out - then hide
 * @param view       target view
 * @delay            delay between animations
 * @param completion animation completely block

-- 中文注释:
 * 放大消失效果
 * @param view       动画承载者
 * @delay            动画之间间隔
 * @param completion 动画结束后的回调block
 */
+ (void)zoomOutAnimation:(UIView *)view delay:(NSTimeInterval)delay completion:(void (^)(BOOL finished))completion NS_AVAILABLE_IOS(4_0);

/**
-- english comment:
 *step1 show: from A to normal
 *step2 hide: from normal to B
 * @param view       target view
 * @param from       A
 * @param to         B
 * @param delay      delay between animations
 * @param completion animation completely block

-- 中文注释:
 * 阶段1显示: 从A缩放到正常
 * 阶段2隐藏: 缩放到B
 * @param view       装载动画的视图
 * @param from       初始态
 * @param to         结束态
 * @param delay      动画之间间隔
 * @param completion 动画结束后的回调block
 */
+ (void)zoomAnimation:(UIView *)view from:(CGAffineTransform)transformA to:(CGAffineTransform)transformB delay:(NSTimeInterval)delay completion:(void (^)(BOOL finished))completion NS_AVAILABLE_IOS(4_0);

@end
