//
//  UDIDRetriever.h
//  myBsphp
//
//  Created by 十三哥 on 2025/1/11.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BSPHPAPI.h"
#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"
#import "GCDWebServerDataRequest.h"
#import <zlib.h>


NS_ASSUME_NONNULL_BEGIN


@interface UDIDRetriever : NSObject

@property (nonatomic, strong) GCDWebServer *webServer;
@property (nonatomic, copy) BSPHPCompletion completion;
//启动局域网 安装描述文件 获取UDID 回调udid
- (void)startServerWithCompletion:(BSPHPCompletion)completion;
- (void)stopServer;
// 用于标记是否已经获取到UDID的属性
@property (nonatomic, assign) BOOL hasReceivedUDID;
@end

NS_ASSUME_NONNULL_END
