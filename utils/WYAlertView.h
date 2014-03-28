//
//  WYAlertView.h
//  WYCore
//
//  Created by wanglidong on 13-4-25.
//  Copyright (c) 2013年 wy. All rights reserved.
//
//  en custom AlertView with block
//  cn 自定义AlertView控件, 使用block方式

/*
 * iOS4.0 or later, for GCD.
 * Usage:
 *
 * ========================================
     [WYAlertView show:@"demo" message:@"this is a demo." cancelButtonTitle:@"cancel" cancelBlock:nil otherButtonTitles:
     @"button1",^{
     
        NSLog(@"click button1");
     },
     @"button2",^(NSInteger buttonIndex){
        
        NSLog(@"click button[%d]",buttonIndex);

     }, nil];
 * ========================================
 */

#import <UIKit/UIKit.h>

typedef void (^WYAlertViewClickedButtonAtIndexBlock)(NSInteger buttonIndex); //

NS_CLASS_AVAILABLE_IOS(4_0) @interface WYAlertView : UIAlertView

// dismiss automatically when app enter backgroud
// app回到后台时是否自动取消
@property(nonatomic, assign)BOOL shouldDismissWhenAppEnterBackground; // Default is YES.

/**
-- english comment
 * new an alert, not autorelease
 * @param title              title
 * @param message            message
 * @param cancelButtonTitle  cancel button text
 * @param cancelBlock button cancel block
 * @param otherButtonTitles  pairs of button & block, until nil. block must not nil.
 
-- 中文注释
 * 创建一个对话框, 不是autorelease的
 * @param title             弹出标题
 * @param message           提示信息
 * @param cancelButtonTitle 取消按钮
 * @param cancelBlock       取消处理
 * @param otherButtonTitles 第一个nil之前参数有效, buttons和blocks必须【成对】出现, 且block不能为nil.
 */
- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(WYAlertViewClickedButtonAtIndexBlock)cancelBlock otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

/**
-- english comment
 * show an alert, autorelease

-- 中文注释
 * 弹出一个对话框, autorelease的
 */
+ (void)show:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(WYAlertViewClickedButtonAtIndexBlock)cancelBlock otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

/**
-- english comment
 * new an alert, only one button, not autorelease
 * @param title       title
 * @param message     message
 * @param buttonTitle button text
 * @param completion  button event

-- 中文注释
 * 创建一个对话框, 只有一个按钮, 不是autorelease的
 * @param title       弹出标题
 * @param message     提示信息
 * @param buttonTitle 按钮
 * @param completion  处理
 */
- (id)initWithTitle:(NSString *)title message:(NSString *)message buttonTitle:(NSString *)buttonTitle completion:(WYAlertViewClickedButtonAtIndexBlock)completion;

/**
-- english comment
 * show an alert, only one button
 
-- 中文注释
 * 弹出一个对话框, 只有一个按钮
 */
+ (void)show:(NSString *)title message:(NSString *)message buttonTitle:(NSString *)buttonTitle completion:(WYAlertViewClickedButtonAtIndexBlock)completion;

@end

UIKIT_EXTERN NSString *const dismissAllActionViewNotify;
