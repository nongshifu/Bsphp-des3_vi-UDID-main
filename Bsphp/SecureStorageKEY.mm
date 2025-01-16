//
//  SecureStorage.m
//  Bsphp
//
//  Created by 十三哥 on 2025/1/16.
//

#import "SecureStorageKEY.h"
#import <Security/Security.h>

@implementation SecureStorageKEY

#pragma mark - 获取 Bundle Identifier

/**
 获取应用程序的 Bundle Identifier
 */
+ (NSString *)getBundleIdentifier {
    return [[NSBundle mainBundle] bundleIdentifier];
}

#pragma mark - Keychain 相关方法

/**
 存储对象到钥匙串
 
 @param object 要存储的对象
 @param key 存储的键
 @return 是否存储成功
 */
+ (BOOL)setKeychainObject:(id)object forKey:(NSString *)key {
    if (!key || !object) {
        return NO;
    }
    
    // 将对象序列化为 NSData
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:YES error:nil];
    if (!data) {
        return NO;
    }
    
    // 获取 Bundle Identifier 作为 serviceName
    NSString *serviceName = [self getBundleIdentifier];
    
    // 构造查询字典
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: serviceName,
        (__bridge id)kSecAttrAccount: key,
        (__bridge id)kSecValueData: data
    };
    
    // 先删除已有的数据
    SecItemDelete((__bridge CFDictionaryRef)query);
    
    // 添加新数据
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    return status == errSecSuccess;
}

/**
 从钥匙串获取对象
 
 @param key 存储的键
 @return 存储的对象，如果不存在则返回 nil
 */
+ (nullable id)keychainObjectForKey:(NSString *)key {
    if (!key) {
        return nil;
    }
    
    // 获取 Bundle Identifier 作为 serviceName
    NSString *serviceName = [self getBundleIdentifier];
    
    // 构造查询字典
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: serviceName,
        (__bridge id)kSecAttrAccount: key,
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne
    };
    
    // 查询数据
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    
    if (status == errSecSuccess && result) {
        NSData *data = (__bridge_transfer NSData *)result;
        // 将 NSData 反序列化为对象
        NSError *error = nil;
        id object = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSObject class] fromData:data error:&error];
        if (!error) {
            return object;
        }
    }
    
    return nil;
}

/**
 从钥匙串删除对象
 
 @param key 存储的键
 @return 是否删除成功
 */
+ (BOOL)removeKeychainObjectForKey:(NSString *)key {
    if (!key) {
        return NO;
    }
    
    // 获取 Bundle Identifier 作为 serviceName
    NSString *serviceName = [self getBundleIdentifier];
    
    // 构造查询字典
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: serviceName,
        (__bridge id)kSecAttrAccount: key
    };
    
    // 删除数据
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    return status == errSecSuccess || status == errSecItemNotFound;
}

#pragma mark - 统一存储方法

+ (BOOL)setObject:(id)object forKey:(NSString *)key {
    if (!key || !object) {
        return NO;
    }
    
    // 优先尝试存储到钥匙串
    BOOL keychainSuccess = [self setKeychainObject:object forKey:key];
    if (keychainSuccess) {
        return YES;
    }
    
    // 如果钥匙串存储失败，则回退到本地存储
    NSString *localKey = [NSString stringWithFormat:@"%@_%@", [self getBundleIdentifier], key];
    [[NSUserDefaults standardUserDefaults] setObject:object forKey:localKey];
    return [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (nullable id)objectForKey:(NSString *)key {
    if (!key) {
        return nil;
    }
    
    // 优先从钥匙串获取对象
    id keychainObject = [self keychainObjectForKey:key];
    if (keychainObject) {
        return keychainObject;
    }
    
    // 如果钥匙串中没有数据，则从本地获取
    NSString *localKey = [NSString stringWithFormat:@"%@_%@", [self getBundleIdentifier], key];
    return [[NSUserDefaults standardUserDefaults] objectForKey:localKey];
}

+ (BOOL)removeObjectForKey:(NSString *)key {
    if (!key) {
        return NO;
    }
    
    // 优先从钥匙串删除对象
    BOOL keychainSuccess = [self removeKeychainObjectForKey:key];
    
    // 从本地删除对象
    NSString *localKey = [NSString stringWithFormat:@"%@_%@", [self getBundleIdentifier], key];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:localKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    return keychainSuccess;
}

#pragma mark - BOOL 类型存储方法

+ (BOOL)setBool:(BOOL)value forKey:(NSString *)key {
    // 将 BOOL 转换为 NSNumber
    NSNumber *numberValue = [NSNumber numberWithBool:value];
    return [self setObject:numberValue forKey:key];
}

+ (BOOL)boolForKey:(NSString *)key {
    // 获取 NSNumber 对象
    NSNumber *numberValue = (NSNumber *)[self objectForKey:key];
    if (numberValue) {
        return [numberValue boolValue];
    }
    return NO; // 默认返回 NO
}

@end
