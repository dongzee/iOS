//
//  WYStoreProductView.m
//  WYCore
//
//  Created by wanglidong on 13-5-11.
//  Copyright (c) 2013年 wy. All rights reserved.
//

#import "WYStoreProductView.h"
#import "WYStoreProductViewController.h"

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
#define SAFE_ARC_BLOCK_COPY(x) (Block_copy(x))
#define SAFE_ARC_BLOCK_RELEASE(x) (Block_release(x))
#define SAFE_ARC_SUPER_DEALLOC() ([super dealloc])
#define SAFE_ARC_AUTORELEASE_POOL_START() NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
#define SAFE_ARC_AUTORELEASE_POOL_END() [pool release];
#endif

@implementation WYStoreProductView

+ (void)showProduct:(NSString *)appURL onParentView:(UIViewController *)pvc
{
    if (!appURL) {
        return;
    }
    
    NSString *appIdentifier = [WYString subString:appURL from:@"id" to:@"?mt"];

    if (!appIdentifier) {
        appIdentifier = [WYString subString:appURL from:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=" to:nil];
    }
    if (!appIdentifier) {
        appIdentifier = [NSString stringWithFormat:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@",appURL];
    }
    // 使用iOS6 自带store视图
    if (appIdentifier && [WYStoreProductViewController showProduct:appIdentifier onParentView:pvc]) {
        
//        appIdentifier = nil;

        return;
    }
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appURL]];
    
    // 使用自实现的 store视图
//    [WYWebViewController showURL:appURL onParentView:pvc];
}

@end

@implementation WYString

+ (NSString *)subString:(NSString *)string from:(NSString *)fromString to:(NSString *)toString
{
    if(string ==nil) return nil;
    
    NSMutableString* str = SAFE_ARC_AUTORELEASE([[NSMutableString alloc]initWithString:string]);

    if(nil != toString)
    {
        NSRange range = [string rangeOfString:toString];
        int location = range.location;
        int len = range.length;
        
        //没找到toString
        if (len <= 0) {
            return nil;
        }
        //删除toString及其后面
        NSInteger length = [str length];
        [str deleteCharactersInRange:NSMakeRange(location,length-location)];
    }
    
    if(nil != fromString)
    {
        NSRange range = [string rangeOfString:fromString];
        int location = range.location;
        int len = range.length;
        
        //没找到fromString
        if (len <= 0) {
            return nil;
        }
        //删除fromString及其前面
        [str deleteCharactersInRange:NSMakeRange(0,location+len)];
    }
    
    return str;
}

@end
