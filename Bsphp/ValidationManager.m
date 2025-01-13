//
//  ValidationManager.m
//  myBsphp
//
//  Created by 十三哥 on 2025/1/11.
//
#import <QuickLook/QuickLook.h>
#import "ValidationManager.h"
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#include <stdio.h>
#import "Config.h"
#import <string.h>
#import <AdSupport/ASIdentifierManager.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <AdSupport/ASIdentifierManager.h>
#import "BSPHPAPI.h"
#import "SCLAlertView.h"

//是否打印
#define MY_NSLog_ENABLED YES

#define NSLog(fmt, ...) \
if (MY_NSLog_ENABLED) { \
NSString *className = NSStringFromClass([self class]); \
NSLog((@"[%s] from class[%@] " fmt), __PRETTY_FUNCTION__, className, ##__VA_ARGS__); \
}

@implementation ValidationManager

#pragma mark --- 初始化函数

+ (instancetype)sharedManager {
    static ValidationManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ValidationManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _currentState = ValidationStateInitial;
        _alertQueue = [NSMutableArray array];
        _appInfo = [BSPHPAPI sharedAPI].appInfo;
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:BS_BBTC];
    }
    return self;
}


#pragma mark --- 验证流程

//开始验证
//开始验证
- (void)startValidation {
    //进入验证环节 输入状态
    [self transitionToState:ValidationStateInitial];
    //启动定时器恢复弹窗流程
    [self startStateCheckTimer];
    // 5秒后 模拟弹出一个控制器 覆盖掉弹窗 看弹窗是否重新弹出到这个控制器顶层
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *coverViewController = [[UIViewController alloc] init];
        coverViewController.view.backgroundColor = [UIColor whiteColor];
        UIViewController *topViewController = [self topViewController];
        if ([topViewController isKindOfClass:[UIAlertController class]]) {
            // 如果当前显示的是弹窗，先关闭它
            [topViewController dismissViewControllerAnimated:YES completion:^{
                [topViewController presentViewController:coverViewController animated:YES completion:^{
                    NSLog(@"已弹出覆盖控制器");
                }];
            }];
        } else {
            // 直接显示覆盖控制器
            UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
            [rootViewController presentViewController:coverViewController animated:YES completion:nil];
        }
    });
}

//流程图
- (void)transitionToState:(ValidationState)state {
    self.currentState = state;
    switch (state) {
            //初始化
        case ValidationStateInitial:
            //启动初始化
            [self handleInitialState];
            
            break;
            //检查网络
        case ValidationStateCheckNetwork:
            [self handleCheckNetworkState];
            break;
            //获取唯一SphpSeSsL
        case ValidationStateGetBSphpSeSsL:
            [self handleGetBSphpSeSsLState];
            break;
            //获取远程配置
        case ValidationStateGetRemoteConfig:
            [self handleGetRemoteConfigState];
            break;
            //获取设备码
        case ValidationStateGetDeviceCode:
            [self handleGetDeviceCodeState];
            break;
            //试用模式
        case ValidationStateTrialMode:
            [self handleTrialModeState];
            break;
            //验证卡密
        case ValidationStateVerifyLicense:
            [self handleVerifyLicenseState];
            break;
            //解绑
        case ValidationStateVerifyUnbind:
            [self UdidUnbind];
            break;
            //验证机器码黑名单
        case ValidationStateVerifyBan:
            [self checkDeviceIsBan];
            break;
            //验证心跳
        case ValidationStateHeartbeat:
            [self handleHeartbeatState];
            break;
            //显示弹窗
        case ValidationStateShowAlert:
            [self handleShowAlertState];
            break;
            //本地验证
        case ValidationStateLocalVerify:
            [self localVerification];
            break;
            //定时器
        case ValidationStateTimeVerify:
            [self heartbeatTime];
            break;
            //显示验证输入框
        case ValidationStateDisplayInputBox:
            [self showInputAlert];
            break;
            //公告显示
        case ValidationStateDisplayGongGao:
            [self GongGaoVerification];
            break;
            //版本检测
        case ValidationStateVersionVerification:
            [self VersionVerification];
            break;
            //判断机器码是否一致
        case ValidationStateCheckDeviceCodeMatch:
            [self checkDeviceCodeMatch];
            break;
            //显示到期时间弹窗
        case ValidationStateDisplayExpTimeAlear:
            [self showExpTimeAlert];
            break;
        case ValidationStateFinished:
            //验证结束
            [self handleFinishedState];
            break;
    }
}

#pragma mark --- 功能函数

// 1. 初始化状态
- (void)handleInitialState {
    // 启动流程，进入本地验证
    [self transitionToState:ValidationStateLocalVerify];
}

//2. 检查网络状态
- (void)handleCheckNetworkState {
    NSLog(@"检查网络");
    if ([self isNetworkAvailable]) {
        // 网络正常，进入获取 BSphpSeSsL 状态
        [self transitionToState:ValidationStateGetBSphpSeSsL];
    } else {
        // 网络不可用，显示弹窗并退出
       
//        [self showAlertWithTitle:@"网络不可用" message:@"请检查网络连接" exitOnDismiss:NO];
        
    }
}

//3. 获取 BSphpSeSsL
- (void)handleGetBSphpSeSsLState {
    [[BSPHPAPI sharedAPI] getBSphpSeSsLWithCompletion:^(id response, NSError *error) {
        if (response) {
            // 获取成功，进入获取远程配置信息状态
            self.baseDict = response;
            [self transitionToState:ValidationStateGetRemoteConfig];
        } else {
            // 获取失败，显示错误弹窗
            [self showAlertWithTitle:@"错误" message:@"无法获取 BSphpSeSsL" exitOnDismiss:YES];
        }
    }];
}

//4. 获取远程配置信息
- (void)handleGetRemoteConfigState {
    [[BSPHPAPI sharedAPI] getXinxiWithCompletion:^(id response, NSError *error) {
        if (response) {
            // 解析远程配置信息
            self.appInfo = response;
            NSLog(@"解析远程配置信息:%@",self.appInfo.软件公告);
            if(self.appInfo.是否免费模式){
                //免费模式 直接弹出公告
                [self showAlertWithTitle:@"当前为免费模式" message:nil actionHandler:^{
                    [self transitionToState:ValidationStateDisplayGongGao];
                }];
                
            }else{
                //非免费模式 进入获取机器码环节
                [self transitionToState:ValidationStateGetDeviceCode];
            }
            
        } else {
            // 获取失败，显示错误弹窗
            [self showAlertWithTitle:@"错误" message:@"无法获取远程配置信息" exitOnDismiss:YES];
        }
    }];
}

//5. 获取设备码
- (void)handleGetDeviceCodeState {
    if (self.appInfo.UDID_IDFV) {
        // 使用 UDID
        NSLog(@"使用 UDID");
        [[BSPHPAPI sharedAPI] getUDIDWithCompletion:^(id response, NSError *error) {
            if (response) {
                self.deviceCode = (NSString *)response;
                NSLog(@"获取设备码成功:%@",self.deviceCode);
                [[NSUserDefaults standardUserDefaults] setObject:self.deviceCode forKey:BS_UDID];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [self transitionToState:ValidationStateVerifyBan];
            } else {
                NSLog(@"获取设备码失败:%@",error);
                [self showAlertWithTitle:@"错误" message:@"无法获取设备码" exitOnDismiss:YES];
            }
        }];
    } else {
        // 使用 IDFV
        NSLog(@"DFV");
        [[BSPHPAPI sharedAPI] getIDFVWithCompletion:^(id response, NSError *error) {
            if (response) {
                self.deviceCode = (NSString *)response;
                [[NSUserDefaults standardUserDefaults] setObject:self.deviceCode forKey:BS_UDID];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                [self transitionToState:ValidationStateVerifyBan];
            } else {
                [self showAlertWithTitle:@"错误" message:@"无法获取设备码" exitOnDismiss:YES];
            }
        }];
    }
}

//6. 试用模式
- (void)handleTrialModeState {
    if (self.appInfo.试用模式) {
        // 进入试用模式
        NSLog(@"进入试用模式");
        [[BSPHPAPI sharedAPI] shiyongWithUDID:self.deviceCode completion:^(id response, NSError *error) {
            if (response) {
                NSString *str = (NSString*)response;
                if ([str containsString:@"|1081|"]) {
                    NSLog(@"试用成功，进入验证卡密状态km:%@",self.licenseKey);
                    NSArray *arr = [response componentsSeparatedByString:@"|"];
                    //保存服务器机器码属性
                    self.seversUDID = arr[2];
                    //保存到期时间属性
                    self.appInfo.到期时间 = arr[4];
                    //储存最新卡密
                    [[NSUserDefaults standardUserDefaults] setObject:self.licenseKey forKey:BS_KAMI_KEY];
                    
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    //显示到期时间弹窗
                    [self transitionToState:ValidationStateDisplayExpTimeAlear];
                }else{
                    NSLog(@"显示输入框 使用失败：%@",str);
                    [self showAlertWithTitle:@"试用失败" message:str actionHandler:^{
                        [self transitionToState:ValidationStateDisplayInputBox];
                    }];
                    
                }
                
            } else {
                // 试用失败，显示错误弹窗
                [self showAlertWithTitle:@"试用失败" message:[NSString stringWithFormat:@"%@",error] actionHandler:^{
                    [self transitionToState:ValidationStateDisplayInputBox];
                }];
            }
        }];
    } else {
        // 跳过试用模式，直接进入验证卡密状态
        NSLog(@"跳过试用模式，直接进入验证卡密状态");
        [self transitionToState:ValidationStateVerifyLicense];
    }
}

//7 验证卡密
- (void)handleVerifyLicenseState {
    
    // 显示输入卡密的弹窗
    self.licenseKey = [[NSUserDefaults standardUserDefaults] objectForKey:BS_KAMI_KEY];
    
    if (self.licenseKey.length==0 || !self.licenseKey) {
        NSLog(@"输入为空=====");
        [self transitionToState:ValidationStateDisplayInputBox];
        //删除本地到期时间数据
        [self deleteCache];
    }else{
        // 用户输入卡密后调用验证接口
        NSLog(@"用户输入卡密后调用验证接口");
        
        [[BSPHPAPI sharedAPI] yanzhengAndUseIt:self.licenseKey completion:^(id response, NSError *error) {
            if(!response || ![response containsString:@"|1081|"] || error){
                [self deleteCache];
                // 验证失败，显示错误弹窗
                [self showAlertWithTitle:@"验证错误" message:[NSString stringWithFormat:@"%@", error ?error : response] actionHandler:^{
                    [self transitionToState:ValidationStateDisplayInputBox];
                }];
                return;
            }
            
            NSArray *arr = [response componentsSeparatedByString:@"|"];
            //保存服务器机器码属性
            self.seversUDID = arr[2];
            //保存到期时间属性
            self.appInfo.到期时间 = arr[4];
            //离线配置
            self.appInfo.软件公告 = self.appInfo.软件公告;
            //存储离线配置
            [AppInfo saveModelToLocal:self.appInfo withExtensionSeconds:[self.appInfo.逻辑A内容 floatValue]];
            //储存最新卡密
            [[NSUserDefaults standardUserDefaults] setObject:self.licenseKey forKey:BS_KAMI_KEY];
            
            [[NSUserDefaults standardUserDefaults] synchronize];
            //判断机器码是否相符
            [self transitionToState:ValidationStateCheckDeviceCodeMatch];
        }];
    }
    
    
    
}

- (void)deleteCache{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //删除本地到期时间数据
    [defaults removeObjectForKey:BS_EXP_Time];
    //删除本地卡密内容
    [defaults removeObjectForKey:BS_KAMI_KEY];
    //删除本地公告
    [defaults removeObjectForKey:BS_GG];
    //删除本地到期时间弹窗
    [defaults removeObjectForKey:BS_DQTC];
    //删除本地离线配置
    [defaults removeObjectForKey:BS_Local_Config];
    //到期弹窗
    [defaults removeObjectForKey:BS_DQTC];
    //删除版本
    [defaults removeObjectForKey:BS_BBTC];
    //删除离线缓存
    [defaults removeObjectForKey:BS_LOCAL_SAVE_KEY];
    
    //储存配置
    [defaults synchronize];
}
//8. 心跳检测
- (void)handleHeartbeatState {
    //如果是离线验证 就走离线本地验证
    if(self.appInfo.逻辑A){
        NSLog(@"心跳检测 状态机进入离线验证模式");
        [self transitionToState:ValidationStateLocalVerify];
        
    }else{
        NSLog(@"心跳检测 状态机进入联网验证模式");
        
        //启动心跳检测
        [[BSPHPAPI sharedAPI] getXinTiaoWithCompletion:^(id response, NSError *error) {
            if (response) {
                if ([response containsString:@"5031"]) {
                    NSLog(@"验证正常：%@",response);
                    self.isSuccess = YES;
                    // 心跳检测成功，进入完成状态
                    
                }else if ([response containsString:@"5030"]) {
                    self.isSuccess = NO;
                    [self deleteCache];
                    NSLog(@"验证到期：%@",response);
                    [self showAlertWithTitle:@"验证到期了" message:@"您的卡密已经到期" actionHandler:^{
                        [self transitionToState:ValidationStateGetBSphpSeSsL];
                    }];
                }else if ([response containsString:@"1085"]) {
                    self.isSuccess = NO;
                    [self deleteCache];
                    NSLog(@"验证冻结：%@",response);
                    [self showAlertWithTitle:@"冻结提示" message:@"您的卡密被管理员冻结" actionHandler:^{
                        exit(0);
                    }];
                }else if ([response containsString:@"1079"]) {
                    NSLog(@"被迫下线：%@",response);
                    [self deleteCache];
                    [self showAlertWithTitle:@"下线提示" message:@"您的卡密在其他设备登录\n或者卡密多开设备已达上限" actionHandler:^{
                        exit(0);
                    }];

                }
                
            }
        }];
        if(!self.isSuccess)return;
        //获取最新公告
        [[BSPHPAPI sharedAPI] getGongGaoWithCompletion:^(id  _Nullable response, NSError * _Nullable error) {
            if(response){
                //获取最新公告
                self.appInfo.软件公告 = (NSString*)response;
                NSLog(@"获取最新公告:%@",self.appInfo.软件公告);
                //执行公告检测
                [self transitionToState:ValidationStateDisplayGongGao];
            }
            
        }];
        [[BSPHPAPI sharedAPI] getVVWithCompletion:^(id  _Nullable response, NSError * _Nullable error) {
            if (response) {
                //获取最新版本号
                self.appInfo.软件版本号 = (NSString*)response;
                NSLog(@"获取最新版本号:%@",self.appInfo.软件版本号);
                //执行版本检核
                [self transitionToState:ValidationStateVersionVerification];
            }

        }];
    }
    
    
}

//9. 完成状态
- (void)handleFinishedState {
    // 验证完成，启动应用功能
    NSLog(@"验证完成，启动应用功能");
    self.isSuccess = YES;
    //启动心跳定时器
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self transitionToState:ValidationStateTimeVerify];
    });
}

//10.显示卡密输入框
- (void)showInputAlert {
    self.isSuccess = NO;
    // 创建弹窗
    NSString *cancelButtonTitle;
    if (self.appInfo.软件网页地址.length>0) {
        cancelButtonTitle =@"购买";
    }else{
        cancelButtonTitle =@"粘贴";
    }
    [self showAlertWithTitle:@"请输入激活码" message:nil textFieldPlaceholder:@"请输入卡密激活码" confirmButtonTitle:@"确定" cancelButtonTitle:cancelButtonTitle cancelHandler:^{
        if (self.appInfo.软件网页地址.length>0) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.appInfo.软件网页地址] options:@{} completionHandler:^(BOOL success) {
                [self transitionToState:ValidationStateDisplayInputBox];
            }];
        }
    } confirmHandler:^(NSString * _Nullable inputText) {
        self.licenseKey = inputText;
        NSLog(@"输入了卡密:%@",self.licenseKey);
        [[NSUserDefaults standardUserDefaults] setObject:self.licenseKey forKey:BS_KAMI_KEY];
        [self transitionToState:ValidationStateVerifyLicense];
    }];
    
}

//11.版本检测
- (void)VersionVerification {
    NSLog(@"开始版本检测...");
    
    // 检查是否开启了版本检测
    if (self.appInfo.验证版本) {
        NSLog(@"版本检测已开启");
        //读取是否弹窗过
        BOOL isShow = [[NSUserDefaults standardUserDefaults] boolForKey:BS_BBTC];
        if(isShow){
            [self transitionToState:ValidationStateFinished];
            return;
        }
        // 检查本地版本号与远程版本号是否一致
        if (![self.appInfo.软件版本号 isEqual:JN_VERSION]) {
            NSLog(@"本地版本号: %@, 远程版本号: %@，版本不一致，需要弹窗 是否强制更新:%d", JN_VERSION, self.appInfo.软件版本号,self.appInfo.是否强制版本更新);
            //标记为已经弹出过
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:BS_BBTC];
            
            NSString *message = [NSString stringWithFormat:@"当前版本:%@\n服务器新版:%@",JN_VERSION,self.appInfo.软件版本号];
            if(!self.appInfo.是否强制版本更新){
                [self showAlertWithTitle:@"发现新版" message:message confirmButtonTitle:@"更新" cancelHandler:^{
                    [self transitionToState:ValidationStateFinished];
                } confirmHandler:^{
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.appInfo.软件url地址] options:@{} completionHandler:^(BOOL success) {
                        if(self.appInfo.是否强制版本更新){
                            exit(0);
                        }
                        
                    }];
                }];
            }else{
                [self showAlertWithTitle:@"发现新版" message:message actionHandler:^{
                    NSLog(@"用户点击了系统弹窗的确定按钮");
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.appInfo.软件url地址] options:@{} completionHandler:^(BOOL success) {
                        if(self.appInfo.是否强制版本更新){
                            exit(0);
                        }
                        
                    }];
                }];
            }
        } else {
            [self transitionToState:ValidationStateFinished];
            NSLog(@"本地版本号: %@, 远程版本号: %@，版本一致，无需弹窗", JN_VERSION, self.appInfo.软件版本号);
        }
    } else {
        NSLog(@"版本检测未开启");
        [self transitionToState:ValidationStateFinished];
    }
    
    // 跳转到下一个状态
    NSLog(@"版本检测完成，跳转到 ValidationStateFinished 状态");
    
}

//12.公告检测
- (void)GongGaoVerification {
    NSLog(@"开始公告检测...");
    
    //如果需要弹公告 那么仅执行一次公告清除 方便后面逻辑弹出
    if (self.appInfo.公告弹窗) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:BS_GG];
        });
    }
    // 读取本地存储的公告
    NSString *benDiGogGao = [[NSUserDefaults standardUserDefaults] objectForKey:BS_GG];
    NSLog(@"本地存储的公告: %@", benDiGogGao ?: @"无");
    
    // 判断是否需要弹公告
    BOOL shouldShowAlert = NO;
    
    if (!benDiGogGao && self.appInfo.软件公告.length>0) {
        NSLog(@"本地没有存储公告，首次弹公告");
        shouldShowAlert = YES;
        // 储存最新公告
        [[NSUserDefaults standardUserDefaults] setObject:self.appInfo.软件公告 forKey:BS_GG];
        NSLog(@"已将最新公告存储到本地: %@", self.appInfo.软件公告);
    } else if (!self.appInfo.公告弹窗) {
        NSLog(@"公告弹窗验证已开启");
        
        // 检查本地公告与远程公告是否一致
        if (![self.appInfo.软件公告 isEqualToString:benDiGogGao]) {
            NSLog(@"本地公告与远程公告不一致，需要弹公告");
            shouldShowAlert = YES;
            [[NSUserDefaults standardUserDefaults] setObject:self.appInfo.软件公告 forKey:BS_GG];
            NSLog(@"已将最新公告存储到本地: %@", self.appInfo.软件公告);
        } else {
            NSLog(@"本地公告与远程公告一致，无需弹公告");
        }
    }
    
    // 如果需要弹公告
    if (shouldShowAlert) {
        NSLog(@"需要弹公告");
        [self showAlertWithTitle:@"公告" message:self.appInfo.软件公告 actionHandler:^{
            NSLog(@"用户点击了系统弹窗的确定按钮");
            [self transitionToState:ValidationStateVersionVerification];
        }];
        
    } else {
        NSLog(@"无需弹公告");
        [self transitionToState:ValidationStateVersionVerification];
    }
    
    // 跳转到下一个状态
    NSLog(@"公告检测完成，跳转到版本状态");
    
}

//13.验证机器码解绑操作
- (void)checkDeviceCodeMatch {
    NSLog(@"开始判断机器码是否一致...");
    // 判断机器码是否相符
    if (![self.seversUDID containsString:self.deviceCode]) {
        NSLog(@"机器码不一致：本机机器码 = %@, 服务器机器码 = %@", self.deviceCode, self.seversUDID);
        
        if (self.appInfo.支持解绑) {
            NSLog(@"当前支持自主解绑");
            NSString *message = [NSString stringWithFormat:@"本机机器码\n%@\n卡密绑定机器码\n%@\n当前支持自主解绑\n解绑扣除:(%ld)秒", self.deviceCode, self.seversUDID, self.appInfo.解绑扣除时间];
            
            [self showAlertWithTitle:@"绑定机器码和本机不符"
                             message:message
                  confirmButtonTitle:@"确定解绑"
                       cancelHandler:^{
                NSLog(@"用户点击了取消按钮");
                // 这里可以执行取消后的逻辑 闪退
                exit(0);
            } confirmHandler:^{
                NSLog(@"用户点击了同意解绑按钮 进入解绑流程");
                // 这里可以执行确定后的逻辑
                [self transitionToState:ValidationStateVerifyUnbind];
                
            }];
        } else {
            NSLog(@"不支持自主解绑，需联系管理员");
            NSString *message = [NSString stringWithFormat:@"本机机器码\n%@\n卡密绑定机器码\n%@\n联系管理员解绑\n解绑扣除:(%ld)秒", self.deviceCode, self.seversUDID, self.appInfo.解绑扣除时间];
            
            [self showAlertWithTitle:@"绑定机器码和本机不符"
                             message:message
                  confirmButtonTitle:@"复制解绑信息"
                       cancelHandler:^{
                NSLog(@"用户点击了取消按钮");
                // 这里可以执行取消后的逻辑
                exit(0);
            } confirmHandler:^{
                NSLog(@"用户点击了复制信息按钮");
                // 这里可以执行确定后的逻辑
                // 获取系统剪贴板
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                // 将字符串拷贝到剪贴板
                [pasteboard setString:message];
                
                [self showAlertWithTitle:@"绑定信息已复制" message:@"联系管理员解绑" exitOnDismiss:YES];
            }];
        }
    } else {
        NSLog(@"机器码一致：本机机器码 = %@, 服务器机器码 = %@", self.deviceCode, self.seversUDID);
        //进入到期时间弹窗逻辑
        [self transitionToState:ValidationStateDisplayExpTimeAlear];
        
    }
}

//14. 显示到期时间弹窗
- (void)showExpTimeAlert{
    
    // 读取是否弹窗过
    BOOL 判断是否已经弹窗过 = [[NSUserDefaults standardUserDefaults] boolForKey:BS_DQTC];
    // 读取本地到期时间
    NSString *bd_BS_EXP_Time = [[NSUserDefaults standardUserDefaults] objectForKey:BS_EXP_Time];
    
    // 如果需要每次启动APP 显示到期时间弹窗
    if (self.appInfo.到期时间弹窗) {
        NSLog(@"每次到期时间弹窗");
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self showAlertWithTitle:@"验证成功-到期时间" message:self.appInfo.到期时间 actionHandler:^{
                // 验证成功，公告
                [self transitionToState:ValidationStateDisplayGongGao];
            }];
        });
        
        //标记为已经弹出过
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:BS_DQTC];
    } else {
        //如果不需要每次启动app都弹窗 那么就检测到期时间是否发生了变化进行弹窗
        NSLog(@"根据条件判断是否需要弹窗");
        // 如果没弹窗过或者到期时间发生变化，则弹窗
        if (!判断是否已经弹窗过 || ![bd_BS_EXP_Time isEqualToString:self.appInfo.到期时间]) {
            NSLog(@"需要弹窗：未弹窗过或到期时间发生变化");
            [self showAlertWithTitle:@"验证成功-到期时间" message:self.appInfo.到期时间 actionHandler:^{
               
                // 验证成功，公告
                [self transitionToState:ValidationStateDisplayGongGao];
            }];
            
            // 标记已弹窗
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:BS_DQTC];
        } else {
            NSLog(@"无需弹窗，直接进入心跳检测状态");
            [self transitionToState:ValidationStateDisplayGongGao];
        }
    }
    
    // 储存最新到期时间
    [[NSUserDefaults standardUserDefaults] setObject:self.appInfo.到期时间 forKey:BS_EXP_Time];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

//15.解绑
- (void)UdidUnbind{
    NSString *km = [[NSUserDefaults standardUserDefaults] objectForKey:BS_KAMI_KEY];
    [[BSPHPAPI sharedAPI] jiebang:km completion:^(id  _Nullable response, NSError * _Nullable error) {
        if (error) {
            [self showAlertWithTitle:@"解绑失败" message:[NSString stringWithFormat:@"%@",error] actionHandler:^{
                exit(0);
            }];
        }else{
            NSString *message =  (NSString*)response;
            if ([message containsString:@"成功"]) {
                [self showAlertWithTitle:@"温馨提示" message:[NSString stringWithFormat:@"%@\n当前设备信息已删除\n请勿重新激活会重新绑定\n请去新设备登录",response] actionHandler:^{
                    
                    //删除本地卡密内容
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:BS_KAMI_KEY];
                    //删除本地公告
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:BS_GG];
                    //删除本地到期时间弹窗
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:BS_DQTC];
                    //删除本地离线配置
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:BS_Local_Config];
                    
                    [self transitionToState:ValidationStateDisplayInputBox];
                }];
            }else{
                [self showAlertWithTitle:@"温馨提示" message:[NSString stringWithFormat:@"%@",response] actionHandler:^{
                    exit(0);
                }];
            }
            
        }
    }];
}

//检测设备还名单
- (void)checkDeviceIsBan{
    if (!self.appInfo.黑名单检测) return;
    NSString *udid = [[NSUserDefaults standardUserDefaults] objectForKey:BS_UDID];
    [[BSPHPAPI sharedAPI] getHMD:udid completion:^(id  _Nullable response, NSError * _Nullable error) {
        if (response) {
            NSArray *array =(NSArray *)response;
            NSLog(@"设备被拉黑-管理备注：%@",array[1]);
            [self showAlertWithTitle:@"您的设备被管理员拉黑" message:array[1] actionHandler:^{
                exit(YES);
            }];
        }else{
            NSLog(@"设备没被拉黑正常");
        }
        
    }];
    [self transitionToState:ValidationStateTrialMode];
}

//离线本地验证
- (void)localVerification {
    NSLog(@"开始离线本地验证...");
    [AppInfo readModelAndCheckTimeWithCompletion:^(BOOL needVerify, AppInfo * _Nullable model, BOOL isExpired) {
        NSLog(@"读取离线数据完成: needVerify=%d, isExpired=%d, model=%@", needVerify, isExpired, model);
        if(model) {
            self.appInfo = model;
        }
        
        if (needVerify || isExpired || !model) {
            NSLog(@"需要联网验证: needVerify=%d, isExpired=%d, model=%@", needVerify, isExpired, model);
            
            [self transitionToState:ValidationStateCheckNetwork];
        }
        //没到期 弹窗提示到期时间 因为心跳定时器也在重复调用这里 因此 只弹一次
        else if (!isExpired && model && self.appInfo.到期时间) {
            NSLog(@"离线验证成功: 到期时间=%@ 离线验证截止:%@", self.appInfo.到期时间,self.appInfo.nextTime);
            
            [self transitionToState:ValidationStateDisplayExpTimeAlear];
            
        }
    }];
}


#pragma mark --- 辅助函数-弹窗管理

//弹窗管理
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message exitOnDismiss:(BOOL)exitOnDismiss {
    
    //弹窗类型YES 就用系统弹窗 NO 就用SCLAlertView 弹窗
    if (self.appInfo.弹窗类型) {
        NSLog(@"使用系统弹窗");
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (exitOnDismiss) {
                exit(0);
            }
            [self.alertQueue removeObjectAtIndex:0];
        }];
        [alert addAction:action];
        [self.alertQueue addObject:alert];
        [self transitionToState:ValidationStateShowAlert];
    }else{
        SCLAlertView *alert = [[SCLAlertView alloc] initWithNewWindow];
        alert.title = title;
        alert.viewText.text = message;
        [alert addButton:@"确定" actionBlock:^{
            if (exitOnDismiss) {
                exit(0);
            }
            [self.alertQueue removeObjectAtIndex:0];
        }];
        [self.alertQueue addObject:alert];
        [self transitionToState:ValidationStateShowAlert];
        
    }
}

// 显示弹窗（支持传入闭包）
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message actionHandler:(void (^)(void))handler {
    if (self.appInfo.弹窗类型) {
        NSLog(@"使用系统弹窗");
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (handler) {
                handler(); // 执行传入的闭包
            }
            [self.alertQueue removeObjectAtIndex:0];
        }];
        [alert addAction:action];
        [self.alertQueue addObject:alert];
        [self transitionToState:ValidationStateShowAlert];
    } else {
        SCLAlertView *alert = [[SCLAlertView alloc] initWithNewWindow];
        alert.title = title;
        alert.viewText.text = message;
        [alert addButton:@"确定" actionBlock:^{
            if (handler) {
                handler(); // 执行传入的闭包
            }
            [self.alertQueue removeObjectAtIndex:0];
        }];
        [self.alertQueue addObject:alert];
        [self transitionToState:ValidationStateShowAlert];
    }
}

// 显示弹窗（支持传入确定按钮标题、取消回调和确定回调）
- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
          confirmButtonTitle:(NSString *)confirmButtonTitle
           cancelHandler:(void (^)(void))cancelHandler
          confirmHandler:(void (^)(void))confirmHandler {
    if (self.appInfo.弹窗类型) {
        NSLog(@"使用系统弹窗");
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        
        // 添加“取消”按钮
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            if (cancelHandler) {
                cancelHandler(); // 执行取消回调
            }
            [self.alertQueue removeObjectAtIndex:0];
        }];
        [alert addAction:cancelAction];
        
        // 添加“确定”按钮（支持自定义标题）
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:confirmButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (confirmHandler) {
                confirmHandler(); // 执行确定回调
            }
            [self.alertQueue removeObjectAtIndex:0];
        }];
        [alert addAction:confirmAction];
        
        // 将弹窗加入队列并显示
        [self.alertQueue addObject:alert];
        [self transitionToState:ValidationStateShowAlert];
    } else {
        SCLAlertView *alert = [[SCLAlertView alloc] initWithNewWindow];
        alert.title = title;
        alert.viewText.text = message;
        [alert addButton:confirmButtonTitle actionBlock:^{
            if (confirmHandler) {
                confirmHandler(); // 执行确定回调
            }
            [self.alertQueue removeObjectAtIndex:0];
        }];
        [alert addButton:@"取消" actionBlock:^{
            if (cancelHandler) {
                cancelHandler(); // 执行取消回调
            }
            [self.alertQueue removeObjectAtIndex:0];
        }];
        [self.alertQueue addObject:alert];
        [self transitionToState:ValidationStateShowAlert];
    }
}

// 显示弹窗（支持传入确定按钮标题、取消回调和确定回调）
- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
          confirmButtonTitle:(NSString *)confirmButtonTitle
         cancelButtonTitle:(NSString *)cancelButtonTitle
           cancelHandler:(void (^)(void))cancelHandler
          confirmHandler:(void (^)(void))confirmHandler {
    if (self.appInfo.弹窗类型) {
        NSLog(@"使用系统弹窗");
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        
        // 添加“取消”按钮
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            if (cancelHandler) {
                cancelHandler(); // 执行取消回调
            }
            [self.alertQueue removeObjectAtIndex:0];
        }];
        [alert addAction:cancelAction];
        
        // 添加“确定”按钮（支持自定义标题）
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:confirmButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (confirmHandler) {
                confirmHandler(); // 执行确定回调
            }
            [self.alertQueue removeObjectAtIndex:0];
        }];
        [alert addAction:confirmAction];
        
        // 将弹窗加入队列并显示
        [self.alertQueue addObject:alert];
        [self transitionToState:ValidationStateShowAlert];
    } else {
        SCLAlertView *alert = [[SCLAlertView alloc] initWithNewWindow];
        alert.title = title;
        alert.viewText.text = message;
        [alert addButton:confirmButtonTitle actionBlock:^{
            if (confirmHandler) {
                confirmHandler(); // 执行确定回调
            }
            [self.alertQueue removeObjectAtIndex:0];
        }];
        [alert addButton:cancelButtonTitle actionBlock:^{
            if (cancelHandler) {
                cancelHandler(); // 执行取消回调
            }
            [self.alertQueue removeObjectAtIndex:0];
        }];
        [self.alertQueue addObject:alert];
        [self transitionToState:ValidationStateShowAlert];
    }
}

// 显示弹窗（支持传入确定取消按钮标题、和输入框 取消回调和确定回调和输入内容回调）
- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
       textFieldPlaceholder:(NSString *)placeholder
          confirmButtonTitle:(NSString *)confirmButtonTitle
           cancelButtonTitle:(NSString *)cancelButtonTitle
              cancelHandler:(void (^)(void))cancelHandler
             confirmHandler:(void (^)(NSString * _Nullable inputText))confirmHandler {
    if (self.appInfo.弹窗类型) {
        NSLog(@"使用系统弹窗");
        // 创建弹窗
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        
        // 添加输入框
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = placeholder; // 输入框占位符
        }];
        
        // 添加“取消”按钮
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            if (cancelHandler) {
                cancelHandler(); // 执行取消回调
            }
            [self.alertQueue removeObjectAtIndex:0];// 从队列中移除当前弹窗
        }];
        [alert addAction:cancelAction];
        
        // 添加“确定”按钮
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:confirmButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.alertQueue removeObjectAtIndex:0]; // 从队列中移除当前弹窗
            // 获取输入框内容
            UITextField *textField = alert.textFields.firstObject;
            NSString *inputText = textField.text;
            
            if (confirmHandler) {
                confirmHandler(inputText); // 执行确定回调，并传入输入框内容
            }
            
        }];
        [alert addAction:confirmAction];
        
        // 将弹窗加入队列
        [self.alertQueue addObject:alert];
        
        // 如果当前没有弹窗显示，则显示弹窗
        [self transitionToState:ValidationStateShowAlert];
    } else {
        SCLAlertView *alert = [[SCLAlertView alloc] initWithNewWindow];
        alert.title = title;
        alert.viewText.text = message;
        
        // 添加输入框
        alert.shouldDismissOnTapOutside = NO;
        SCLTextView *textF = [alert addTextField:placeholder setDefaultText:nil];
        
        // 添加“取消”按钮
        if ([cancelButtonTitle containsString:@"粘贴"]) {
            [alert addButton:@"粘贴" validationBlock:^BOOL{
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                textF.text =pasteboard.string;
                return NO;
            }actionBlock:^{}];
        }else{
            [alert addButton:cancelButtonTitle actionBlock:^{
                if (cancelHandler) {
                    cancelHandler(); // 执行取消回调
                }
                [self.alertQueue removeObjectAtIndex:0];
            }];
        }
        
        
        
        // 添加“确定”按钮
        [alert addButton:confirmButtonTitle actionBlock:^{
            if (confirmHandler) {
                confirmHandler(textF.text); // 执行确定回调，并传入输入框内容
            }
            [self.alertQueue removeObjectAtIndex:0];
        }];
        
        
        // 将弹窗加入队列
        [self.alertQueue addObject:alert];
        
        // 如果当前没有弹窗显示，则显示弹窗
        [self transitionToState:ValidationStateShowAlert];
    }
}

// 处理弹窗显示状态
- (void)handleShowAlertState {
    NSLog(@"处理弹窗显示状态 self.alertQueue.count: %ld", self.alertQueue.count);
    dispatch_async(dispatch_get_main_queue(), ^{
        // 如果当前没有弹窗显示，且队列中有弹窗
        UIViewController *topViewController = [self topViewController];
        id firstAlertInQueue = self.alertQueue.firstObject;
        if ([firstAlertInQueue isKindOfClass:[UIAlertController class]]) {
            UIAlertController * alert = (UIAlertController *)self.alertQueue.firstObject;
            // 如果当前显示的视图控制器是弹窗，并且是队列中的第一个弹窗
            if ([topViewController isKindOfClass:[UIAlertController class]]) {
                UIAlertController *currentAlert = (UIAlertController *)topViewController;
                
                // 如果当前显示的弹窗是队列中的第一个弹窗，则不重新弹窗
                if (currentAlert == alert) {
                    return;
                }
            }
            // 如果当前显示的视图控制器不是弹窗，或者不是队列中的第一个弹窗，则重新显示弹窗
            UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
            [rootViewController presentViewController:alert animated:YES completion:nil];
            
        }else if ([firstAlertInQueue isKindOfClass:[SCLAlertView class]]){
            SCLAlertView * alert = (SCLAlertView *)self.alertQueue.firstObject;
            
            // 如果弹窗已经显示，则不再重复弹窗
            if (alert.isShowing) {
                return;
            }
            NSString *alertTitle = alert.title;
            SCLAlertViewStyle Style = SCLAlertViewStyleNotice;
            if([alertTitle containsString:@"请输入"]){
                Style = SCLAlertViewStyleEdit;
            }else if([alertTitle containsString:@"公告"]){
                Style = SCLAlertViewStyleNotice;
            }else if([alertTitle containsString:@"验证成功"]){
                Style = SCLAlertViewStyleSuccess;
            }else if([alertTitle containsString:@"错误"]){
                Style = SCLAlertViewStyleError;
            }else if([alertTitle containsString:@"冻结"]){
                Style = SCLAlertViewStyleError;
            }else if([alertTitle containsString:@"发现新版本"]){
                Style = SCLAlertViewStyleQuestion;
            }
            alert.isGZB = self.appInfo.验证过直播;
            [alert showTitle:alertTitle subTitle:alert.viewText.text style:Style closeButtonTitle:nil duration:0];
        }
        
        
    });
}

- (BOOL)isSCLAlertViewShowingInViewController:(UIViewController *)viewController {
    // 检查 keyWindow
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (keyWindow != nil) {
        for (UIView *subview in keyWindow.rootViewController.view.subviews) {
            if ([subview isKindOfClass:[SCLAlertView class]]) {
                return YES; // 找到了 SCLAlertView
            }
        }
    }

    // 检查传入的视图控制器
    if (viewController != nil) {
        for (UIView *subview in viewController.view.subviews) {
            if ([subview isKindOfClass:[SCLAlertView class]]) {
                return YES; // 找到了 SCLAlertView
            }
        }
    }

    return NO; // 没有找到 SCLAlertView
}

// 获取顶层视图控制器
- (UIViewController *)topViewController {
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    return topViewController;
}

// 启动状态检查定时器
- (void)startStateCheckTimer {
    [NSTimer scheduledTimerWithTimeInterval:2.0
                                    repeats:YES block:^(NSTimer * _Nonnull timer) {
        // 如果验证成功，不执行
        if (self.isSuccess || self.currentState == ValidationStateInitial || self.currentState == ValidationStateFinished) {
            return;
        }
        
        NSLog(@"如果流程未完成恢复状态: %ld", self.currentState);
        [self transitionToState:self.currentState];
        // 调用 handleShowAlertState 方法确保弹窗显示在最顶层
        [self handleShowAlertState];
    }];
}

//网络状态
- (BOOL)isNetworkAvailable {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, "www.apple.com");
    SCNetworkReachabilityFlags flags;
    BOOL success = SCNetworkReachabilityGetFlags(reachability, &flags);
    BOOL isReachable = success && (flags & kSCNetworkFlagsReachable);
    BOOL needsConnection = success && (flags & kSCNetworkFlagsConnectionRequired);
    BOOL canConnectAutomatically = success && (flags & kSCNetworkFlagsConnectionAutomatic);
    BOOL canConnectWithoutUserInteraction = canConnectAutomatically && !(flags & kSCNetworkFlagsInterventionRequired);
    BOOL isNetworkReachable = (isReachable && (!needsConnection || canConnectWithoutUserInteraction));
    CFRelease(reachability);
    
    if (isNetworkReachable) {
        NSLog(@"网络可用");
        return YES;
    } else {
        NSLog(@"网络不可用");
        return NO;
    }
    return NO;
}

//心跳定时器
- (void)heartbeatTime{
    //读取逻辑B的时间作为定时验证
    float time = [self.appInfo.逻辑B内容 floatValue];
    //时间为0 就不执行
    if (time ==0 || !self.appInfo.逻辑B内容) return;
    [NSTimer scheduledTimerWithTimeInterval:time
                                    repeats:YES block:^(NSTimer * _Nonnull timer) {
        //如果验证失败 就不会调用心跳 如果软件配置逻辑B 关掉 也不执行
        if(!self.isSuccess || !self.appInfo.逻辑B)return;
        [self transitionToState:ValidationStateHeartbeat];
    }];
}

@end
