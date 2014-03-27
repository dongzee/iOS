//
//  WYFileManager.m
//  WYCore
//
//  Created by wanglidong on 13-4-26.
//  Copyright (c) 2013年 wy. All rights reserved.
//

#import "WYFileManager.h"
#import <dirent.h>
#import <sys/stat.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import "WYDigest.h"

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

/******************************************************
 * 储存单位
 ******************************************************/
#ifndef WY_STORAGE_ARY
#define WY_STORAGE_ARY 1024                        // 进制
#define WY_STORAGE_KB 1024                         // 1KB
#define WY_STORAGE_MB (1024 * 1024)                // 1MB
#define WY_STORAGE_GB (1024 * 1024 * 1024)         // 1GB
#endif

//safely set object NSMutableDictionary
#define SAFE_SET_DICT(d, v, k) \
do{\
    if ((v) != nil && (k) != nil)\
        [(d) setObject:(v) forKey:(k)];\
}while(0)

#define SAFE_SET_DICT_INT(d,v,k) \
do{\
if ((k) != nil)\
[(d) setObject:[NSNumber numberWithInt:(v)] forKey:(k)];\
}while(0)

// 计算目录总大小
off_t folderSizeAtPath(const char *folderPath)
{
    off_t folderSize = 0;
    DIR* dir = opendir(folderPath);
    if (dir == NULL) return 0;
    struct dirent* child;
    while ((child = readdir(dir))!=NULL) {
        if (child->d_type == DT_DIR && (
                                        (child->d_name[0] == '.' && child->d_name[1] == 0) || // 忽略目录 .
                                        (child->d_name[0] == '.' && child->d_name[1] == '.' && child->d_name[2] == 0) // 忽略目录 ..
                                        )) continue;
        
        int folderPathLength = strlen(folderPath);
        char childPath[1024]; // 子文件的路径地址
        stpcpy(childPath, folderPath);
        if (folderPath[folderPathLength-1] != '/'){
            childPath[folderPathLength] = '/';
            folderPathLength++;
        }
        stpcpy(childPath+folderPathLength, child->d_name);
        childPath[folderPathLength + child->d_namlen] = 0;
        if (child->d_type == DT_DIR){ // directory
            folderSize += folderSizeAtPath(childPath); // 递归调用子目录
            // 把目录本身所占的空间也加上
            struct stat st;
            if(lstat(childPath, &st) == 0) folderSize += st.st_size;
        }else if (child->d_type == DT_REG || child->d_type == DT_LNK){ // file or link
            struct stat st;
            if(lstat(childPath, &st) == 0)
            {
                folderSize += st.st_size;
            }
        }
    }
    
    // 一定要关闭
    closedir(dir);
    return folderSize;
}

@implementation WYFileManager

#pragma mark - size
+ (long long)sizeOfFolder:(NSString *)path
{
    return folderSizeAtPath([path cStringUsingEncoding:NSUTF8StringEncoding]);
}

+ (long long)deviceTotalSize
{
    return [[self deviceAttributesForKey:NSFileSystemFreeSize] longLongValue];
}

+ (long long)deviceFreeSize
{
    return [[self deviceAttributesForKey:NSFileSystemFreeSize] longLongValue];
}

// 取得系统属性
+ (id)deviceAttributesForKey:(id)key
{
    NSDictionary *fattributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    return [fattributes objectForKey:key];
}

// 设置文件（夹）属性
+ (BOOL)setAttribute:(id)value forKey:(id)key ofItemAtPath:(NSString *)path error:(NSError **)error NS_AVAILABLE(10_5, 2_0)
{
    if(value && key)
    {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSDictionary *attr = [NSDictionary dictionaryWithObject:value  forKey:key];
        return [fm setAttributes:attr ofItemAtPath:path error:error];
    }

    return NO;
}

+ (BOOL)setModifyTime:(NSDate *)date ofItemAtPath:(NSString *)path NS_AVAILABLE(10_5, 2_0)
{
    return [self setAttribute:date forKey:NSFileModificationDate ofItemAtPath:path error:nil];
}
+ (BOOL)setModifyTime:(NSDate *)date ofItemAtPath:(NSString *)path  error:(NSError **)error NS_AVAILABLE(10_5, 2_0)
{
    return [self setAttribute:date forKey:NSFileModificationDate ofItemAtPath:path error:error];
}

#pragma mark - files
+ (NSArray *)childrenAtPath:(NSString *)path
{
    if(path == nil) return nil;
    const char *folderPath = [path cStringUsingEncoding:NSUTF8StringEncoding];

    NSMutableArray *files = SAFE_ARC_AUTORELEASE([[NSMutableArray alloc]init]);
    
    DIR* dir = opendir(folderPath);
    if (dir == NULL) return nil;
    struct dirent* child;
    while ((child = readdir(dir))!=NULL) {
        
        if(
           (child->d_name[0] == '.' && child->d_name[1] == 0) || // 忽略目录 .
           (child->d_name[0] == '.' && child->d_name[1] == '.' && child->d_name[2] == 0) // 忽略目录 ..
           ) continue;
        
        [files addObject:[NSString stringWithUTF8String:child->d_name]];
    }
    
    closedir(dir);
    return files;
}

+ (NSArray *)filesAtPath:(NSString *)path
{
    if(path == nil) return nil;
    const char *folderPath = [path cStringUsingEncoding:NSUTF8StringEncoding];
    NSMutableArray *files = SAFE_ARC_AUTORELEASE([[NSMutableArray alloc]init]);
    DIR* dir = opendir(folderPath);
    if (dir == NULL) return nil;
    struct dirent* child;
    while ((child = readdir(dir))!=NULL) {
        if (child->d_type == DT_DIR && (
                                        (child->d_name[0] == '.' && child->d_name[1] == 0) || // 忽略目录 .
                                        (child->d_name[0] == '.' && child->d_name[1] == '.' && child->d_name[2] == 0) // 忽略目录 ..
                                        )) continue;
        
        //子文件名
        if (child->d_type == DT_REG)
        {
            [files addObject:[NSString stringWithUTF8String:child->d_name]];
        }
    }
    
    closedir(dir);
    return files;
}

+ (BOOL)isExist:(NSString *)path isDirectory:(BOOL)isDirectory
{
    NSFileManager* fm = [NSFileManager defaultManager];
    BOOL bIsDir = NO;
	return ([fm fileExistsAtPath:path isDirectory:&bIsDir] && (bIsDir == isDirectory));
}

// 新建一个目录或文件
+ (BOOL)newItem:(NSString *)path error:(NSError **)error isDirectory:(BOOL)isDirectory force:(BOOL)shouldForce NS_AVAILABLE(10_5, 2_0)
{
    
    if(path == nil) return NO;
    
    NSFileManager *fm = [NSFileManager defaultManager];

    if (shouldForce) {
        // 强制新建, 先删除旧的, 再新建
        if ([fm fileExistsAtPath:path isDirectory:NULL]) {
            [fm removeItemAtPath:path error:nil];
        }
    }
    else {
        BOOL bIsDir = isDirectory;
        if ([fm fileExistsAtPath:path isDirectory:&bIsDir] && (bIsDir == isDirectory)) {
            
            // 存在
            return YES;
            
        } else if(bIsDir != isDirectory) {
            // 存在但类型不对
            [fm removeItemAtPath:path error:nil];
        }
    }
    
    // 创建
    if (isDirectory) {
        return [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    else {

        // 上级目录必须要存在
        [self newItem:[path stringByDeletingLastPathComponent] error:error isDirectory:YES force:NO];
        
        return [fm createFileAtPath:path contents:nil attributes:nil];
    }
}

+ (BOOL)newFolder:(NSString *)path error:(NSError **)error force:(BOOL)shouldForce NS_AVAILABLE(10_5, 2_0)
{
    return [self newItem:path error:error isDirectory:YES force:shouldForce];
}

+ (BOOL)newFolder:(NSString *)path force:(BOOL)shouldForce NS_AVAILABLE(10_5, 2_0)
{
    return [self newItem:path error:nil isDirectory:YES force:shouldForce];
}

+ (BOOL)newFile:(NSString *)path force:(BOOL)shouldForce NS_AVAILABLE(10_5, 2_0)
{
    return [self newItem:path error:nil isDirectory:NO force:shouldForce];
}

+ (NSOutputStream *)outputStreamToFileAtPath:(NSString *)path append:(BOOL)shouldAppend
{
    if(path == nil) return nil;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if(shouldAppend)
    {
        // is here ?
        BOOL bIsDir = NO;
        if([fm fileExistsAtPath:path isDirectory:&bIsDir] && !bIsDir)
        {
            return [NSOutputStream outputStreamToFileAtPath:path append:YES];
        }
    }
    
    // 不追加，原文件删除
    [self newFile:path force:YES];
	return [NSOutputStream outputStreamToFileAtPath:path append:NO];
}

+ (BOOL)copyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath force:(BOOL)shouldForce NS_AVAILABLE(10_5, 2_0)
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 强制拷贝, 已存在, 删除, 拷贝 --- 既然存在, 就无需检查其上级目录了
    if (shouldForce && [fm fileExistsAtPath:dstPath isDirectory:NULL]) {
        [fm removeItemAtPath:dstPath error:nil];
        return [[NSFileManager defaultManager] copyItemAtPath:srcPath toPath:dstPath error:nil];
    }
    else if(![fm fileExistsAtPath:dstPath isDirectory:NULL])
    {
        // 目标已存在时操作会失败 --- 上级目录必须存在
        if([self newFolder:[dstPath stringByDeletingLastPathComponent] error:nil force:NO])
        {
            return [fm copyItemAtPath:srcPath toPath:dstPath error:nil];
        }
    }

    return NO;
}
+ (BOOL)copyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError **)error NS_AVAILABLE(10_5, 2_0)
{
    return [[NSFileManager defaultManager] copyItemAtPath:srcPath toPath:dstPath error:error];
}

+ (BOOL)moveItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath force:(BOOL)shouldForce NS_AVAILABLE(10_5, 2_0)
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 强制拷贝, 已存在, 删除, 拷贝 --- 既然存在, 就无需检查其上级目录了
    if (shouldForce && [fm fileExistsAtPath:dstPath isDirectory:NULL]) {
        [fm removeItemAtPath:dstPath error:nil];
        return [[NSFileManager defaultManager] moveItemAtPath:srcPath toPath:dstPath error:nil];
    }
    else if(![fm fileExistsAtPath:dstPath isDirectory:NULL])
    {
        // 目标已存在时操作会失败 --- 上级目录必须存在
        if([self newFolder:[dstPath stringByDeletingLastPathComponent] error:nil force:NO])
        {
            return [fm moveItemAtPath:srcPath toPath:dstPath error:nil];
        }
    }
    
    return NO;
}
+ (BOOL)moveItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError **)error NS_AVAILABLE(10_5, 2_0)
{
    return [[NSFileManager defaultManager] moveItemAtPath:srcPath toPath:dstPath error:error];
}

+ (BOOL)removeItemAtPath:(NSString *)path NS_AVAILABLE(10_5, 2_0)
{
    NSFileManager* fm = [NSFileManager defaultManager];

    return [fm fileExistsAtPath:path] && [fm removeItemAtPath:path error:nil];
}

+ (BOOL)removeItemAtPath:(NSString *)path error:(NSError **)error NS_AVAILABLE(10_5, 2_0)
{
    return [[NSFileManager defaultManager] removeItemAtPath:path error:error];
}

+ (NSString *)lowercaseExtensionForPath:(NSString *)path
{
    NSString* ext = [path pathExtension];
    
    return (ext ? [[path stringByDeletingPathExtension] stringByAppendingPathExtension:[ext lowercaseString]] : path);
}

#pragma mark write


#pragma mark read

+ (NSDictionary *)calcBlocksOfFile:(NSString *)path withBlockSize:(NSInteger)blockSize
{
    FILE* fp = fopen([path UTF8String], "rb");
    if (fp == NULL)
        return nil;

    NSDictionary *dict = [self calcBlocksWithSize:blockSize usingReadBlock:^(uint8_t *buf, long offset, NSUInteger length, int *realReadLength) {
        *realReadLength = fread(buf, 1, length, fp);
    }];
    
    fclose(fp), fp = NULL;
    
    return dict;
}

+ (NSData *)readDataOfFile:(NSString *)path fromOffset:(long)offset size:(int)size
{
    FILE* fp = fopen([path UTF8String], "rb");
    if (fp == NULL)
        return nil;

    fseek(fp,offset,SEEK_SET);

    NSData *data = [WYFileManager readDataFromOffset:offset size:size usingReadBlock:^(uint8_t *buf, long offset, NSUInteger length, int *realReadLength) {
        *realReadLength = fread(buf, 1, length, fp);
    }];
    
    fclose(fp), fp = NULL;
    
    return data;
}

#define READ_SIZE (64 * WY_STORAGE_KB) // 64kb every read op.
+ (NSDictionary *)calcBlocksWithSize:(NSInteger)blockSize usingReadBlock:(WYReadBlock)readBlock
{
    NSMutableDictionary *dictResult = [NSMutableDictionary dictionary];
    @autoreleasepool {
        
        __block CC_SHA1_CTX file_sha1;
        CC_SHA1_Init(&file_sha1);
        __block CC_MD5_CTX file_md5;
        CC_MD5_Init(&file_md5);
        
        int readSize = READ_SIZE; // 4k each read
        int blockIndex = 0;
        int offset = 0;
        BOOL hasByte = YES;
        
        NSMutableArray *blocks = [NSMutableArray array];
        
        // read & make blocks
        while (hasByte) {
            
            // init a block read params
            int readRealSize = readSize;
            int readInBlock = 0;// mark as block
            
            __block CC_SHA1_CTX block_sha1;
            CC_SHA1_Init(&block_sha1);
            __block CC_MD5_CTX block_md5;
            CC_MD5_Init(&block_md5);
            while (1) {
                
                unsigned char * buf = (unsigned char *)malloc(readRealSize);
                //                int nRead = fread(buf, 1, readRealSize, fp);
                //                int nRead = [rep getBytes:buf fromOffset:offset length:readRealSize error:&err];
                int nRead = -1;
                readBlock(buf, offset, readRealSize, &nRead);
                
                if (nRead > 0)
                {
                    CC_SHA1_Update(&block_sha1, buf, nRead);
                    CC_SHA1_Update(&file_sha1, buf, nRead);
                    CC_MD5_Update(&block_md5, buf, nRead);
                    CC_MD5_Update(&file_md5, buf, nRead);
                    offset += nRead;
                    readInBlock += nRead;
                    if(readInBlock < blockSize)
                    {
                        // to keep next read not flow current block
                        readRealSize = MIN(readSize,blockSize - readInBlock);
                    }
                }
                
                free(buf);
                // end of file
                if (nRead < readRealSize)
                {
                    hasByte = NO;
                    break;
                }
                if(readInBlock >= blockSize)
                {
                    // block has full
                    break;
                }
            }
            
            // deal one block
            
            ++blockIndex;
            
            // get block's sha1 & MD5
            unsigned char sha1[CC_SHA1_DIGEST_LENGTH];
            CC_SHA1_Final(sha1, &block_sha1);
            
            unsigned char md5[CC_MD5_DIGEST_LENGTH];
            CC_MD5_Final(md5, &block_md5);
            
            //save block info
            NSMutableDictionary *dictBlock = [NSMutableDictionary dictionary];
            SAFE_SET_DICT(dictBlock,[WYDigest SHA1FromBytes:sha1],@"sha1");
            SAFE_SET_DICT(dictBlock,[WYDigest MD5FromBytes:md5],@"md5");
            SAFE_SET_DICT(dictBlock,[WYDigest MD5FromBytes:md5],@"md5");
            SAFE_SET_DICT_INT(dictBlock,readInBlock,@"size");
            SAFE_SET_DICT_INT(dictBlock,(offset - readInBlock),@"offset");

            [blocks addObject:dictBlock];
        }
        
        // get file's sha1 & MD5
        unsigned char sha1f[CC_SHA1_DIGEST_LENGTH];
        CC_SHA1_Final(sha1f, &file_sha1);

        SAFE_SET_DICT(dictResult,[WYDigest SHA1FromBytes:sha1f],@"sha1");
        SAFE_SET_DICT(dictResult,blocks,@"block_infos");

    }
    return dictResult;
}

+ (NSData *)readDataFromOffset:(long)offset size:(int)size usingReadBlock:(WYReadBlock)readBlock
{
    // block size can't be 0 , or this upload force to be fail.
    if(size <= 0)
    {
        return nil;
    }
    
    NSMutableData *mdata = [NSMutableData data];
    
    @autoreleasepool {

        int readSize = READ_SIZE;
        int readRealSize = MIN(readSize,size);
        int readInBlock = 0;
        
        while (1) {
            
            unsigned char * buf = (unsigned char *)malloc(readRealSize);
            NSInteger nRead = -1;
            readBlock(buf, offset, readRealSize, &nRead);
            if (nRead > 0)
            {
                [mdata appendBytes:buf length:readRealSize];
                free(buf);
                
                // end
                if(nRead < readRealSize)
                {
                    break;
                }
                
                // block has full
                readInBlock += nRead;
                if(readInBlock >= size)
                {
                    break;
                }
                
                offset += nRead;
                // to keep next read not flow current block
                readRealSize = MIN(readSize,size - readInBlock);
            }
            else
            {
                free(buf);
                break;
            }
        }
    }
    
    return mdata;
}

@end
//+ (BOOL)saveData:(NSData *)data toFile:(NSString *)path
//{
//    if (nil == data || nil == path) {
//        return NO;
//    }
//
//    return [data writeToFile:path atomically:YES];
//}
///** 将 NSData写入指定文件
// *
// * @param path 文件全路径
// *
// * @return 写入成功 YES / 否则 NO
// */
//+ (BOOL)saveData:(NSData *)data toFile:(NSString *)path;

