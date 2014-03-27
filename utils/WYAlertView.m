//
//  WYAlertView.m
//  WYCore
//
//  Created by wanglidong on 13-4-25.
//  Copyright (c) 2013年 wy. All rights reserved.
//

#import "WYAlertView.h"

#ifdef LOG_THIS_FILE
#undef LOG_THIS_FILE
#endif
#define LOG_THIS_FILE 0

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

@interface WYAlertView ()
{
    NSMutableArray *m_blocks;
}
@end

@implementation WYAlertView

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
//app resign notify method
- (void)dismissAutomatically:(NSNotification *)note
{
    //hide it
    if(self.shouldDismissWhenAppEnterBackground)
    {
        [self dismissWithClickedButtonIndex:0 animated:NO];
    }
}

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    WYAlertViewClickedButtonAtIndexBlock block = [m_blocks objectAtIndex:buttonIndex];
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

// title & block 成对添加, 遇到nil就结束
- (void)addOtherButtons:(NSString *)otherButtonTitles withVAList:(va_list)list
{
    id t = otherButtonTitles;
    id b = va_arg(list,id);
    
    while (b) {
        
        [self addButtonWithTitle:t];
        [m_blocks addObject:SAFE_ARC_BLOCK_COPY((WYAlertViewClickedButtonAtIndexBlock)b)];
        
        t = va_arg(list,id);
        // 按钮内容为空或不为String时即认为结束
        if (nil == t || ![t isKindOfClass:[NSString class]]) {
            break;
        }
        
        b = va_arg(list,id);
    }
}

// 用取消按钮初始化alert
- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(WYAlertViewClickedButtonAtIndexBlock)cancelBlock
{
    [WYAlertView dismissAllActionView];

    self = [super initWithTitle:title ? title : @""
                        message:message ? message : @""
                       delegate:self
              cancelButtonTitle:cancelButtonTitle
              otherButtonTitles:nil];
    if(self)
    {
        m_blocks = [[NSMutableArray alloc]initWithCapacity:1];
        if(cancelBlock)
        {
            [m_blocks addObject:SAFE_ARC_BLOCK_COPY(cancelBlock)];
        }
        else
        {
            [m_blocks addObject:[NSNull null]];
        }
        self.shouldDismissWhenAppEnterBackground = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissAutomatically:) name:UIApplicationDidEnterBackgroundNotification object:[UIApplication sharedApplication]];
    }
    return self;
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(WYAlertViewClickedButtonAtIndexBlock)cancelBlock otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION
{
    if (cancelButtonTitle) {
        
        self = [self initWithTitle:title message:message cancelButtonTitle:cancelButtonTitle cancelBlock:cancelBlock];
        
        if(self && otherButtonTitles)
        {
            va_list list;
            va_start(list,otherButtonTitles);
            [self addOtherButtons:otherButtonTitles withVAList:list];
            va_end(list);
        }
    }
    return self;
}

+ (void)show:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(WYAlertViewClickedButtonAtIndexBlock)cancelBlock otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION
{
    if (cancelButtonTitle) {
        
        WYAlertView *alert = SAFE_ARC_AUTORELEASE([[WYAlertView alloc] initWithTitle:title message:message cancelButtonTitle:cancelButtonTitle cancelBlock:cancelBlock]);
        
        if(alert && otherButtonTitles)
        {
            va_list list;
            va_start(list,otherButtonTitles);
            [alert addOtherButtons:otherButtonTitles withVAList:list];
            va_end(list);
        }
        
        
        // 显示
        [alert show];
    }
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message buttonTitle:(NSString *)buttonTitle completion:(WYAlertViewClickedButtonAtIndexBlock)completion
{
    if (buttonTitle) {
        
        self = [self initWithTitle:title message:message cancelButtonTitle:buttonTitle cancelBlock:completion];

    }
    return self;
}

+ (void)show:(NSString *)title message:(NSString *)message buttonTitle:(NSString *)buttonTitle completion:(WYAlertViewClickedButtonAtIndexBlock)completion
{
    if (buttonTitle) {

        WYAlertView *alert = SAFE_ARC_AUTORELEASE([[WYAlertView alloc] initWithTitle:title message:message cancelButtonTitle:buttonTitle cancelBlock:completion]);
        // 显示
        [alert show];
    }
}

@end

/*********************************************************************************
 以下只作为研究资料，不作为接口对外提供
 *********************************************************************************/
#if 0

/** 产生一个Alert对话框,未使用ARC时需要手动释放
 *
 * @param title     弹出标题
 * @param message   提示信息
 * @param buttonTitlesAndBlocks buttons和blocks必须【成对】出现, 第一个为取消按钮
 *
 * @return 返回对话框对象
 */
- (id)initWithTitle:(NSString *)title message:(NSString *)message buttonTitlesAndBlocks:(NSString *)cancelButtonTitle, ... NS_REQUIRES_NIL_TERMINATION;

/** 弹出一个对话框，buttons和blocks必须成对出现
 *
 * @param title     弹出标题
 * @param message   提示信息
 * @param buttonTitlesAndBlocks buttons和blocks必须【成对】出现, 第一个为取消按钮
 */
+ (void)show:(NSString *)title message:(NSString *)message buttonTitlesAndBlocks:(NSString *)cancelButtonTitle, ... NS_REQUIRES_NIL_TERMINATION;


Class object_getClass(id object);

@interface WYAlertView ()
{
    NSMutableArray *m_blocks;
}
@end
@implementation WYAlertView
- (void)dealloc
{
#if LOG_THIS_FILE
    NSLog(@"%s",__func__);
#endif
    [self terminate];
    [super dealloc];
}

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    dispatch_block_t block = [m_blocks objectAtIndex:buttonIndex];
    if(![block isEqual:[NSNull null]])
    {
        dispatch_async(dispatch_get_current_queue(),block);
    }
#if LOG_THIS_FILE
    NSLog(@"%s [%d]%@",__func__,buttonIndex,block);
#endif
    [self terminate];
}

- (void)terminate
{
    for (dispatch_block_t block in m_blocks) {
        Block_release(block);
    }
    [m_blocks removeAllObjects], [m_blocks release], m_blocks = nil;
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(dispatch_block_t)cancelBlock
{
    self = [super initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
    if(self)
    {
        m_blocks = [[NSMutableArray alloc]initWithCapacity:1];
        if(cancelBlock)
        {
            [m_blocks addObject:Block_copy(cancelBlock)];
        }
        else
        {
            [m_blocks addObject:[NSNull null]];
        }
    }
    return self;
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(dispatch_block_t)cancelBlock otherButtonTitles:(NSString *)otherButtonTitles withVAList:(va_list)list
{
    [self initWithTitle:title message:message cancelButtonTitle:cancelButtonTitle cancelBlock:cancelBlock];
    if(self)
    {
#if 0
        [self addOtherButtonsAllowNilBlock:otherButtonTitles withVAList:list];
#else
        [self addOtherButtons:otherButtonTitles withVAList:list];
#endif
    }
    return self;
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle withVAList:(va_list)list
{
    self = [super initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
    if(self)
    {
        m_blocks = [[NSMutableArray alloc]initWithCapacity:1];
    }
    id va = va_arg(list,id);
    do {
        if(va)
        {
            [m_blocks addObject:Block_copy(va)];
        }
        else
        {
            [m_blocks addObject:[NSNull null]];
        }
        
        // 按钮内容为空或不为String时即认为结束
        va = va_arg(list,id);
        Class c = object_getClass(va);
        if(nil == va || (c != NSClassFromString(@"__NSCFConstantString") && c != [NSString class])) break;
        [self addButtonWithTitle:va];
        
        va = va_arg(list,id);
        
    } while (1);
    return self;
}

// 允许block为nil
- (void)addOtherButtonsAllowNilBlock:(NSString *)otherButtonTitles withVAList:(va_list)list
{
    [self addButtonWithTitle:otherButtonTitles];
    id va = va_arg(list,id);
    do {
        if(va)
        {
            [m_blocks addObject:Block_copy(va)];
        }
        else
        {
            [m_blocks addObject:[NSNull null]];
        }
        
        // 按钮内容为空或不为String时即认为结束
        va = va_arg(list,id);
        Class c = object_getClass(va);
        if(nil == va || (c != NSClassFromString(@"__NSCFConstantString") && c != [NSString class])) break;
        [self addButtonWithTitle:va];
        
        va = va_arg(list,id);
        
    } while (1);
}

// 遇到nil就结束
- (void)addOtherButtons:(NSString *)otherButtonTitles withVAList:(va_list)list
{
    id t = otherButtonTitles;
    id b = va_arg(list,id);
    
    while (b) {
        
        [self addButtonWithTitle:otherButtonTitles];
        [m_blocks addObject:Block_copy(b)];
        
        t = va_arg(list,id);
        // 按钮内容为空或不为String时即认为结束
        if (nil == t || ![t isKindOfClass:[NSString class]]) {
            break;
        }
        
        b = va_arg(list,id);
    }
}

#pragma mark -
- (id)initWithTitle:(NSString *)title message:(NSString *)message buttonTitlesAndBlocks:(NSString *)cancelButtonTitle, ... NS_REQUIRES_NIL_TERMINATION
{
    if (cancelButtonTitle) {
        va_list list;
        va_start(list,cancelButtonTitle);
        self = [self initWithTitle:title message:message cancelButtonTitle:cancelButtonTitle withVAList:list];
        va_end(list);
    }
    
    return self;
}

+ (void)show:(NSString *)title message:(NSString *)message buttonTitlesAndBlocks:(NSString *)cancelButtonTitle, ... NS_REQUIRES_NIL_TERMINATION
{
    if (cancelButtonTitle) {
        va_list list;
        va_start(list,cancelButtonTitle);
        WYAlertView *alert = [[[WYAlertView alloc]initWithTitle:title message:message cancelButtonTitle:cancelButtonTitle withVAList:list]autorelease];
        va_end(list);
        [alert show];
    }
}

#if 0
- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(dispatch_block_t)cancelBlock otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION
{
    if (cancelButtonTitle) {
        
        [self initWithTitle:title message:message cancelButtonTitle:cancelButtonTitle cancelBlock:cancelBlock];
        
        if(self && otherButtonTitles)
        {
            va_list list;
            va_start(list,otherButtonTitles);
            [self addOtherButtonsAllowNilBlock:otherButtonTitles withVAList:list];
            va_end(list);
        }
    }
    return self;
}

+ (void)show:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(dispatch_block_t)cancelBlock otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION
{
    if (cancelButtonTitle) {

        WYAlertView *alert = SAFE_ARC_AUTORELEASE([[WYAlertView alloc] initWithTitle:title message:message cancelButtonTitle:cancelButtonTitle cancelBlock:cancelBlock]);
        
        if(alert && otherButtonTitles)
        {
            va_list list;
            va_start(list,otherButtonTitles);
            [alert addOtherButtonsAllowNilBlock:otherButtonTitles withVAList:list];
            va_end(list);
        }
        
        [alert show];
    }
}

#else
- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(dispatch_block_t)cancelBlock otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION
{
    if (cancelButtonTitle) {
        
        [self initWithTitle:title message:message cancelButtonTitle:cancelButtonTitle cancelBlock:cancelBlock];
        
        if(self && otherButtonTitles)
        {
            va_list list;
            va_start(list,otherButtonTitles);
            [self addOtherButtons:otherButtonTitles withVAList:list];
            va_end(list);
        }
    }
    return self;
}

+ (void)show:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(dispatch_block_t)cancelBlock otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION
{
    if (cancelButtonTitle) {
        va_list list;
        va_start(list,otherButtonTitles);
        WYAlertView *alert = [[[WYAlertView alloc] initWithTitle:title message:message cancelButtonTitle:cancelButtonTitle cancelBlock:cancelBlock otherButtonTitles:otherButtonTitles withVAList:list]autorelease];
        va_end(list);
        [alert show];
    }
}
#endif

@end


#endif

