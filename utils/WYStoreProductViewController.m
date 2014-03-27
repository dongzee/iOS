//
//  WYStoreProductViewController.m
//  WYCore
//
//  Created by wanglidong on 13-5-11.
//  Copyright (c) 2013年 wy. All rights reserved.
//

#import "WYStoreProductViewController.h"

//NSClassFromString(@"SKStoreProductViewController")

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
#define SAFE_ARC_BLOCK_COPY(x) (Block_copy(x))
#define SAFE_ARC_BLOCK_RELEASE(x) (Block_release(x))
#define SAFE_ARC_SUPER_DEALLOC() ([super dealloc])
#define SAFE_ARC_AUTORELEASE_POOL_START() NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
#define SAFE_ARC_AUTORELEASE_POOL_END() [pool release];
#endif

#define IS_PAD() (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_PHONE() (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)

@implementation WYStoreProductViewController

#pragma mark - point
+ (BOOL)showProduct:(NSString *)appIdentifier onParentView:(UIViewController *)pvc
{
#if LOG_THIS_FILE
    NSLog(@"%s[%@]",__func__,appIdentifier);
#endif
    if(NSClassFromString(@"SKStoreProductViewController") &&
       appIdentifier != nil &&
       pvc != nil &&
       [pvc isKindOfClass:[UIViewController class]])
    {
        // Initialize Product View Controller
        WYStoreProductViewController *storeProductViewController = [[WYStoreProductViewController alloc] init];
        // Configure View Controller
        [storeProductViewController setDelegate:storeProductViewController];
        [storeProductViewController loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier:appIdentifier}
                                              completionBlock:^(BOOL result, NSError *error) {
                                                  if (error) {

                                                      NSLog(@"Error %@ with User Info %@.", error, [error userInfo]);
                                                  } else {

                                                  }
                                              }];
        [pvc presentViewController:storeProductViewController animated:YES completion:nil];

        SAFE_ARC_RELEASE(storeProductViewController);
        
        return YES;
    }

    return NO;
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

// iOS6.0 & later
- (NSUInteger)supportedInterfaceOrientations
{
    if(IS_PHONE())
    {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    else
    {
        return UIInterfaceOrientationMaskAll;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    if(IS_PHONE())
    {
        return UIInterfaceOrientationIsPortrait(interfaceOrientation);
    }
    else
    {
        return YES;
    }
}

- (void)dealloc
{
#if LOG_THIS_FILE
    NSLog(@"%s",__func__);
#endif
    
    SAFE_ARC_SUPER_DEALLOC();
}

@end
