//
//  SecureStorage.h
//  Bsphp
//
//  Created by 十三哥 on 2025/1/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SecureStorageKEY : NSObject

#pragma mark - 通用存储方法

/**
 存储对象到钥匙串或本地（优先钥匙串）
 
 @param object 要存储的对象
 @param key 存储的键
 @return 是否存储成功
 */
+ (BOOL)setObject:(id)object forKey:(NSString *)key;

/**
 从钥匙串或本地获取对象
 
 @param key 存储的键
 @return 存储的对象，如果不存在则返回 nil
 */
+ (nullable id)objectForKey:(NSString *)key;

/**
 从钥匙串或本地删除对象
 
 @param key 存储的键
 @return 是否删除成功
 */
+ (BOOL)removeObjectForKey:(NSString *)key;

#pragma mark - BOOL 类型存储方法

/**
 存储 BOOL 值到钥匙串或本地（优先钥匙串）
 
 @param value 要存储的 BOOL 值
 @param key 存储的键
 @return 是否存储成功
 */
+ (BOOL)setBool:(BOOL)value forKey:(NSString *)key;

/**
 从钥匙串或本地获取 BOOL 值
 
 @param key 存储的键
 @return 存储的 BOOL 值，如果不存在则返回 NO
 */
+ (BOOL)boolForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
