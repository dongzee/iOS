//
//  WYStoreProductView.h
//  WYCore
//
//  Created by wanglidong on 13-5-11.
//  Copyright (c) 2013年 wy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WYStoreProductView : NSObject

/** 以视图方式显示appstore
 *
 * @param appURL app地址
 * @param pvc 模态弹出的父窗口, 不能为空
 *
 */
+ (void)showProduct:(NSString *)appURL onParentView:(UIViewController *)pvc;

@end

@interface WYString : NSObject

/** 截取字符串string, 从 fromString 到 toString 的内容
 *
 *  特殊场景：
 *      如果fromString为nil，则从头开始
 *      如果toString为nil，则截取到末尾
 *      如果fromString或toString不为nil，又没有发现fromString或toString，则返回nil
 */
+ (NSString *)subString:(NSString *)string from:(NSString *)fromString to:(NSString *)toString;

@end
