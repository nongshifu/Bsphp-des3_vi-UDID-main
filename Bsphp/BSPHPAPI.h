//
//  BSPHPAPI.h
//  myBsphp
//
//  Created by 十三哥 on 2025/1/11.
//

#import <Foundation/Foundation.h>
#import "AppInfo.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^BSPHPCompletion)(id _Nullable response, NSError * _Nullable error);

@interface BSPHPAPI : NSObject



+ (instancetype)sharedAPI;

@property (nonatomic,strong) NSDictionary * baseDict;
@property (nonatomic,strong) AppInfo *appInfo;

// 获取 BSphpSeSsL
- (void)getBSphpSeSsLWithCompletion:(BSPHPCompletion)completion;

// 获取软件信息
- (void)getXinxiWithCompletion:(BSPHPCompletion)completion;

// 获取设备 UDID
- (void)getUDIDWithCompletion:(BSPHPCompletion)completion;

// 获取设备 IDFV
- (void)getIDFVWithCompletion:(BSPHPCompletion)completion;

// 试用模式验证
- (void)shiyongWithUDID:(NSString *)udid completion:(BSPHPCompletion)completion;

// 验证授权码
- (void)yanzhengAndUseIt:(NSString *)licenseKey completion:(BSPHPCompletion)completion;

// 心跳检测
- (void)getXinTiaoWithCompletion:(BSPHPCompletion)completion;

// 获取公告
- (void)getGongGaoWithCompletion:(BSPHPCompletion)completion;

// 获取版本信息
- (void)getVVWithCompletion:(BSPHPCompletion)completion;

//解绑
- (void)jiebang:(NSString*)km completion:(BSPHPCompletion)completion;

//黑名单检测
-(void)getHMD:(NSString*)udid completion:(BSPHPCompletion)completion;

@end

NS_ASSUME_NONNULL_END
