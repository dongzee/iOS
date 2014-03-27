//
//  WYDigest.m
//  WYCore
//
//  Created by wanglidong on 13-4-27.
//  Copyright (c) 2013年 wy. All rights reserved.
//

#import "WYDigest.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonCryptor.h> 
#import "zlib.h"

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
 * 工具宏 : 数学
 ******************************************************/
//交换两个数（类型任意）
#ifndef SWAP
#define SWAP(A,B) ({ __typeof__(*(A)) __t = (*(A)); *A = *B; *B = __t; })
#endif

@implementation WYDigest
+ (uint32_t)CRC32:(NSData *)data
{
    uLong crc = crc32(0L, Z_NULL, 0);
    crc = crc32(crc, [data bytes], [data length]);
    return crc;
}

+ (NSString *)SHA1:(NSString *)string
{
    const char *cstr = [string cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:string.length];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
}

+ (NSString *)MD5:(NSString *)string
{
    if(string == nil) return nil;
    
    const char *cStr = [string UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
}

+ (NSString *)SHA1FromBytes:(const unsigned char *)sha1
{
    NSMutableString *str_sha1 = [[NSMutableString alloc]init];
    for (size_t i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
    {
        [str_sha1 appendFormat:@"%02x",sha1[i]];
    }

    return SAFE_ARC_AUTORELEASE(str_sha1);
}
+ (NSString *)MD5FromBytes:(const unsigned char *)md5
{
    NSMutableString *str_md5 = [[NSMutableString alloc]init];
    for (size_t i = 0; i< CC_MD5_DIGEST_LENGTH; ++i) {
        [str_md5 appendFormat:@"%02x",md5[i]];
    }
    return SAFE_ARC_AUTORELEASE(str_md5);
}

+ (NSData *)HMACSHA1EncodedData:(NSData *)data withKey:(NSString *)key
{
	NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    void *buffer = malloc(CC_SHA1_DIGEST_LENGTH);
    CCHmac(kCCHmacAlgSHA1, [keyData bytes], [keyData length], [data bytes], [data length], buffer);
	
	NSData *encodedData = [NSData dataWithBytesNoCopy:buffer length:CC_SHA1_DIGEST_LENGTH freeWhenDone:YES];
    return encodedData;
}

+ (NSData *)HMACSHA1EncodedString:(NSString *)string withKey:(NSString *)key
{
    return [self HMACSHA1EncodedData:[string dataUsingEncoding:NSUTF8StringEncoding] withKey:key];
}

+ (NSString *)ARC4Encrypt:(NSString *)string withKey:(NSString *)key
{
    // init
	int i = 0;
	int j = 0;
	unsigned char s[256];
    //set up array with 256 elements, numbered 0 through 255
	for (int a = 0; a < 256; a++)
	{
		s[a] = a;
	}
	/* set up array with 256 elements, numbered 0 through 255 for key string*/
	for (int b = 0; b < 256; b++)
	{
		j = (j + s[b] + [key characterAtIndex:(b % key.length)]) % 256;
		
        //	swap
        SWAP(&s[b],&s[j]);
	}
	i = j = 0;
    
    NSString *stringToEncrypt = string;
    NSMutableString *rfunc = SAFE_ARC_AUTORELEASE([[NSMutableString alloc] init]);

    int iStringLength = [stringToEncrypt length]; // declare a variable to take the length of the incoming string
	unsigned char k;
	unsigned char t;
	// loop to grab all characters one at a time and send them through the array
	for (int c = 0; c < iStringLength; c++){
        
        i = (i + 1) % 256;
        j = (j + s[i]) % 256;
        
        SWAP(&s[i],&s[j]);
        k = abs (s[(s[i] + s[j]) % 256]);
        
		t = [stringToEncrypt characterAtIndex:c]; // a temp variable to store the last taken in character from the array
		[rfunc appendFormat:@"%02x", (unsigned char)(k ^ t)]; // xor the characters, then into hexadecimal
		//[rfunc appendString:@" "]; // with spaces
	}
    
	return rfunc; // return the hexadecimal string with spaces
}

+ (NSData *)RC4EncryptDecrypt:(NSData *)data withKey:(unsigned char *)key operation:(CCOperation)operation
{
    
    // encode/decode
    size_t len = strlen((char *)key);
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesOut = 0;
    CCCryptorStatus cryptStatus = CCCrypt(operation,
                                          kCCAlgorithmRC4,
                                          kCCOptionECBMode,
                                          key,
                                          len,
                                          NULL,
                                          [data bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesOut);
    
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer
                                    length:numBytesOut
                              freeWhenDone:YES];
    }
    
    free(buffer);
    return nil;
}

+ (NSData *)RC4Encrypt:(NSData *)data withKey:(unsigned char *)key {
    return [self RC4EncryptDecrypt:data withKey:key operation:kCCEncrypt];
}

+ (NSData *)RC4Decrypt:(NSData *)data withKey:(unsigned char *)key {
    return [self RC4EncryptDecrypt:data withKey:key operation:kCCDecrypt];
}

@end

