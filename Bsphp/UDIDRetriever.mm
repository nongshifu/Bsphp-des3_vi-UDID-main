#import "UDIDRetriever.h"
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <dlfcn.h>
#include <stdio.h>


@implementation UDIDRetriever

- (instancetype)init {
    self = [super init];
    if (self) {
        _hasReceivedUDID = NO;
    }
    return self;
}

- (void)startServerWithCompletion:(BSPHPCompletion)completion {
    
    // 判断越狱/ROOT注入情况下 直接读取
    static CFStringRef (*$MGCopyAnswer)(CFStringRef);
    void *gestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY);
    $MGCopyAnswer = reinterpret_cast<CFStringRef (*)(CFStringRef)>(dlsym(gestalt, "MGCopyAnswer"));
    NSString *设备特征码 = (__bridge NSString *)$MGCopyAnswer(CFSTR("SerialNumber"));
    if (设备特征码.length > 6 && completion) {
        completion(设备特征码, nil);
        return;
    }
    
    self.completion = completion;
    
    // 初始化 GCDWebServer
    self.webServer = [[GCDWebServer alloc] init];
    // 创建弱引用
    __weak typeof(self) weakSelf = self;
    // 提供描述文件下载
    [self.webServer addHandlerForMethod:@"GET"
                                   path:@"/profile"
                           requestClass:[GCDWebServerRequest class]
                           processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
        // 动态生成描述文件内容
        NSString *profileContent = [NSString stringWithFormat:
            @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
            "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
            "<plist version=\"1.0\">\n"
            "<dict>\n"
            "    <key>PayloadContent</key>\n"
            "    <dict>\n"
            "        <key>URL</key>\n"
            "        <string>https://baidu.com</string>\n"
            "        <key>DeviceAttributes</key>\n"
            "        <array>\n"
            "            <string>UDID</string>\n"
            "            <string>IMEI</string>\n"
            "            <string>ICCID</string>\n"
            "            <string>VERSION</string>\n"
            "            <string>PRODUCT</string>\n"
            "        </array>\n"
            "    </dict>\n"
            "    <key>PayloadOrganization</key>\n"
            "    <string>十三哥</string>\n"
            "    <key>PayloadDisplayName</key>\n"
            "    <string>UDID Retrieval</string>\n"
            "    <key>PayloadVersion</key>\n"
            "    <integer>1</integer>\n"
            "    <key>PayloadUUID</key>\n"
            "    <string>%@</string>\n"
            "    <key>PayloadIdentifier</key>\n"
            "    <string>com.yourcompany.udid</string>\n"
            "    <key>PayloadDescription</key>\n"
            "    <string>这个描述文件用来获取你的设备码绑定卡密.</string>\n"
            "    <key>PayloadType</key>\n"
            "    <string>Profile Service</string>\n"
            "</dict>\n"
            "</plist>",
            
            [[NSUUID UUID] UUIDString]
        ];
        
        // 将描述文件内容转换为 NSData
        NSData *profileData = [profileContent dataUsingEncoding:NSUTF8StringEncoding];
        
        // 返回描述文件
        return [GCDWebServerDataResponse responseWithData:profileData contentType:@"application/x-apple-aspen-config"];
    }];
    
    // 处理 UDID 返回
    [self.webServer addHandlerForMethod:@"POST"
                                   path:@"/udid"
                           requestClass:[GCDWebServerDataRequest class]
                           processBlock:^GCDWebServerResponse *(GCDWebServerDataRequest *request) {
        // 解析设备返回的数据
        NSData *data = request.data;
        NSError *error = nil;
        NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:data
                                                                       options:NSPropertyListImmutable
                                                                        format:nil
                                                                         error:&error];
        if (error) {
            weakSelf.completion(nil, error);
            return [GCDWebServerDataResponse responseWithHTML:@"<html><body><h1>Error: Invalid Data</h1></body></html>"];
        }
        
        // 提取 UDID
        NSString *udid = plist[@"UDID"];
        if (udid) {
            weakSelf.completion(udid, nil);
            weakSelf.hasReceivedUDID = YES;
        } else {
            weakSelf.completion(nil, [NSError errorWithDomain:@"UDIDError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Failed to retrieve UDID"}]);
        }
        
        // 返回成功页面
        return [GCDWebServerDataResponse responseWithHTML:@"<html><body><h1>UDID Received</h1></body></html>"];
    }];
    
    // 启动服务器
    [self.webServer startWithPort:8080 bonjourName:nil];
    NSLog(@"Visit %@ in your browser to retrieve UDID", self.webServer.serverURL);
    
    // 注册通知，监听App变为活跃状态，尝试判断是否从描述文件安装页面跳转回来（只是一种尝试的判断方式，不一定完全准确）
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)stopServer {
    if (self.webServer.isRunning) {
        [self.webServer stop];
    }
    // 移除通知观察者
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

// 处理App变为活跃状态的通知方法，在这里尝试判断是否从描述文件安装页面跳转回来以及进行UDID获取后的相关处理
- (void)appDidBecomeActive:(NSNotification *)notification {
    if (self.hasReceivedUDID) {
        NSLog(@"已经成功获取到UDID，可在这里进行后续处理，比如传递给其他模块等");
        // 这里可以添加代码将UDID传递给其他需要使用的模块，或者进行数据上报等操作
    } else {
        NSLog(@"可能从其他情况进入活跃状态，尚未获取到UDID，可考虑是否需要重新尝试获取等操作");
        // 可以根据实际需求决定是否在这里重新启动获取UDID的流程，比如再次调用startServerWithCompletion等
    }
}

@end
