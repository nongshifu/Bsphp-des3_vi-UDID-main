//
//  appInfo.h
//  myBsphp
//
//  Created by 十三哥 on 2025/1/11.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "YYModel.h"
#import "NSString+MD5.h"
#import "NSString+URLCode.h"
#import "DES3Util.h"

//是否打印
#define MY_NSLog_ENABLED YES

#define NSLog(fmt, ...) \
if (MY_NSLog_ENABLED) { \
NSString *className = NSStringFromClass([self class]); \
NSLog((@"[%s] from class[%@] " fmt), __PRETTY_FUNCTION__, className, ##__VA_ARGS__); \
}


//UIDI存储key
#define BS_UDID @"ergewgrergvstrrrveg"

//卡密存储key
#define BS_KAMI_KEY @"ergewhrthrfagrgfgrge"

//离线存储key
#define BS_Local_Config @"rtggrdffarn"

//到期时间KEY
#define BS_EXP_Time @"hwgertyjyhrg"

//是否已经弹出过到期时间
#define BS_DQTC @"jtehrgefgbwrth"


//软件公告
#define BS_GG @"gonggaoagg"


//随机ID
#define BS_SJID @"BS_SJIDdafs"

//版本弹窗
#define BS_BBTC @"BS_BBTCs"

//离线缓存
#define BS_LOCAL_SAVE_KEY  @"asgfaggta131"

NS_ASSUME_NONNULL_BEGIN


@interface AppInfo : NSObject
//以下为官方配置
@property (nonatomic,strong) NSString * 软件版本号;
@property (nonatomic,strong) NSString * 软件公告;
///软件网页地址作为激活码输入框下面卡密购买地址，留空则不显示购买按钮 变成粘贴按钮
@property (nonatomic,strong) NSString * 软件网页地址;
///软件url地址作为软件更新地址 发现新版会提示这个地址跳转 留空则不跳转浏览器 app闪退
@property (nonatomic,strong) NSString * 软件url地址;
///逻辑A作为是否需要离线验证
@property (nonatomic,assign) BOOL 逻辑A;
///逻辑A的内容为纯数字 作为离线验证的联网周期
@property (nonatomic,strong) NSString * 逻辑A内容;
///逻辑B的真假心跳定时器验证的开关 关闭则不定时验证 建议开启
@property (nonatomic,assign) BOOL 逻辑B;
///逻辑B的内容作为 心跳定时器验证的时间(单位秒)   到了时间会重复验证 这个时间务必比 软件配置-限开控制-心跳包时间 少或者  的一半 不能多
@property (nonatomic,strong) NSString * 逻辑B内容;
///开启自助解绑 客户可以自己更换设备 扣除这个时间(单位秒)
@property (nonatomic,assign) NSInteger 解绑扣除时间;
///储存的到期时间 可以用来显示在UI
@property (nonatomic,strong) NSString * 到期时间;
///判断是否是系用户或者老用户 - 用来免费试用 (通过机器码查询是否存在记录)
@property (nonatomic,assign) BOOL 是否新用户;
/*
 *判断是否被拉黑 这个只有在UDID 安装描述文件模式下 首次安装描述文件后返回 idfv不支持
 *软件列表-用户分组-新建个(黑名单)分组 代码会查询关键字"黑名单"来判断是否被拉黑
 *被拉黑后 客户 安装描述文件 会弹出被管理员拉黑 和信息提示 这个提示内容在 软件-用户列表-查询卡密-卡密备注内容
 */
@property (nonatomic,assign) BOOL 是否被拉黑;
/*
 *管理员备注 被拉黑后 客户 安装描述文件 会弹出被管理员拉黑 和信息提示 这个提示内容在 软件-用户列表-查询卡密-卡密备注内容
 */
@property (nonatomic,strong) NSString * 管理员备注;
/*
 *管理员备注 被拉黑后 客户 安装描述文件 会弹出被管理员拉黑 和信息提示 这个提示内容在 软件-用户列表-查询卡密-卡密备注内容
 */
@property (nonatomic,assign) BOOL 是否免费模式;
///下次离线验证时间
@property (nonatomic, strong) NSDate  * nextTime;

//以下为软件描述不符
@property (nonatomic,assign) BOOL 到期时间弹窗;
@property (nonatomic,assign) BOOL UDID_IDFV;
@property (nonatomic,assign) BOOL 验证版本;
@property (nonatomic,assign) BOOL 验证过直播;
@property (nonatomic,assign) NSInteger 弹窗类型;
@property (nonatomic,assign) BOOL 公告弹窗;
@property (nonatomic,assign) BOOL 试用模式;
@property (nonatomic,assign) BOOL 支持解绑;
@property (nonatomic,assign) BOOL 黑名单检测;
@property (nonatomic,assign) BOOL 是否强制版本更新;
@property (nonatomic,assign) BOOL 是否三指双击显示到期时间;
@property (nonatomic,assign) BOOL 是否验证特征码一致;
// 读取模型并判断是否超过时间以及是否到期的函数，通过闭包返回结果
+ (void)readModelAndCheckTimeWithCompletion:(void (^)(BOOL needVerify, AppInfo * _Nullable appInfo, BOOL isExpired))completion;
// 本地化存储函数
+ (void)saveModelToLocal:(AppInfo *)appInfo withExtensionSeconds:(NSTimeInterval)seconds;


@end

NS_ASSUME_NONNULL_END
