
#import "NetWorkingApiClient.h"
#import "Config.h"
#import "DES3Util.h"
#import "NSDictionary+StichingStringkeyValue.h"
#import "NSString+MD5.h"
#import "NSString+URLCode.h"
//是否打印
#define MY_NSLog_ENABLED YES

#define NSLog(fmt, ...) \
if (MY_NSLog_ENABLED) { \
NSString *className = NSStringFromClass([self class]); \
NSLog((@"[%s] from class[%@] " fmt), __PRETTY_FUNCTION__, className, ##__VA_ARGS__); \
}


@implementation NetTool : NSObject
+ (NSURLSessionDataTask *)__attribute__((optnone))Post_AppendURL:(NSString *)appendURL
parameters:(NSDictionary *)param
success:(void (^)(id responseObject))success failure:(void (^)(NSError *error))failure{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc]init];
    [parameters setObject:@"ok" forKey:@"json"];
    if (param != nil) {
        NSString *desString  =  [NSDictionary stitchingStringFromDictionary:param];
        NSString *md5String = [BSPHP_PASSWORD md5:BSPHP_PASSWORD];
        desString = [DES3Util encrypt:desString gkey:md5String];
        
        
        NSString * sginstr = [BSPHP_INSGIN stringByReplacingOccurrencesOfString:@"[KEY]"withString:desString];
        NSString * sginstrMD5 = [sginstr md5:sginstr];
        NSLog(@"replaceStr=%@",sginstrMD5);
        parameters[@"sgin"] = sginstrMD5;
        desString = [desString URLEncodedString];
        parameters[@"parameter"] = desString;
    }
    return [[NetWorkingApiClient sharedNetWorkingApiClient] POST:appendURL
                                                      parameters:parameters
                                                        progress:nil
                                                         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSString *str = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSString *md5String = [BSPHP_PASSWORD md5:BSPHP_PASSWORD];
        str = [DES3Util decrypt:str gkey:md5String];
        NSLog(@"请求网址 = %@",appendURL);
        NSLog(@"parameters = %@",parameters);
        NSLog(@"服务器返回数据 = %@",str);
        NSData * data = [str dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        NSLog(@"dict = %@",dict);
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        
        NSString * insginString = [NSString stringWithFormat:@"%@%@%@%@%@", json[@"response"][@"data"], json[@"response"][@"date"],json[@"response"][@"unix"],json[@"response"][@"microtime"],json[@"response"][@"appsafecode"]];
        
        insginString = [BSPHP_TOSGIN stringByReplacingOccurrencesOfString:@"[KEY]"withString:insginString];
        //本地签名
        md5String = [insginString md5:insginString];
        NSString * sginstrMD5 = json[@"response"][@"sgin"];
        if([md5String isEqualToString:sginstrMD5]){
            //success(data);
            NSLog(@"签名验证通过\n");
            
        }else{
            NSLog(@"签名验证未通过\n");
            
            
            NSData *testData = [@"-1000" dataUsingEncoding: NSUTF8StringEncoding];
            data = testData;
        }
        
        
        
        success(data);
    }
                                                         failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@",error);
        failure(error);
    }];
    
}




@end
