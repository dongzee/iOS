//
//  WYActionSheet.h
//  WYCore
//
//  Created by wanglidong on 13-5-2.
//  Copyright (c) 2013年 wy. All rights reserved.
//  en custom actionsheet with block
//  cn 自定义actionsheet控件, 使用block方式

/*
 * iOS4.0 or later, for GCD.
 * Usage:
 *
 * ========================================
     WYActionSheet *sheet = [[WYActionSheet alloc]initWithTitle:[NSString stringWithFormat:@"%d",[indexPath row]] cancelButtonTitle:@"CANCEL" cancelBlock:^(NSInteger buttonIndex){
     
     NSLog(@"%s [%d]",__func__,buttonIndex);
     
     } otherButtonTitles:@"1",^(NSInteger buttonIndex){
     
     NSLog(@"%s [%d]",__func__,buttonIndex);
     
     }, @"2",^(NSInteger buttonIndex){
     
     NSLog(@"%s [%d]",__func__,buttonIndex);
     
     },nil];
 
    // sets destructive(red) button. 
    // -1 means not set. default is -1. 
    // ignored when only one button
    [sheet setDestructiveButtonIndex:0];
 
    [sheet showFromTabBar:self.tabBarController.tabBar];
 * ========================================
 */

#import <UIKit/UIKit.h>
typedef void (^WYActionSheetClickedButtonAtIndexBlock)(NSInteger buttonIndex); //

NS_CLASS_AVAILABLE_IOS(4_0) @interface WYActionSheet : UIActionSheet<UIActionSheetDelegate>

// dismiss automatically when app enter backgroud
// app回到后台时是否自动取消
@property(nonatomic, assign)BOOL shouldDismissWhenAppEnterBackground; // Default is YES.

// dismiss automatically when device rotate
// 屏幕旋转时是否自动取消
@property(nonatomic, assign)BOOL shouldDismissWhenDeviceRotate; // Default is YES.

/**
-- english comment
 * new an actionsheet, not autorelease
 * @param title             title
 * @param cancelButtonTitle cancel button text
 * @param cancelBlock       cancel block
 * @param otherButtonTitles pairs of button & block, until nil. block must not nil.

-- 中文注释
 * 产生一个ActionSheet, 不是autorelease的, 故未使用ARC时需要手动释放
 *
 * @param title             提示信息
 * @param cancelButtonTitle 取消按钮
 * @param cancelBlock       取消处理
 * @param otherButtonTitles 第一个nil之前参数有效, buttons和blocks必须【成对】出现, 且block不能为nil.
 */
- (id)initWithTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(WYActionSheetClickedButtonAtIndexBlock)cancelBlock otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

/**
-- english comment
 * show an actionsheet, autorelease

-- 中文注释
 * 显示一个ActionSheet, autorelease的
 */
+ (void)showInview:(UIView *)view withTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(WYActionSheetClickedButtonAtIndexBlock)cancelBlock otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

+ (void)showFromTabBar:(UITabBar *)view withTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(WYActionSheetClickedButtonAtIndexBlock)cancelBlock otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

+ (void)showFromToolbar:(UIToolbar *)view withTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(WYActionSheetClickedButtonAtIndexBlock)cancelBlock otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

+ (void)showFromBarButtonItem:(UIBarButtonItem *)item animated:(BOOL)animated withTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(WYActionSheetClickedButtonAtIndexBlock)cancelBlock otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

+ (void)showFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated withTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(WYActionSheetClickedButtonAtIndexBlock)cancelBlock otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

/**
-- english comment
 * show an actionsheet has destructiveButton, autorelease. destructiveButtonTitle & destructiveBlock not nil.
 
-- 中文注释
 * 显示一个ActionSheet, 有destructiveButton, autorelease. destructiveButtonTitle & destructiveBlock 不能为nil.
 */
+ (void)showInview:(UIView *)view
         withTitle:(NSString *)title
 cancelButtonTitle:(NSString *)cancelButtonTitle
       cancelBlock:(WYActionSheetClickedButtonAtIndexBlock)cancelBlock
destructiveButtonTitle:(NSString *)destructiveButtonTitle
  destructiveBlock:(WYActionSheetClickedButtonAtIndexBlock)destructiveBlock
 otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

+ (void)showFromTabBar:(UITabBar *)view
             withTitle:(NSString *)title
     cancelButtonTitle:(NSString *)cancelButtonTitle
           cancelBlock:(WYActionSheetClickedButtonAtIndexBlock)cancelBlock
destructiveButtonTitle:(NSString *)destructiveButtonTitle
      destructiveBlock:(WYActionSheetClickedButtonAtIndexBlock)destructiveBlock
     otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

+ (void)showFromToolbar:(UIToolbar *)view
              withTitle:(NSString *)title
      cancelButtonTitle:(NSString *)cancelButtonTitle
            cancelBlock:(WYActionSheetClickedButtonAtIndexBlock)cancelBlock
 destructiveButtonTitle:(NSString *)destructiveButtonTitle
       destructiveBlock:(WYActionSheetClickedButtonAtIndexBlock)destructiveBlock
      otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

+ (void)showFromBarButtonItem:(UIBarButtonItem *)item
                     animated:(BOOL)animated
                    withTitle:(NSString *)title
            cancelButtonTitle:(NSString *)cancelButtonTitle
                  cancelBlock:(WYActionSheetClickedButtonAtIndexBlock)cancelBlock
       destructiveButtonTitle:(NSString *)destructiveButtonTitle
             destructiveBlock:(WYActionSheetClickedButtonAtIndexBlock)destructiveBlock
            otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

+ (void)showFromRect:(CGRect)rect
              inView:(UIView *)view
            animated:(BOOL)animated
           withTitle:(NSString *)title
   cancelButtonTitle:(NSString *)cancelButtonTitle
         cancelBlock:(WYActionSheetClickedButtonAtIndexBlock)cancelBlock
destructiveButtonTitle:(NSString *)destructiveButtonTitle
    destructiveBlock:(WYActionSheetClickedButtonAtIndexBlock)destructiveBlock
   otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

@end

UIKIT_EXTERN NSString *const dismissAllActionViewNotify;
