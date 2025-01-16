//  BSPHPOC
//  BSPHP 魔改UDID 技术团队 十三哥工作室
//  承接软件APP开发 UDID定制 验证加密二改 PHP JS HTML5开发 辅助开发
//  WX:NongShiFu123 QQ350722326
//  Created by MRW on 2022/11/14.
//  GitHub:http://github.com/nongshifu/
//  开源Q群: 398423911
//  Copyright © 2019年 xiaozhou. All rights reserved.
//com.rileytestut.Delta.Beta

#import "Config.h"
#import "ValidationManager.h"

@implementation NSObject (mian)
+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(BS延迟启动时间 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[ValidationManager sharedManager] startValidation];
        });
    });
}
@end
