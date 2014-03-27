//
//  WYActionSheet.m
//  WYCore
//
//  Created by wanglidong on 13-5-2.
//  Copyright (c) 2013年 wy. All rights reserved.
//

#import "WYActionSheet.h"

#define LOG_THIS_FILE 0

@interface WYActionSheet ()
{
    NSMutableArray *m_blocks;
}
@end
#if !defined(__clang__) || __clang_major__ < 3
#ifndef __bridge
#define __bridge
#endif

#ifndef __bridge_retain
#define __bridge_retain
#endif

#ifndef __bridge_retained
#define __bridge_retained
#endif

#ifndef __autoreleasing
#define __autoreleasing
#endif

#ifndef __strong
#define __strong
#endif

#ifndef __unsafe_unretained
#define __unsafe_unretained
#endif

#ifndef __weak
#define __weak
#endif
#endif

#if __has_feature(objc_arc)
#define SAFE_ARC_PROP_RETAIN strong
#define SAFE_ARC_RETAIN(x) (x)
#define SAFE_ARC_RELEASE(x)
#define SAFE_ARC_AUTORELEASE(x) (x)
#define SAFE_ARC_BLOCK_COPY(x) (x)
#define SAFE_ARC_BLOCK_RELEASE(x)
#define SAFE_ARC_SUPER_DEALLOC()
#define SAFE_ARC_AUTORELEASE_POOL_START() @autoreleasepool {
#define SAFE_ARC_AUTORELEASE_POOL_END() }
#else
#define SAFE_ARC_PROP_RETAIN retain
#define SAFE_ARC_RETAIN(x) ([(x) retain])
#define SAFE_ARC_RELEASE(x) ([(x) release])
#define SAFE_ARC_AUTORELEASE(x) ([(x) autorelease])
#define SAFE_ARC_BLOCK_COPY(x) (Block_copy((x)))
#define SAFE_ARC_BLOCK_RELEASE(x) (Block_release(x))
#define SAFE_ARC_SUPER_DEALLOC() ([super dealloc])
#define SAFE_ARC_AUTORELEASE_POOL_START() NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
#define SAFE_ARC_AUTORELEASE_POOL_END() [pool release];
#endif

NSString *const dismissAllActionViewNotify = @"wydmaavn";

@implementation WYActionSheet

+ (void)dismissAllActionView
{
    [[NSNotificationCenter defaultCenter] postNotificationName:dismissAllActionViewNotify object:nil];
}

- (void)dealloc
{
#if LOG_THIS_FILE
    NSLog(@"%s",__func__);
#endif
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self terminate];

    SAFE_ARC_SUPER_DEALLOC();
}
//
- (void)terminate
{
#if ! __has_feature(objc_arc)
    for (dispatch_block_t block in m_blocks) {
        Block_release(block);
    }
#endif
    [m_blocks removeAllObjects];
    SAFE_ARC_RELEASE(m_blocks);
    m_blocks = nil;
}

#pragma mark notify
- (void)dismissWhenOtherShow
{
    //hide it
    [self dismissWithClickedButtonIndex:0 animated:NO];
}

- (void)dismissWhenDeviceRotate
{
    //hide it
    if(self.shouldDismissWhenDeviceRotate)
    {
        [self dismissWithClickedButtonIndex:0 animated:NO];
    }
}

//app resign notify method
- (void)dismissWhenAppEnterBackground
{
    //hide it
    if(self.shouldDismissWhenAppEnterBackground)
    {
        [self dismissWithClickedButtonIndex:0 animated:NO];
    }
}

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    WYActionSheetClickedButtonAtIndexBlock block = [m_blocks objectAtIndex:buttonIndex];
    if(![block isEqual:[NSNull null]])
    {
        dispatch_async(dispatch_get_main_queue(),^{
            block(buttonIndex);
        });
    }
#if LOG_THIS_FILE
    NSLog(@"%s [%d]%@",__func__,buttonIndex,block);
#endif
    //    [self terminate];
}

// title & block 成对添加
- (void)addOtherButtons:(NSString *)title withBlock:(WYActionSheetClickedButtonAtIndexBlock)block
{
    [self addButtonWithTitle:title];
    if(block)
    {
        [m_blocks addObject:SAFE_ARC_BLOCK_COPY(block)];
    }
    else
    {
        [m_blocks addObject:[NSNull null]];
    }
}
// title & block 成对添加, 遇到nil就结束
- (void)addOtherButtons:(NSString *)otherButtonTitles withVAList:(va_list)list
{
    id t = otherButtonTitles;
    id b = va_arg(list,id);
    
    while (b) {
        
        [self addButtonWithTitle:t];
        [m_blocks addObject:SAFE_ARC_BLOCK_COPY((WYActionSheetClickedButtonAtIndexBlock)b)];
        
        t = va_arg(list,id);
        // 按钮内容为空或不为String时即认为结束
        if (nil == t || ![t isKindOfClass:[NSString class]]) {
            break;
        }
        
        b = va_arg(list,id);
    }
}

// 初始化actionSheet
- (id)initWithTitle:(NSString *)title
{
    [WYActionSheet dismissAllActionView];
    self = [super initWithTitle:title
                       delegate:self
              cancelButtonTitle:nil
         destructiveButtonTitle:nil
              otherButtonTitles:nil];
    
    if(self)
    {
        m_blocks = [[NSMutableArray alloc]initWithCapacity:1];
        
        self.shouldDismissWhenAppEnterBackground = YES;
        self.shouldDismissWhenDeviceRotate = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(dismissWhenAppEnterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(dismissWhenDeviceRotate)
                                                     name:UIApplicationWillChangeStatusBarOrientationNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(dismissWhenOtherShow)
                                                     name:dismissAllActionViewNotify
                                                   object:nil];
        
    }
    return self;
}

- (void)setCancelButtonWithLastIndex
{
    [self setCancelButtonIndex:(self.numberOfButtons - 1 )];
}

- (void)setDestructiveButtonWithFirstIndex
{
    [self setDestructiveButtonIndex:0];
}

- (id)initWithTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(WYActionSheetClickedButtonAtIndexBlock)cancelBlock otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION
{
    if (cancelButtonTitle) {
        
        self = [self initWithTitle:title];

        if(self)
        {
            if(otherButtonTitles)
            {
                va_list list;
                va_start(list,otherButtonTitles);
                [self addOtherButtons:otherButtonTitles withVAList:list];
                va_end(list);
            }
            
            // 添加取消按钮
            [self addOtherButtons:cancelButtonTitle withBlock:cancelBlock];
            [self setCancelButtonWithLastIndex];
        }
        
    }
    return self;
}

+ (void)showInview:(UIView *)view withTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(WYActionSheetClickedButtonAtIndexBlock)cancelBlock otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION
{
    if (cancelButtonTitle) {
        
        WYActionSheet *sheet = SAFE_ARC_AUTORELEASE([[WYActionSheet alloc] initWithTitle:title]);

        if(sheet)
        {
            if(otherButtonTitles)
            {
                va_list list;
                va_start(list,otherButtonTitles);
                [sheet addOtherButtons:otherButtonTitles withVAList:list];
                va_end(list);
            }
            // 添加取消按钮
            [sheet addOtherButtons:cancelButtonTitle withBlock:cancelBlock];
            [sheet setCancelButtonWithLastIndex];
            
            // 显示
            [sheet showInView:view];
        }
    }
}

+ (void)showFromTabBar:(UITabBar *)view withTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(WYActionSheetClickedButtonAtIndexBlock)cancelBlock otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION
{
    if (cancelButtonTitle) {
        
        WYActionSheet *sheet = SAFE_ARC_AUTORELEASE([[WYActionSheet alloc] initWithTitle:title]);
        
        
        if(sheet)
        {
            if(otherButtonTitles)
            {
                va_list list;
                va_start(list,otherButtonTitles);
                [sheet addOtherButtons:otherButtonTitles withVAList:list];
                va_end(list);
            }
            // 添加取消按钮
            [sheet addOtherButtons:cancelButtonTitle withBlock:cancelBlock];
            [sheet setCancelButtonWithLastIndex];
            
            // 显示
            [sheet showFromTabBar:view];
        }
        
    }
}

+ (void)showFromToolbar:(UIToolbar *)view withTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(WYActionSheetClickedButtonAtIndexBlock)cancelBlock otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION
{
    if (cancelButtonTitle) {
        
        WYActionSheet *sheet = SAFE_ARC_AUTORELEASE([[WYActionSheet alloc] initWithTitle:title]);
        
        
        if(sheet)
        {
            if(otherButtonTitles)
            {
                va_list list;
                va_start(list,otherButtonTitles);
                [sheet addOtherButtons:otherButtonTitles withVAList:list];
                va_end(list);
            }
            // 添加取消按钮
            [sheet addOtherButtons:cancelButtonTitle withBlock:cancelBlock];
            [sheet setCancelButtonWithLastIndex];
            
            // 显示
            [sheet showFromToolbar:view];
        }
    }
}

+ (void)showFromBarButtonItem:(UIBarButtonItem *)item animated:(BOOL)animated withTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(WYActionSheetClickedButtonAtIndexBlock)cancelBlock otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION
{
    if (cancelButtonTitle) {
        
        WYActionSheet *sheet = SAFE_ARC_AUTORELEASE([[WYActionSheet alloc] initWithTitle:title]);
        
        
        if(sheet)
        {
            if(otherButtonTitles)
            {
                va_list list;
                va_start(list,otherButtonTitles);
                [sheet addOtherButtons:otherButtonTitles withVAList:list];
                va_end(list);
            }
            // 添加取消按钮
            [sheet addOtherButtons:cancelButtonTitle withBlock:cancelBlock];
            [sheet setCancelButtonWithLastIndex];
            
            // 显示
            [sheet showFromBarButtonItem:item animated:animated];
        }
        
    }
}

+ (void)showFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated withTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(WYActionSheetClickedButtonAtIndexBlock)cancelBlock otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION
{
    if (cancelButtonTitle) {
        
        WYActionSheet *sheet = SAFE_ARC_AUTORELEASE([[WYActionSheet alloc] initWithTitle:title]);
        
        
        if(sheet)
        {
            if(otherButtonTitles)
            {
                va_list list;
                va_start(list,otherButtonTitles);
                [sheet addOtherButtons:otherButtonTitles withVAList:list];
                va_end(list);
            }
            
            // 添加取消按钮
            [sheet addOtherButtons:cancelButtonTitle withBlock:cancelBlock];
            [sheet setCancelButtonWithLastIndex];
            
            // 显示
            [sheet showFromRect:rect inView:view animated:animated];
        }
        
    }
}

#pragma mark - destructiveButton

+ (void)showInview:(UIView *)view
         withTitle:(NSString *)title
 cancelButtonTitle:(NSString *)cancelButtonTitle
       cancelBlock:(WYActionSheetClickedButtonAtIndexBlock)cancelBlock
destructiveButtonTitle:(NSString *)destructiveButtonTitle
  destructiveBlock:(WYActionSheetClickedButtonAtIndexBlock)destructiveBlock
 otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION
{
    if (cancelButtonTitle) {
        
        WYActionSheet *sheet = SAFE_ARC_AUTORELEASE([[WYActionSheet alloc] initWithTitle:title]);
        
        if(sheet)
        {
            // 添加destructiveButton
            if(destructiveButtonTitle && destructiveBlock)
            {
                [sheet addOtherButtons:destructiveButtonTitle withBlock:destructiveBlock];
                [sheet setDestructiveButtonWithFirstIndex];
            }
            if(otherButtonTitles)
            {
                va_list list;
                va_start(list,otherButtonTitles);
                [sheet addOtherButtons:otherButtonTitles withVAList:list];
                va_end(list);
            }
            
            // 添加取消按钮
            [sheet addOtherButtons:cancelButtonTitle withBlock:cancelBlock];
            [sheet setCancelButtonWithLastIndex];
            
            // 显示
            [sheet showInView:view];
        }
    }
}

+ (void)showFromTabBar:(UITabBar *)view
             withTitle:(NSString *)title
     cancelButtonTitle:(NSString *)cancelButtonTitle
           cancelBlock:(WYActionSheetClickedButtonAtIndexBlock)cancelBlock
destructiveButtonTitle:(NSString *)destructiveButtonTitle
      destructiveBlock:(WYActionSheetClickedButtonAtIndexBlock)destructiveBlock
     otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION
{
    if (cancelButtonTitle) {
        
        WYActionSheet *sheet = SAFE_ARC_AUTORELEASE([[WYActionSheet alloc] initWithTitle:title]);
        
        if(sheet)
        {
            // 添加destructiveButton
            if(destructiveButtonTitle && destructiveBlock)
            {
                [sheet addOtherButtons:destructiveButtonTitle withBlock:destructiveBlock];
                [sheet setDestructiveButtonWithFirstIndex];
            }
            if(otherButtonTitles)
            {
                va_list list;
                va_start(list,otherButtonTitles);
                [sheet addOtherButtons:otherButtonTitles withVAList:list];
                va_end(list);
            }
            
            // 添加取消按钮
            [sheet addOtherButtons:cancelButtonTitle withBlock:cancelBlock];
            [sheet setCancelButtonWithLastIndex];
            
            // 显示
            [sheet showFromTabBar:view];
        }
    }
}

+ (void)showFromToolbar:(UIToolbar *)view
              withTitle:(NSString *)title
      cancelButtonTitle:(NSString *)cancelButtonTitle
            cancelBlock:(WYActionSheetClickedButtonAtIndexBlock)cancelBlock
 destructiveButtonTitle:(NSString *)destructiveButtonTitle
       destructiveBlock:(WYActionSheetClickedButtonAtIndexBlock)destructiveBlock
      otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION
{
    if (cancelButtonTitle) {
        
        WYActionSheet *sheet = SAFE_ARC_AUTORELEASE([[WYActionSheet alloc] initWithTitle:title]);
        
        if(sheet)
        {
            // 添加destructiveButton
            if(destructiveButtonTitle && destructiveBlock)
            {
                [sheet addOtherButtons:destructiveButtonTitle withBlock:destructiveBlock];
                [sheet setDestructiveButtonWithFirstIndex];
            }
            if(otherButtonTitles)
            {
                va_list list;
                va_start(list,otherButtonTitles);
                [sheet addOtherButtons:otherButtonTitles withVAList:list];
                va_end(list);
            }
            
            // 添加取消按钮
            [sheet addOtherButtons:cancelButtonTitle withBlock:cancelBlock];
            [sheet setCancelButtonWithLastIndex];
            
            // 显示
            [sheet showFromToolbar:view];
        }
    }
}

+ (void)showFromBarButtonItem:(UIBarButtonItem *)item
                     animated:(BOOL)animated
                    withTitle:(NSString *)title
            cancelButtonTitle:(NSString *)cancelButtonTitle
                  cancelBlock:(WYActionSheetClickedButtonAtIndexBlock)cancelBlock
       destructiveButtonTitle:(NSString *)destructiveButtonTitle
             destructiveBlock:(WYActionSheetClickedButtonAtIndexBlock)destructiveBlock
            otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION
{
    if (cancelButtonTitle) {
        
        WYActionSheet *sheet = SAFE_ARC_AUTORELEASE([[WYActionSheet alloc] initWithTitle:title]);
        
        if(sheet)
        {
            // 添加destructiveButton
            if(destructiveButtonTitle && destructiveBlock)
            {
                [sheet addOtherButtons:destructiveButtonTitle withBlock:destructiveBlock];
                [sheet setDestructiveButtonWithFirstIndex];
            }
            if(otherButtonTitles)
            {
                va_list list;
                va_start(list,otherButtonTitles);
                [sheet addOtherButtons:otherButtonTitles withVAList:list];
                va_end(list);
            }
            
            // 添加取消按钮
            [sheet addOtherButtons:cancelButtonTitle withBlock:cancelBlock];
            [sheet setCancelButtonWithLastIndex];
            
            // 显示
            [sheet showFromBarButtonItem:item animated:animated];
        }
    }
}

+ (void)showFromRect:(CGRect)rect
              inView:(UIView *)view
            animated:(BOOL)animated
           withTitle:(NSString *)title
   cancelButtonTitle:(NSString *)cancelButtonTitle
         cancelBlock:(WYActionSheetClickedButtonAtIndexBlock)cancelBlock
destructiveButtonTitle:(NSString *)destructiveButtonTitle
    destructiveBlock:(WYActionSheetClickedButtonAtIndexBlock)destructiveBlock
   otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION
{
    if (cancelButtonTitle) {
        
        WYActionSheet *sheet = SAFE_ARC_AUTORELEASE([[WYActionSheet alloc] initWithTitle:title]);
        
        if(sheet)
        {
            // 添加destructiveButton
            if(destructiveButtonTitle && destructiveBlock)
            {
                [sheet addOtherButtons:destructiveButtonTitle withBlock:destructiveBlock];
                [sheet setDestructiveButtonWithFirstIndex];
            }
            if(otherButtonTitles)
            {
                va_list list;
                va_start(list,otherButtonTitles);
                [sheet addOtherButtons:otherButtonTitles withVAList:list];
                va_end(list);
            }
            
            // 添加取消按钮
            [sheet addOtherButtons:cancelButtonTitle withBlock:cancelBlock];
            [sheet setCancelButtonWithLastIndex];
            
            // 显示
            [sheet showFromRect:rect inView:view animated:animated];
        }
    }
}


@end

//#endif
