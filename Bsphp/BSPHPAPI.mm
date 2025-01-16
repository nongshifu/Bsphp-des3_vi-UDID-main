//
//  BSPHPAPI.m
//  myBsphp
//
//  Created by 十三哥 on 2025/1/11.
//

#import "BSPHPAPI.h"
#import "Config.h" // 假设你有一个网络请求工具类

#import <AdSupport/ASIdentifierManager.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <QuickLook/QuickLook.h>
#import <UIKit/UIKit.h>
#import "AppInfo.h"

#import <dlfcn.h>
#include <stdio.h>
#import "UDIDRetriever.h"
#import "SCLAlertView.h"

@implementation BSPHPAPI

+ (instancetype)sharedAPI {
    static BSPHPAPI *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[BSPHPAPI alloc] init];
        //初始化模型
        instance.appInfo = [[AppInfo alloc] init];
        
    });
    return instance;
}

// 获取 BSphpSeSsL
- (void)getBSphpSeSsLWithCompletion:(BSPHPCompletion)completion {
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    param[@"api"] = @"BSphpSeSsL.in";
    param[@"date"] = [self getSystemDate];
    param[@"md5"] = @"";
    param[@"mutualkey"] = BSPHP_MUTUALKEY;
    
    [NetTool Post_AppendURL:BSPHP_HOST parameters:param success:^(id responseObject) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        if (dict) {
            NSLog(@"BSphpSeSsL:%@",dict);
            completion(dict[@"response"][@"data"], nil);
        } else {
            completion(nil, [NSError errorWithDomain:@"BSPHPError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"解析失败"}]);
        }
    } failure:^(NSError *error) {
        completion(nil, error);
    }];
}

// 获取软件信息
- (void)getXinxiWithCompletion:(BSPHPCompletion)completion {
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    param[@"api"] = @"globalinfo.in";
    param[@"BSphpSeSsL"] = self.baseDict[@"response"][@"data"];
    param[@"date"] = [self getSystemDate];
    param[@"mutualkey"] = BSPHP_MUTUALKEY;
    param[@"appsafecode"] = [self getSystemDate];
    param[@"md5"] = @"";
    param[@"info"] = @"GLOBAL_MIAOSHU|GLOBAL_V|GLOBAL_GG|GLOBAL_WEBURL|GLOBAL_URL|GLOBAL_LOGICA|GLOBAL_LOGICINFOA|GLOBAL_LOGICB|GLOBAL_LOGICINFOB|GLOBAL_TURN";
    
    [NetTool Post_AppendURL:BSPHP_HOST parameters:param success:^(id responseObject) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        if (dict) {
            NSString *data =dict[@"response"][@"data"];
            NSLog(@"软件信息=%@",data);
            if ([data containsString:@"|"]) {
                
                NSArray *arr = [data componentsSeparatedByString:@"|"];
                NSString *miaoshu = arr[0];
                if ([miaoshu containsString:@"\n"] && miaoshu.length > 10) {
                    NSArray<NSString *> *miaos = [miaoshu componentsSeparatedByString:@"\n"];
                    for (int i = 0; i < miaos.count; i++) {
                        NSString *key = miaos[i];
                        NSLog(@"i:%d  key:%@", i, key);
                        if (key.length<4) continue;
                        BOOL status = [key rangeOfString:@"YES" options:NSCaseInsensitiveSearch].location != NSNotFound;
                        NSLog(@"status%d  key:%@", status, key);
                        // 赋值
                        switch (i) {
                            case 0:
                                self.appInfo.到期时间弹窗 = status;
                                break;
                            case 1:
                                self.appInfo.UDID_IDFV = status;
                                break;
                            case 2:
                                self.appInfo.验证版本 = status;
                                break;
                            case 3:
                                self.appInfo.验证过直播 = status;
                                break;
                            case 4:
                                self.appInfo.弹窗类型 = status;
                                break;
                            case 5:
                                self.appInfo.公告弹窗 = status;
                                break;
                            case 6:
                                self.appInfo.试用模式 = status;
                                break;
                            case 7:
                                self.appInfo.支持解绑 = status;
                                break;
                            case 8:
                                self.appInfo.黑名单检测 = status;
                                break;
                            case 9:
                                self.appInfo.是否免费模式 = status;
                                break;
                            case 10:
                                self.appInfo.是否强制版本更新 = status;
                                break;
                            case 11:
                                self.appInfo.是否三指双击显示到期时间 = status;
                                break;
                            case 12:
                                self.appInfo.是否验证特征码一致 = status;
                                break;
                                
                                
                            default:
                                break;
                        }
                    }
                    NSLog(@"info.软件描述.到期时间弹窗:%d", self.appInfo.到期时间弹窗);
                }
                
                self.appInfo.软件版本号 = arr[1];
                self.appInfo.软件公告 = arr[2];
                self.appInfo.软件网页地址 = arr[3];
                self.appInfo.软件url地址 = arr[4];
                self.appInfo.逻辑A = [arr[5] boolValue];
                self.appInfo.逻辑A内容 = arr[6];
                self.appInfo.逻辑B = [arr[7] boolValue];
                self.appInfo.逻辑B内容 = arr[8];
                self.appInfo.解绑扣除时间 = [arr[9] integerValue];
                
                
                completion(self.appInfo, nil);
            }else{
                completion(nil, [NSError errorWithDomain:@"BSPHPError" code:-1 userInfo:@{NSLocalizedDescriptionKey: data}]);
            }
            
        } else {
            completion(nil, [NSError errorWithDomain:@"BSPHPError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"解析失败"}]);
        }
    } failure:^(NSError *error) {
        completion(nil, error);
    }];
}

// 获取设备 UDID
- (void)getUDIDWithCompletion:(BSPHPCompletion)completion {
    NSString *udid = [[NSUserDefaults standardUserDefaults] objectForKey:BS_UDID];
    if (udid && udid.length>5) {
        [[NSUserDefaults standardUserDefaults] setObject:udid forKey:BS_UDID];
        [[NSUserDefaults standardUserDefaults] synchronize];
        completion(udid, nil);
    } else {
        //判断越狱ROOT注入情况下 直接读取
        static CFStringRef (*$MGCopyAnswer)(CFStringRef);
        void *gestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY);
        $MGCopyAnswer = reinterpret_cast<CFStringRef (*)(CFStringRef)>(dlsym(gestalt, "MGCopyAnswer"));
        udid=(__bridge NSString *)$MGCopyAnswer(CFSTR("SerialNumber"));
        if (udid.length>6) {
            [[NSUserDefaults standardUserDefaults] setObject:udid forKey:BS_UDID];
            [[NSUserDefaults standardUserDefaults] synchronize];
            completion(udid, nil);
            return;
        }
        
        //非越狱 不存在就读取服务器安装描述文件获取
        NSDictionary *dict = [[NSBundle mainBundle] infoDictionary];
        NSArray *urlTypes = dict[@"CFBundleURLTypes"];
        NSString *urlSchemes = nil;
        //读取APP的跳转URL
        for (NSDictionary *scheme in urlTypes) {
            urlSchemes = scheme[@"CFBundleURLSchemes"][0];
        }
        //生成随机用户ID
        NSString* suijiid = [[NSUserDefaults standardUserDefaults] objectForKey:BS_SJID];
        
        NSLog(@"suijiid=%@",suijiid);
        //不存在就储存随机生成id并且储存钥匙串
        if (suijiid.length<=5) {
            NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
            NSMutableString *randomString = [NSMutableString stringWithCapacity:15];
            for (int i = 0; i < 15; i++) {
                [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((unsigned int)[letters length])]];
            }
            NSLog(@"随机生成的码：%@", randomString);
            suijiid=[NSString stringWithFormat:@"%@",randomString];
            [[NSUserDefaults standardUserDefaults] setObject:suijiid forKey:BS_SJID];
           
        }
        
        
        //通过ID读取服务器的UDID
        NSString *requestStr = [NSString stringWithFormat:@"%@udid%@.txt",UDID_HOST,suijiid];
        NSLog(@"requestStr=%@",requestStr);
        // 创建 NSURLSession 对象
        NSURLSession *session = [NSURLSession sharedSession];
        // 创建 NSURL 对象
        NSURL *url = [NSURL URLWithString:requestStr];
        // 创建 NSURLSessionDataTask 对象
        NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                // URL 返回错误
                NSLog(@"URL 返回错误：%@", error);
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
            } else {
               
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                if ([httpResponse statusCode] == 404) {
                    NSLog(@"URL 返回 404 错误 提示用户安装UDID描述文件");
                    
                    completion(@"404服务器缓存读取错误",nil);
                   
                } else {
                    NSLog(@"URL 正常");
                    // 打印返回值非404的html字符串
                    NSString *htmlString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    NSLog(@"URL 返回的 HTML 字符串：%@", htmlString);
                    //删除换行和空格
                    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                    NSArray *strarr = [[htmlString stringByTrimmingCharactersInSet:whitespace] componentsSeparatedByString:@"|"];
                    NSLog(@"URL 返回的 strarr字符串：%@", strarr);
                    NSString * udidstr= strarr[0];
                    NSLog(@"URL 返回的 udidstr：%@", udidstr);
                    NSString*NewOld=strarr[1];
                    self.appInfo.是否新用户 = [NewOld containsString:@"新用户"];
                    NSString*heimingdan=strarr[2];
                    self.appInfo.是否被拉黑 = [heimingdan containsString:@"黑名单"];
                    
                    self.appInfo.管理员备注 = strarr[3];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (udidstr.length>5) {
                            [[NSUserDefaults standardUserDefaults] setObject:udidstr forKey:BS_UDID];
                            [[NSUserDefaults standardUserDefaults] synchronize];
                            completion(udidstr,nil);
                        }else{
                            completion(nil,nil);
                        }
                    });
                    //判断是否黑名单用户 是则拉黑提示备注内容 并且闪退
                    NSString *remohcurl = [NSString stringWithFormat:@"%@udid.php?rm=%@",UDID_HOST,suijiid];
                    NSString *htmlStr = [NSString stringWithContentsOfURL:[NSURL URLWithString:remohcurl] encoding:NSUTF8StringEncoding error:nil];
                    NSLog(@"删除UDIDhtmlStr：%@", htmlStr);
                }
            }
        }];
        
        // 启动任务
        [dataTask resume];
        
    }
}

// 获取设备 IDFV
- (void)getIDFVWithCompletion:(BSPHPCompletion)completion {
    NSString *idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    if (idfv) {
        NSLog(@"成功获取IDFV");
        completion(idfv, nil);
    } else {
        completion(nil, [NSError errorWithDomain:@"BSPHPError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"无法获取 IDFV"}]);
    }
}

// 试用模式验证
- (void)shiyongWithUDID:(NSString *)udid completion:(BSPHPCompletion)completion {
    // 实现试用模式验证的逻辑
    NSLog(@"实现试用模式验证的逻辑");
    //开始注册卡密 生成随机卡密
    
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    NSString *appsafecode = [self getSystemDate];//设置一次过期判断变量
    param[@"api"] = @"AddCardFeatures.key.ic";
    param[@"BSphpSeSsL"] = self.baseDict[@"response"][@"data"];
    param[@"date"] = [self getSystemDate];
    param[@"md5"] = @"";
    param[@"mutualkey"] = BSPHP_MUTUALKEY;
    param[@"appsafecode"] = appsafecode;//这里是防封包被劫持的验证，传什么给服务器返回什么，返回不一样说明中途被劫持了
    param[@"maxoror"] = udid;//多开控制
    param[@"key"] = udid;//必填,建议让用户填QQ或者联系方式这样方便联系用户(自己想象)
    param[@"carid"] = udid;//必填,建议让用户填QQ或者联系方式这样方便联系用户(自己想象)
    
    [NetTool Post_AppendURL:BSPHP_HOST parameters:param success:^(id responseObject) {
        NSError *error;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:&error];
        if (dict) {
            NSString*dataString = dict[@"response"][@"data"];
            NSLog(@"dataString=%@",dataString);
            completion(dataString,nil);
            
        }else{
            completion(nil,error);
        }
    } failure:^(NSError *error) {
        NSLog(@"注册失败：%@",error);
        completion(nil,error);
    }];
    
}

// 验证授权码
- (void)yanzhengAndUseIt:(NSString *)licenseKey completion:(BSPHPCompletion)completion {
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    param[@"api"] = @"login.ic";
    param[@"BSphpSeSsL"] = self.baseDict[@"response"][@"data"];
    param[@"date"] = [self getSystemDate];
    param[@"md5"] = @"";
    param[@"mutualkey"] = BSPHP_MUTUALKEY;
    param[@"icid"] = licenseKey;
    param[@"icpwd"] = @"";
    param[@"key"] = [[NSUserDefaults standardUserDefaults] objectForKey:BS_UDID];
    param[@"maxoror"] = [[NSUserDefaults standardUserDefaults] objectForKey:BS_UDID];
    param[@"appsafecode"] = [self getSystemDate];
    
    [NetTool Post_AppendURL:BSPHP_HOST parameters:param success:^(id responseObject) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        if (dict) {
            NSString*dataString = dict[@"response"][@"data"];
            NSLog(@"授权返回:%@",dataString);
            completion(dataString, nil);
        } else {
            NSLog(@"授权返回!dict:");
            completion(nil, [NSError errorWithDomain:@"BSPHPError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"解析失败"}]);
        }
    } failure:^(NSError *error) {
        NSLog(@"授权返回!error:%@",error);
        completion(nil, error);
    }];
}

// 心跳检测
- (void)getXinTiaoWithCompletion:(BSPHPCompletion)completion {
    // 实现心跳检测的逻辑
    NSLog(@"现心跳检测的逻辑");
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    NSString *appsafecode = [self getSystemDate];//设置一次过期判断变量
    param[@"api"] = @"timeout.ic";
    param[@"BSphpSeSsL"] = self.baseDict[@"response"][@"data"];
    param[@"date"] = [self getSystemDate];
    param[@"md5"] = @"";
    param[@"mutualkey"] = BSPHP_MUTUALKEY;
    param[@"appsafecode"] = appsafecode;//这里是防封包被劫持的验证，传什么给服务器返回什么，返回不一样说明中途被劫持了
    [NetTool Post_AppendURL:BSPHP_HOST parameters:param success:^(id responseObject) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        if (dict) {
            NSString*data = dict[@"response"][@"data"];
            completion(data, nil);
        }else{
            completion(nil, nil);
        }
    } failure:^(NSError *error) {
        completion(nil, nil);
    }];
    
}

// 获取公告
- (void)getGongGaoWithCompletion:(BSPHPCompletion)completion {
    // 实现获取公告的逻辑
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    param[@"api"] = @"gg.in";
    param[@"BSphpSeSsL"] = self.baseDict[@"response"][@"data"];
    param[@"date"] = [self getSystemDate];
    param[@"mutualkey"] = BSPHP_MUTUALKEY;
    param[@"appsafecode"] = [self getSystemDate];
    param[@"md5"] = @"";
    
    [NetTool Post_AppendURL:BSPHP_HOST parameters:param success:^(id responseObject) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        if (dict) {
            NSLog(@"BSphpSeSsL:%@",dict);
            completion(dict[@"response"][@"data"], nil);
        } else {
            completion(nil, [NSError errorWithDomain:@"BSPHPError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"解析失败"}]);
        }
    } failure:^(NSError *error) {
        completion(nil, error);
    }];
    
    
}

// 获取版本信息
- (void)getVVWithCompletion:(BSPHPCompletion)completion {
    // 实现获取版本信息的逻辑
  
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    param[@"api"] = @"v.in";
    param[@"BSphpSeSsL"] = self.baseDict[@"response"][@"data"];
    param[@"date"] = [self getSystemDate];
    param[@"mutualkey"] = BSPHP_MUTUALKEY;
    param[@"appsafecode"] = [self getSystemDate];
    param[@"md5"] = @"";
    
    [NetTool Post_AppendURL:BSPHP_HOST parameters:param success:^(id responseObject) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        if (dict) {
            NSLog(@"BSphpSeSsL:%@",dict);
            completion(dict[@"response"][@"data"], nil);
        } else {
            completion(nil, [NSError errorWithDomain:@"BSPHPError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"解析失败"}]);
        }
    } failure:^(NSError *error) {
        completion(nil, error);
    }];
}

//解绑
- (void)jiebang:(NSString*)km completion:(BSPHPCompletion)completion {
    //参数开始组包
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    NSString *appsafecode = [self getSystemDate];//设置一次过期判断变量
    param[@"api"] = @"setcarnot.ic";
    param[@"BSphpSeSsL"] = self.baseDict[@"response"][@"data"];//ssl是获取的全局参数，app第一次启动时候获取的
    param[@"date"] = [self getSystemDate];
    param[@"md5"] = @"";
    param[@"mutualkey"] = BSPHP_MUTUALKEY;
    param[@"icid"] = km;
    param[@"icpwd"] = @"";
    param[@"appsafecode"] = appsafecode;//这里是防封包被劫持的验证，传什么给服务器返回什么，返回不一样说明中途被劫持了
    [NetTool Post_AppendURL:BSPHP_HOST parameters:param success:^(id responseObject) {
        NSError *error;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:&error];
        if (dict) {
            //这里是防封包被劫持的验证，传什么给服务器返回什么，返回不一样说明中途被劫持了
            if(![dict[@"response"][@"appsafecode"] isEqualToString:appsafecode]){
                dict[@"response"][@"data"] = @"-2000";
                completion(@"封包倍劫持了",nil);
                return;
            }
            NSString *dataString = dict[@"response"][@"data"];
            NSLog(@"解绑操作 返回内容：%@",dataString);
            completion(dataString,nil);
            
        }else{
            completion(nil,error);
        }
        
        
    } failure:^(NSError *error) {
        completion(nil,error);
        
    }];
    
}

//黑名单检测
-(void)getHMD:(NSString*)udid completion:(BSPHPCompletion)completion{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //请求的url
        NSString *requestStr = [NSString stringWithFormat:@"%@udid.php?code=%@",UDID_HOST,udid];
        NSString *htmlStr = [NSString stringWithContentsOfURL:[NSURL URLWithString:requestStr] encoding:NSUTF8StringEncoding error:nil];
        if ([htmlStr containsString:@"黑名单用户"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSArray *strarr = [htmlStr componentsSeparatedByString:@"|"];
                self.appInfo.是否被拉黑 = YES;
                self.appInfo.管理员备注 = strarr[1];
                completion(strarr,nil);
            });
        }else{
            completion(nil,nil);
        }
        
    });
    
}

// 获取系统时间
- (NSString *)getSystemDate {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd#HH:mm:ss";
    return [formatter stringFromDate:[NSDate date]];
}

- (NSString *)generateRandomString{
    // 定义包含所有字母的字符集
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:25];
    
    for (int i = 0; i < 25; i++) {
        // 随机选择一个字母
        u_int32_t randomIndex = arc4random_uniform((u_int32_t)[letters length]);
        unichar randomChar = [letters characterAtIndex:randomIndex];
        [randomString appendFormat:@"%C", randomChar];
    }
    
    return [randomString copy];
}
@end
