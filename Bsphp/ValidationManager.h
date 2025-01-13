//
//  ValidationManager.h
//  myBsphp
//
//  Created by 十三哥 on 2025/1/11.
//

#import <Foundation/Foundation.h>
#import "AppInfo.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ValidationState) {
    ValidationStateInitial,           // 1初始化
    ValidationStateCheckNetwork,      // 2检查网络
    ValidationStateGetBSphpSeSsL,     // 3获取 BSphpSeSsL
    ValidationStateGetRemoteConfig,   // 4获取远程配置信息
    ValidationStateGetDeviceCode,     // 5获取设备码
    ValidationStateTrialMode,         // 6试用模式
    ValidationStateVerifyLicense,     // 7验证卡密
    ValidationStateVerifyUnbind,      // 8解绑机器
    ValidationStateVerifyBan,         // 9黑名单
    ValidationStateHeartbeat,         // 10心跳检测
    ValidationStateShowAlert,         // 11显示弹窗
    ValidationStateLocalVerify,       // 12本地验证
    ValidationStateTimeVerify,        // 13定时验证
    ValidationStateDisplayInputBox,   // 14显示验证输入框
    ValidationStateDisplayGongGao,    // 15显示公告
    ValidationStateVersionVerification,    // 16版本检测
    ValidationStateCheckDeviceCodeMatch,    // 17判断机器码一致
    ValidationStateDisplayExpTimeAlear,    // 18显示到期时间弹窗
    ValidationStateFinished           // 19完成
};

@interface ValidationManager : NSObject

@property (nonatomic,strong) NSDictionary * baseDict;
@property (nonatomic,strong) AppInfo * appInfo;
//本机机器码
@property (nonatomic,strong) NSString * deviceCode;
//服务器返回的机器码
@property (nonatomic,strong) NSString * seversUDID;
@property (nonatomic,strong) NSString * licenseKey;

@property (nonatomic, assign) ValidationState currentState; // 当前状态
@property (nonatomic, assign) BOOL isSuccess; // 验证成功

@property (nonatomic, strong) NSMutableArray *alertQueue; // 弹窗队列


+ (instancetype)sharedManager;

- (void)startValidation; // 启动验证


@end

NS_ASSUME_NONNULL_END
