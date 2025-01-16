//
//  appInfo.m
//  myBsphp
//
//  Created by 十三哥 on 2025/1/11.
//

#import "AppInfo.h"



// 加密的密钥，这里简单示例，实际中可根据需求妥善保管和设置更安全的密钥
static NSString *const kEncryptionKey = @"Ysdgarsgwge4qgfaqg2gfwa";

@implementation AppInfo

// 设置东八区时区
+ (NSTimeZone *)beijingTimeZone {
    return [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
}

// 辅助函数，将NSDate类型转换为字符串，按照北京时间格式化，方便存储（这里使用自定义格式示例，可根据需求调整）
+ (NSString *)stringFromDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    formatter.timeZone = [self beijingTimeZone];
    return [formatter stringFromDate:date];
}

// 辅助函数，将字符串转换回NSDate类型（用于还原日期数据），按照北京时间解析
+ (NSDate *)dateFromString:(NSString *)dateString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    formatter.timeZone = [self beijingTimeZone];
    return [formatter dateFromString:dateString];
}

// 本地化存储函数
+ (void)saveModelToLocal:(AppInfo *)appInfo withExtensionSeconds:(NSTimeInterval)seconds {
    // 使用YYModel将模型转为字典
    NSDictionary *modelDict = [appInfo mj_keyValues];
    // 将不可变字典转为可变字典，以便后续修改元素
    NSMutableDictionary *mutableModelDict = [modelDict mutableCopy];
    // 根据传入的秒数延长下次验证时间，使用北京时间获取当前时间并进行时间计算
    NSDate *currentDate = [NSDate date];
    currentDate = [currentDate dateByAddingTimeInterval:seconds];
    appInfo.nextTime = currentDate;
    // 更新字典中的下次验证时间字段，按照北京时间格式化时间后存储
    mutableModelDict[@"nextTime"] = [self stringFromDate:currentDate];
    // 添加存储时的时间戳
    mutableModelDict[@"storageTime"] = [self stringFromDate:[NSDate date]];
    NSLog(@"更新字典中的下次验证时间字段:%@", mutableModelDict[@"nextTime"]);
    // 将可变字典转为JSON字符串
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:mutableModelDict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(@"jsonString字段:%@", jsonString);
    if (error) {
        NSLog(@"转换JSON字符串出错: %@", error.localizedDescription);
        return;
    }
    // 加密JSON字符串
    NSString *encryptedString = [DES3Util encrypt:jsonString gkey:kEncryptionKey];
    // 使用NSUserDefaults存储加密后的字符串
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:encryptedString forKey:BS_LOCAL_SAVE_KEY];
    [userDefaults synchronize];
}

// 读取模型并判断是否超过时间以及是否到期的函数，通过闭包返回结果
+ (void)readModelAndCheckTimeWithCompletion:(void (^)(BOOL needVerify, AppInfo * _Nullable appInfo, BOOL isExpired))completion {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *encryptedString = [userDefaults objectForKey:BS_LOCAL_SAVE_KEY];
    if (encryptedString) {
        // 解密字符串
        NSString *decryptedString = [DES3Util decrypt:encryptedString gkey:kEncryptionKey];
        if (decryptedString) {
            // 将JSON字符串转为字典
            NSError *error;
            NSMutableDictionary *modelDict = [NSJSONSerialization JSONObjectWithData:[decryptedString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
            if (!error) {
                // 更新 storageTime 为当前时间
                modelDict[@"storageTime"] = [self stringFromDate:[NSDate date]];
                
                // 重新加密并保存
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:modelDict options:NSJSONWritingPrettyPrinted error:&error];
                NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                NSString *newEncryptedString = [DES3Util encrypt:jsonString gkey:kEncryptionKey];
                [userDefaults setObject:newEncryptedString forKey:BS_LOCAL_SAVE_KEY];
                [userDefaults synchronize];
                
                // 使用YYModel将字典转为模型
                AppInfo *model = [AppInfo mj_objectWithKeyValues:modelDict];
                
                // 获取当前服务器时间
                NSDate *currentServerTime = [self fetchCurrentServerTime];
                NSLog(@"离线验证 网络接口返回时间:%@", currentServerTime);
                
                // 如果无法获取服务器时间，使用本地时间
                if (!currentServerTime) {
                    NSLog(@"离线验证 无法获取服务器时间，改成本地时间");
                    currentServerTime = [NSDate date];
                }
                
                // 检查当前服务器时间是否早于存储时的服务器时间
                NSDate *storageServerTime = [self dateFromString:modelDict[@"storageTime"]];
                NSLog(@"获取上次查询的时间点:%@",modelDict[@"storageTime"]);
                if ([currentServerTime compare:storageServerTime] == NSOrderedAscending || !modelDict[@"storageTime"]) {
                    NSLog(@"离线储存时的时间不对 可能用户修改了系统时间");
                    if (completion) {
                        completion(YES, nil, YES); // needVerify = YES, model = nil, isExpired = YES
                    }
                    return;
                }
                
                // 检查是否超过下次验证时间
                NSDate *currentDate = [self getCurrentDateInBeijingTime];
                BOOL needVerify = [currentDate compare:model.nextTime] == NSOrderedDescending;
                
                // 检查是否到期
                BOOL isExpired = NO;
                if (model.到期时间) {
                    NSDate *expireDate = [self dateFromString:model.到期时间];
                    expireDate = [self getCurrentDateInBeijingTimeForTime:expireDate];
                    isExpired = [currentDate compare:expireDate] == NSOrderedDescending;
                }
                
                // 通过闭包返回结果
                if (completion) {
                    completion(needVerify, model, isExpired);
                }
            } else {
                // 解析JSON出错
                if (completion) {
                    completion(YES, nil, NO); // needVerify = YES, model = nil, isExpired = NO
                }
            }
        } else {
            // 解密失败
            if (completion) {
                completion(YES, nil, NO); // needVerify = YES, model = nil, isExpired = NO
            }
        }
    } else {
        // 没有存储的数据
        if (completion) {
            completion(YES, nil, NO); // needVerify = YES, model = nil, isExpired = NO
        }
    }
}
// 获取当前时间并转换为北京时间对应的NSDate对象
+ (NSDate *)getCurrentDateInBeijingTime {
    NSDate *currentDate = [NSDate date];
    NSTimeZone *beijingTimeZone = [self beijingTimeZone];
    NSTimeInterval timeInterval = [beijingTimeZone secondsFromGMTForDate:currentDate];
    return [currentDate dateByAddingTimeInterval:timeInterval];
}

// 获取当前时间并转换为北京时间对应的NSDate对象
+ (NSDate *)getCurrentDateInBeijingTimeForTime:(NSDate*)currentDate {
    NSTimeZone *beijingTimeZone = [self beijingTimeZone];
    NSTimeInterval timeInterval = [beijingTimeZone secondsFromGMTForDate:currentDate];
    return [currentDate dateByAddingTimeInterval:timeInterval];
}

+ (NSDate *)fetchCurrentServerTime {
    NSString *urlString = @"https://f.m.suning.com/api/ct.do";
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *data = [NSData dataWithContentsOfURL:url];
    if (data) {
        NSError *error;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (!error) {
            NSNumber *timeStampNumber = json[@"currentTime"];
            if (timeStampNumber) {
                NSTimeInterval timeInterval = [timeStampNumber doubleValue] / 1000.0; // 将毫秒转换为秒
                return [NSDate dateWithTimeIntervalSince1970:timeInterval];
            }
        }
    }
    return nil;
}

@end
