//
//  GCDSingleton.h
//  WYCore
//
//  Created by dongzee on 13-3-20.
//  Acknowledgement : Singleton & GCDSingleton

/*
 * iOS4.0 or later, for GCD.
 * 1. This kind of Singleton is Thread safe.
 * 2. Both ARC and non-arc work well.
 *
 * [MyClass sharedInstance] will create a singleton. Also, if you wanna an elegant code, do it like this：
 * + (MyClass *)manager
 * {
 *    return [MyClass sharedInstance];
 * }
 *
 * [MyClass purgeSharedInstance] will release current singleton, which is valid during app life cycle，and managed by process.
 *
 * Usage:
 *
 * MyClass.h:
 * ========================================
 *	#import "GCDSingleton.h"
 *
 *	@interface MyClass: SomeSuperclass
 *	{
 *		...
 *	}
 *	GCD_SINGLETON_FOR_CLASS_HEADER(MyClass);
 *
 *	@end
 * ========================================
 *
 *
 *	MyClass.m:
 * ========================================
 *	#import "MyClass.h"
 *
 *	@implementation MyClass
 *
 *	GCD_SINGLETON_FOR_CLASS_HEADER(MyClass);
 *
 *	...
 *
 *	@end
 * ========================================
 */


#ifndef __WYCore_KSSingleton_H__
#define __WYCore_KSSingleton_H__

#import <objc/runtime.h>

#ifndef LOG_FUNC
#if TARGET_IPHONE_SIMULATOR && defined(DEBUG)
#define LOG_FUNC()  NSLog(@"%s[%d]",__func__,__LINE__)
#else
#define LOG_FUNC()
#endif
#endif


#define GCD_CLEAR_ONCE_TAG(__CLASSNAME__)\
_##__CLASSNAME__##_once_t1 = 0; \
_##__CLASSNAME__##_once_t2 = 0;

// .h
#define GCD_SINGLETON_FOR_CLASS_HEADER(__CLASSNAME__)	\
\
+ (__CLASSNAME__*) sharedInstance;	\
+ (void) purgeSharedInstance;

// .m
#if ! __has_feature(objc_arc) //non arc
#define GCD_SINGLETON_FOR_CLASS(__CLASSNAME__)	\
\
static volatile __CLASSNAME__* _##__CLASSNAME__##_sharedInstance = nil;	\
static dispatch_once_t _##__CLASSNAME__##_once_t1 = 0; \
static dispatch_once_t _##__CLASSNAME__##_once_t2 = 0; \
\
+ (__CLASSNAME__*) sharedInstanceNoSynch  \
{	\
return (__CLASSNAME__*) _##__CLASSNAME__##_sharedInstance;	\
}	\
\
+ (__CLASSNAME__*) sharedInstanceSynch	\
{	\
dispatch_once(& _##__CLASSNAME__##_once_t1, ^{  \
LOG_FUNC();  \
_##__CLASSNAME__##_sharedInstance = [[self alloc] init];  \
}); \
return (__CLASSNAME__*) _##__CLASSNAME__##_sharedInstance;	\
}	\
\
+ (__CLASSNAME__*) sharedInstance	\
{	\
return [self sharedInstanceSynch]; \
}	\
\
+ (id)allocWithZone:(NSZone*) zone	\
{	\
dispatch_once(& _##__CLASSNAME__##_once_t2, ^{  \
LOG_FUNC();  \
_##__CLASSNAME__##_sharedInstance = [super allocWithZone:zone];	\
if(nil != _##__CLASSNAME__##_sharedInstance)	\
{	\
Method newSharedInstanceMethod = class_getClassMethod(self, @selector(sharedInstanceNoSynch));	\
method_setImplementation(class_getClassMethod(self, @selector(sharedInstance)), method_getImplementation(newSharedInstanceMethod));	\
method_setImplementation(class_getInstanceMethod(self, @selector(retainCount)), class_getMethodImplementation(self, @selector(retainCountDoNothing)));	\
method_setImplementation(class_getInstanceMethod(self, @selector(release)), class_getMethodImplementation(self, @selector(releaseDoNothing)));	\
method_setImplementation(class_getInstanceMethod(self, @selector(autorelease)), class_getMethodImplementation(self, @selector(autoreleaseDoNothing)));	\
}	\
}); \
return (__CLASSNAME__*) _##__CLASSNAME__##_sharedInstance;	\
}	\
\
+ (void)purgeSharedInstance	\
{	\
@synchronized(self)	\
{	\
if(nil != _##__CLASSNAME__##_sharedInstance)	\
{	\
Method newSharedInstanceMethod = class_getClassMethod(self, @selector(sharedInstanceSynch));	\
method_setImplementation(class_getClassMethod(self, @selector(sharedInstance)), method_getImplementation(newSharedInstanceMethod));	\
method_setImplementation(class_getInstanceMethod(self, @selector(retainCount)), class_getMethodImplementation(self, @selector(retainCountDoSomething)));	\
method_setImplementation(class_getInstanceMethod(self, @selector(release)), class_getMethodImplementation(self, @selector(releaseDoSomething)));	\
method_setImplementation(class_getInstanceMethod(self, @selector(autorelease)), class_getMethodImplementation(self, @selector(autoreleaseDoSomething)));	\
[_##__CLASSNAME__##_sharedInstance release];	\
_##__CLASSNAME__##_sharedInstance = nil;	\
_##__CLASSNAME__##_once_t1 = 0; \
_##__CLASSNAME__##_once_t2 = 0; \
}	\
}	\
}	\
\
- (id)copyWithZone:(NSZone *)zone	\
{	\
return self;	\
}	\
\
- (id)retain	\
{	\
return self;	\
}	\
\
- (NSUInteger)retainCount	\
{	\
NSAssert1(1==0, @"SynthesizeSingleton: %@ ERROR: -(NSUInteger)retainCount method did not get swizzled.", self);	\
return NSUIntegerMax;	\
}	\
\
- (NSUInteger)retainCountDoNothing	\
{	\
return NSUIntegerMax;	\
}	\
- (NSUInteger)retainCountDoSomething	\
{	\
return [super retainCount];	\
}	\
\
- (oneway void)release	\
{	\
NSAssert1(1==0, @"SynthesizeSingleton: %@ ERROR: -(void)release method did not get swizzled.", self);	\
}	\
\
- (void)releaseDoNothing{}	\
\
- (void)releaseDoSomething	\
{	\
@synchronized(self)	\
{	\
[super release];	\
}	\
}	\
\
- (id)autorelease	\
{	\
NSAssert1(1==0, @"SynthesizeSingleton: %@ ERROR: -(id)autorelease method did not get swizzled.", self);	\
return self;	\
}	\
\
- (id)autoreleaseDoNothing	\
{	\
return self;	\
}	\
\
- (id)autoreleaseDoSomething	\
{	\
return [super autorelease];	\
}

#else //ARC

#define GCD_SINGLETON_FOR_CLASS(__CLASSNAME__)	\
\
static volatile __CLASSNAME__* _##__CLASSNAME__##_sharedInstance = nil;	\
static dispatch_once_t _##__CLASSNAME__##_once_t1 = 0; \
static dispatch_once_t _##__CLASSNAME__##_once_t2 = 0; \
\
+ (__CLASSNAME__*) sharedInstanceNoSynch  \
{	\
return (__CLASSNAME__*) _##__CLASSNAME__##_sharedInstance;	\
}	\
\
+ (__CLASSNAME__*) sharedInstanceSynch	\
{	\
dispatch_once(& _##__CLASSNAME__##_once_t1, ^{  \
LOG_FUNC();  \
_##__CLASSNAME__##_sharedInstance = [[self alloc] init];  \
}); \
return (__CLASSNAME__*) _##__CLASSNAME__##_sharedInstance;	\
}	\
\
+ (__CLASSNAME__*) sharedInstance	\
{	\
return [self sharedInstanceSynch]; \
}	\
\
+ (id)allocWithZone:(NSZone*) zone	\
{	\
dispatch_once(& _##__CLASSNAME__##_once_t2, ^{  \
LOG_FUNC();  \
_##__CLASSNAME__##_sharedInstance = [super allocWithZone:zone];	\
if(nil != _##__CLASSNAME__##_sharedInstance)	\
{	\
Method newSharedInstanceMethod = class_getClassMethod(self, @selector(sharedInstanceNoSynch));	\
method_setImplementation(class_getClassMethod(self, @selector(sharedInstance)), method_getImplementation(newSharedInstanceMethod));	\
}	\
}); \
return (__CLASSNAME__*) _##__CLASSNAME__##_sharedInstance;	\
}	\
\
+ (void)purgeSharedInstance	\
{	\
@synchronized(self)	\
{	\
if(nil != _##__CLASSNAME__##_sharedInstance)	\
{	\
Method newSharedInstanceMethod = class_getClassMethod(self, @selector(sharedInstanceSynch));	\
method_setImplementation(class_getClassMethod(self, @selector(sharedInstance)), method_getImplementation(newSharedInstanceMethod));	\
_##__CLASSNAME__##_sharedInstance = nil;	\
_##__CLASSNAME__##_once_t1 = 0; \
_##__CLASSNAME__##_once_t2 = 0; \
}	\
}	\
}	\
\
- (id)copyWithZone:(NSZone *)zone	\
{	\
return self;	\
}

#endif

#endif
