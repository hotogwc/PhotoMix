//
//  iHealthAFNTools.m
//  iHealth_AiJiaKang
//
//  Created by yang yang on 16/5/6.
//  Copyright © 2016年 九安. All rights reserved.
//

#import "iHealthAFNTools.h"
#import <CommonCrypto/CommonDigest.h>

#pragma mark - md5文件
@interface NSString (md5)

+ (NSString *)IHealthnetworking_md5:(NSString *)string;

@end

@implementation NSString (md5)

+ (NSString *)IHealthnetworking_md5:(NSString *)string {
    if (string == nil || [string length] == 0) {
        return nil;
    }
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH], i;
    CC_MD5([string UTF8String], (int)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding], digest);
    NSMutableString *ms = [NSMutableString string];
    
    for (i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [ms appendFormat:@"%02x", (int)(digest[i])];
    }
    
    return [ms copy];
}

@end

#pragma mark - 默认信息 
static NSString *sg_privateNetworkBaseUrl = nil;   //基础url
static NSTimeInterval sg_timeout = 5.0f;   //默认超时时间
static BOOL sg_shoulObtainLocalWhenUnconnected = NO; //无网时不读取缓存
static BOOL sg_cacheGet = YES;   //默认缓存get请求数据
static BOOL sg_cachePost = NO; //默认不缓存post请求数据
static BOOL sg_isEnableInterfaceDebug = YES; //默认开启接口打印信息
static IHealthResponseType sg_responseType = kIHealthResponseTypeData; //响应格式为HTTPResponseSerializer
static IHealthRequestType  sg_requestType  = kIHealthRequestTypePlainText; //请求格式为普通text/html
static BOOL sg_shouldAutoEncode = NO; //不自动encode
static BOOL sg_shouldCallbackOnCancelRequest = YES; //当取消请求时，要回调
static NSDictionary *sg_httpHeaders = nil;  //公共的请求头
static NSMutableArray *sg_requestTasks; //请求task数组
static IHealthNetworkStatus sg_networkStatus = kIHealthNetworkStatusUnknown; //网络状态

#define PostRequest 2
#define GetRequest 1

#pragma mark - IHealthAFNTools实现代码
@implementation IHealthAFNTools

+ (void)updateBaseUrl:(NSString *)baseUrl {
    sg_privateNetworkBaseUrl = baseUrl;
}

+ (NSString *)baseUrl {
    return sg_privateNetworkBaseUrl;
}

+ (void)setTimeout:(NSTimeInterval)timeout {
    sg_timeout = timeout;
}

+ (void)obtainDataFromLocalWhenNetworkUnconnected:(BOOL)shouldObtain {
    sg_shoulObtainLocalWhenUnconnected = shouldObtain;
}

+ (void)cacheGetRequest:(BOOL)isCacheGet shoulCachePost:(BOOL)shouldCachePost {
    sg_cacheGet = isCacheGet;
    sg_cachePost = shouldCachePost;
}

#pragma mark - 缓存目录
static inline NSString *cachePath() {
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/IHealthNetworkingCaches"];
}

#pragma mark - 网络请求Cache大小
+ (unsigned long long)totalCacheSize {
    NSString *directoryPath = cachePath();
    BOOL isDir = NO;
    unsigned long long total = 0;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDir]) {
        if (isDir) {
            NSError *error = nil;
            NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:&error];
            
            if (error == nil) {
                for (NSString *subpath in array) {
                    NSString *path = [directoryPath stringByAppendingPathComponent:subpath];
                    NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:path
                                                                                          error:&error];
                    if (!error) {
                        total += [dict[NSFileSize] unsignedIntegerValue];
                    }
                }
            }
        }
    }
    
    return total;
}

#pragma mark - 清除CaChe
+ (void)clearCaches {
    NSString *directoryPath = cachePath();
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:nil]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:directoryPath error:&error];
        
        if (error) {
            //MYLog(@"IHealthNetworking clear caches error: %@", error);
        } else {
            //MYLog(@"IHealthNetworking clear caches ok");
        }
    }
}

+ (void)enableInterfaceDebug:(BOOL)isDebug {
    sg_isEnableInterfaceDebug = isDebug;
}

+ (BOOL)isDebug {
    return sg_isEnableInterfaceDebug;
}

#pragma mark - 配置请求格式、响应格式、是否自动encode url、请求取消是否需要回调
+ (void)configRequestType:(IHealthRequestType)requestType
             responseType:(IHealthResponseType)responseType
      shouldAutoEncodeUrl:(BOOL)shouldAutoEncode
  callbackOnCancelRequest:(BOOL)shouldCallbackOnCancelRequest {
    sg_requestType = requestType;
    sg_responseType = responseType;
    sg_shouldAutoEncode = shouldAutoEncode;
    sg_shouldCallbackOnCancelRequest = shouldCallbackOnCancelRequest;
}

+ (void)configCommonHttpHeaders:(NSDictionary *)httpHeaders {
    sg_httpHeaders = httpHeaders;
}

+ (NSMutableArray *)allTasks {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sg_requestTasks == nil) {
            sg_requestTasks = [[NSMutableArray alloc] init];
        }
    });
    
    return sg_requestTasks;
}

+ (void)cancelAllRequest {
    @synchronized(self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(IHealthURLSessionTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task isKindOfClass:[IHealthURLSessionTask class]]) {
                [task cancel];
            }
        }];
        
        [[self allTasks] removeAllObjects];
    };
}

+ (void)cancelRequestWithURL:(NSString *)url {
    if (url == nil) {
        return;
    }
    
    @synchronized(self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(IHealthURLSessionTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task isKindOfClass:[IHealthURLSessionTask class]]
                && [task.currentRequest.URL.absoluteString hasSuffix:url]) {
                [task cancel];
                [[self allTasks] removeObject:task];
                return;
            }
        }];
    };
}

+ (AFHTTPSessionManager *)manager {
    // 开启转圈圈
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    AFHTTPSessionManager *manager = nil;;
    if ([self baseUrl] != nil) {
        manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:[self baseUrl]]];
    } else {
        manager = [AFHTTPSessionManager manager];
    }
    
    switch (sg_requestType) {
        case kIHealthRequestTypeJSON: {
            manager.requestSerializer = [AFJSONRequestSerializer serializer];
            break;
        }
        case kIHealthRequestTypePlainText: {
            manager.requestSerializer = [AFHTTPRequestSerializer serializer];
            break;
        }
        default: {
            break;
        }
    }
    
    switch (sg_responseType) {
        case kIHealthResponseTypeJSON: {
            manager.responseSerializer = [AFJSONResponseSerializer serializer];
            break;
        }
        case kIHealthResponseTypeXML: {
            manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
            break;
        }
        case kIHealthResponseTypeData: {
            manager.responseSerializer = [AFHTTPResponseSerializer serializer];
            break;
        }
        default: {
            break;
        }
    }
    
    manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
    
    
    for (NSString *key in sg_httpHeaders.allKeys) {
        if (sg_httpHeaders[key] != nil) {
            [manager.requestSerializer setValue:sg_httpHeaders[key] forHTTPHeaderField:key];
        }
    }
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*"]];
    
    manager.requestSerializer.timeoutInterval = sg_timeout;
    
    // 设置允许同时最大并发数量，过大容易出问题
    manager.operationQueue.maxConcurrentOperationCount = 3;
    
    if (sg_shoulObtainLocalWhenUnconnected && (sg_cacheGet || sg_cachePost ) ) {
        [self detectNetwork];
    }
    return manager;
}

#pragma mark - 更新网络状态
+ (void)detectNetwork{
    AFNetworkReachabilityManager *reachabilityManager = [AFNetworkReachabilityManager sharedManager];
    [reachabilityManager startMonitoring];
    [reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status == AFNetworkReachabilityStatusNotReachable){
            sg_networkStatus = kIHealthNetworkStatusNotReachable;
        }else if (status == AFNetworkReachabilityStatusUnknown){
            sg_networkStatus = kIHealthNetworkStatusUnknown;
        }else if (status == AFNetworkReachabilityStatusReachableViaWWAN){
            sg_networkStatus = kIHealthNetworkStatusReachableViaWWAN;
        }else if (status == AFNetworkReachabilityStatusReachableViaWiFi){
            sg_networkStatus = kIHealthNetworkStatusReachableViaWiFi;
        }
    }];
}

+ (NSString *)absoluteUrlWithPath:(NSString *)path {
    if (path == nil || path.length == 0) {
        return @"";
    }
    
    if ([self baseUrl] == nil || [[self baseUrl] length] == 0) {
        return path;
    }
    
    NSString *absoluteUrl = [[NSURL URLWithString:path relativeToURL:[NSURL URLWithString:[self baseUrl]]] absoluteString];
    
    return absoluteUrl;
}

+ (BOOL)shouldEncode {
    return sg_shouldAutoEncode;
}

+ (NSString *)encodeUrl:(NSString *)url {
    return [self IHealth_URLEncode:url];
}

+ (NSString *)IHealth_URLEncode:(NSString *)url {
    NSString *newString = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                              (CFStringRef)url,
                                                              NULL,
                                                              CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
    if (newString) {
        return newString;
    }
    
    return url;
}

+ (id)cahceResponseWithURL:(NSString *)url parameters:params {
    id cacheData = nil;
    
    if (url) {
        // Try to get datas from disk
        NSString *directoryPath = cachePath();
        NSString *absoluteURL = [self generateGETAbsoluteURL:url params:params];
        NSString *key = [NSString IHealthnetworking_md5:absoluteURL];
        NSString *path = [directoryPath stringByAppendingPathComponent:key];
        
        NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];
        if (data) {
            cacheData = data;
            //MYLog(@"Read data from cache for url: %@\n", url);
        }
    }
    
    return cacheData;
}

// 仅对一级字典结构起作用
+ (NSString *)generateGETAbsoluteURL:(NSString *)url params:(id)params {
    if (params == nil || ![params isKindOfClass:[NSDictionary class]] || [params count] == 0) {
        return url;
    }
    
    NSString *queries = @"";
    for (NSString *key in params) {
        id value = [params objectForKey:key];
        
        if ([value isKindOfClass:[NSDictionary class]]) {
            continue;
        } else if ([value isKindOfClass:[NSArray class]]) {
            continue;
        } else if ([value isKindOfClass:[NSSet class]]) {
            continue;
        } else {
            queries = [NSString stringWithFormat:@"%@%@=%@&",
                       (queries.length == 0 ? @"&" : queries),
                       key,
                       value];
        }
    }
    
    if (queries.length > 1) {
        queries = [queries substringToIndex:queries.length - 1];
    }
    
    if (([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) && queries.length > 1) {
        if ([url rangeOfString:@"?"].location != NSNotFound
            || [url rangeOfString:@"#"].location != NSNotFound) {
            url = [NSString stringWithFormat:@"%@%@", url, queries];
        } else {
            queries = [queries substringFromIndex:1];
            url = [NSString stringWithFormat:@"%@?%@", url, queries];
        }
    }
    
    return url.length == 0 ? queries : url;
}

+ (void)successResponse:(id)responseData callback:(IHealthResponseSuccess)success isParseJsonData:(BOOL)isParseJsonData{
    if (success) {
        if (isParseJsonData) {
            success([self tryToParseData:responseData]);
        }
        else{
            success([self tryToParseDataString:responseData]);
        }
    }
}

#pragma mark - 尝试data => string
+ (NSString *)tryToParseDataString:(id)responseData
{
    if ([responseData isKindOfClass:[NSData class]]) {
        
        if (responseData == nil) {
            return responseData;
        } else {
            return [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        }
    } else {
        return responseData;
    }
}

#pragma mark - 尝试解析成JSON
+ (id)tryToParseData:(id)responseData{
    if ([responseData isKindOfClass:[NSData class]]) {
        
        if (responseData == nil) {
            return responseData;
        } else {
            NSError *error = nil;
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData
                                                                     options:NSJSONReadingMutableContainers
                                                                       error:&error];
            
            if (error != nil) {
                return responseData;
            } else {
                return response;
            }
        }
    } else {
        return responseData;
    }
}

+ (void)logWithSuccessResponse:(id)response url:(NSString *)url params:(NSDictionary *)params isParseJsonData:(BOOL)isParseJsonData{
    //MYLog(@"\n");
    NSString *str;
    if (isParseJsonData) {
        str = [self tryToParseData:response];
    }
    else{
        str = [self tryToParseDataString:response];
    }
    //MYLog(@"\nRequest success, URL: %@\n params:%@\n response:%@\n\n",
    //          [self generateGETAbsoluteURL:url params:params],
      //        params,
        //      str);
}

+ (void)logWithFailError:(NSError *)error url:(NSString *)url params:(id)params {
    NSString *format = @" params: ";
    if (params == nil || ![params isKindOfClass:[NSDictionary class]]) {
        format = @"";
        params = @"";
    }
    
    //MYLog(@"\n");
    if ([error code] == NSURLErrorCancelled) {
        //MYLog(@"\nRequest was canceled mannully, URL: %@ %@%@\n\n",
         //         [self generateGETAbsoluteURL:url params:params],
           //       format,
             //     params);
    } else {
        //MYLog(@"\nRequest error, URL: %@ %@%@\n errorInfos:%@\n\n",
          //        [self generateGETAbsoluteURL:url params:params],
            //      format,
              //    params,
                 // [error localizedDescription]);
    }
}

+ (void)cacheResponseObject:(id)responseObject request:(NSURLRequest *)request parameters:params {
    if (request && responseObject && ![responseObject isKindOfClass:[NSNull class]]) {
        NSString *directoryPath = cachePath();
        
        NSError *error = nil;
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:nil]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&error];
            if (error) {
                //MYLog(@"create cache dir error: %@\n", error);
                return;
            }
        }
        
        NSString *absoluteURL = [self generateGETAbsoluteURL:request.URL.absoluteString params:params];
        NSString *key = [NSString IHealthnetworking_md5:absoluteURL];
        NSString *path = [directoryPath stringByAppendingPathComponent:key];
        NSDictionary *dict = (NSDictionary *)responseObject;
        
        NSData *data = nil;
        if ([dict isKindOfClass:[NSData class]]) {
            data = responseObject;
        } else {
            data = [NSJSONSerialization dataWithJSONObject:dict
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&error];
        }
        
        if (data && error == nil) {
            BOOL isOk = [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
            if (isOk) {
                //MYLog(@"cache file ok for request: %@\n", absoluteURL);
            } else {
                //MYLog(@"cache file error for request: %@\n", absoluteURL);
            }
        }
    }
}

+ (void)handleCallbackWithError:(NSError *)error fail:(IHealthResponseFail)fail {
    if ([error code] == NSURLErrorCancelled) {
        if (sg_shouldCallbackOnCancelRequest) {
            if (fail) {
                fail(error);
            }
        }
    } else {
        if (fail) {
            fail(error);
        }
    }
}

#pragma mark - get请求
+ (IHealthURLSessionTask *)getWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                          success:(IHealthResponseSuccess)success
                             fail:(IHealthResponseFail)fail {
    return [self getWithUrl:url
               refreshCache:refreshCache
                     params:nil
                    success:success
                       fail:fail];
}

+ (IHealthURLSessionTask *)getWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                           params:(NSDictionary *)params
                          success:(IHealthResponseSuccess)success
                             fail:(IHealthResponseFail)fail {
    return [self _requestWithUrl:url
                    refreshCache:refreshCache
                       httpMedth:GetRequest
                          params:params
                        isParseJsonData:YES
                        isJSONRequestSerializer:NO
                         success:success
                            fail:fail];
}

#pragma mark - post请求
+ (IHealthURLSessionTask *)postWithUrl:(NSString *)url
                      refreshCache:(BOOL)refreshCache
                            params:(NSDictionary *)params
                           success:(IHealthResponseSuccess)success
                              fail:(IHealthResponseFail)fail {
    return [self _requestWithUrl:url
                    refreshCache:refreshCache
                       httpMedth:PostRequest
                          params:params
                           isParseJsonData:YES
                        isJSONRequestSerializer:NO
                         success:success
                            fail:fail];
}

+ (IHealthURLSessionTask *)postWithUrl:(NSString *)url
                                params:(NSDictionary *)params
                       isParseJsonData:(BOOL)isParseJsonData
                               success:(IHealthResponseSuccess)success
                                  fail:(IHealthResponseFail)fail
{
    return [self postWithUrl:url
                      params:params
             isParseJsonData:isParseJsonData
     isJSONRequestSerializer:YES
                     success:success
                        fail:fail];
}

+ (IHealthURLSessionTask *)postWithUrl:(NSString *)url
                                params:(NSDictionary *)params
               isJSONRequestSerializer:(BOOL)isJSONRequestSerializer
                               success:(IHealthResponseSuccess)success
                                  fail:(IHealthResponseFail)fail
{
    return [self postWithUrl:url
                    params:params
             isParseJsonData:YES
     isJSONRequestSerializer:isJSONRequestSerializer
                     success:success
                        fail:fail];
}

+ (IHealthURLSessionTask *)postWithUrl:(NSString *)url
                                params:(NSDictionary *)params
                                isParseJsonData:(BOOL)isParseJsonData
               isJSONRequestSerializer:(BOOL)isJSONRequestSerializer
                               success:(IHealthResponseSuccess)success
                                  fail:(IHealthResponseFail)fail
{
    return [self _requestWithUrl:url
                    refreshCache:NO
                       httpMedth:PostRequest
                          params:params
                 isParseJsonData:isParseJsonData
         isJSONRequestSerializer:isJSONRequestSerializer
                         success:success
                            fail:fail];
}

#pragma mark - 最底层的请求函数
+ (IHealthURLSessionTask *)_requestWithUrl:(NSString *)url
                          refreshCache:(BOOL)refreshCache
                             httpMedth:(NSUInteger)httpMethod
                                params:(NSDictionary *)params
                                isParseJsonData:(BOOL)isParseJsonData
                                isJSONRequestSerializer:(BOOL)isJSONRequestSerializer
                               success:(IHealthResponseSuccess)success
                                  fail:(IHealthResponseFail)fail {
    AFHTTPSessionManager *manager = [self manager];
    if (isJSONRequestSerializer) {
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
    }
    NSString *absolute = [self absoluteUrlWithPath:url];
    
    if ([self baseUrl] == nil) {
        if ([NSURL URLWithString:url] == nil) {
            //MYLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    } else {
        NSURL *absouluteURL = [NSURL URLWithString:absolute];
        
        if (absouluteURL == nil) {
            //MYLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    }
    
    if ([self shouldEncode]) {
        url = [self encodeUrl:url];
    }
    
    IHealthURLSessionTask *session = nil;
    
    if (httpMethod == GetRequest) {
        if (sg_cacheGet) {
            if (sg_shoulObtainLocalWhenUnconnected) {
                if (sg_networkStatus == kIHealthNetworkStatusNotReachable ||  sg_networkStatus == kIHealthNetworkStatusUnknown ) {
                    id response = [IHealthAFNTools cahceResponseWithURL:absolute parameters:params];
                    if (response) {
                        if (success) {
                            [self successResponse:response callback:success isParseJsonData:isParseJsonData];
                            
                            if ([self isDebug]) {
                                [self logWithSuccessResponse:response
                                                         url:absolute
                                                      params:params
                                                      isParseJsonData:isParseJsonData];
                            }
                        }
                        return nil;
                    }
                }
            }
            if (refreshCache) {// 从缓存中更新
                id response = [IHealthAFNTools cahceResponseWithURL:absolute
                                                       parameters:params];
                if (response) {
                    if (success) {
                        [self successResponse:response callback:success  isParseJsonData:isParseJsonData];
                        
                        if ([self isDebug]) {
                            [self logWithSuccessResponse:response
                                                     url:absolute
                                                  params:params
                                         isParseJsonData:isParseJsonData];
                        }
                    }
                    return nil;
                }
            }
        }
        
        session = [manager GET:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [self successResponse:responseObject callback:success isParseJsonData:isParseJsonData];
            
            if (sg_cacheGet) {
                [self cacheResponseObject:responseObject request:task.currentRequest parameters:params];
            }
            
            [[self allTasks] removeObject:task];
            
            if ([self isDebug]) {
                [self logWithSuccessResponse:responseObject
                                         url:absolute
                                      params:params
                             isParseJsonData:isParseJsonData];
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [[self allTasks] removeObject:task];
            
            if ([error code] < 0 && sg_cacheGet) {// 获取缓存
                id response = [IHealthAFNTools cahceResponseWithURL:absolute
                                                       parameters:params];
                if (response) {
                    if (success) {
                        [self successResponse:response callback:success isParseJsonData:isParseJsonData];
                        
                        if ([self isDebug]) {
                            [self logWithSuccessResponse:response
                                                     url:absolute
                                                  params:params
                                         isParseJsonData:isParseJsonData];
                        }
                    }
                } else {
                    [self handleCallbackWithError:error fail:fail];
                    
                    if ([self isDebug]) {
                        [self logWithFailError:error url:absolute params:params];
                    }
                }
            } else {
                [self handleCallbackWithError:error fail:fail];
                
                if ([self isDebug]) {
                    [self logWithFailError:error url:absolute params:params];
                }
            }
        }];
    } else if (httpMethod == PostRequest) {
        if (sg_cachePost ) {// 无网络时获取缓存
            if (sg_shoulObtainLocalWhenUnconnected) {
                if (sg_networkStatus == kIHealthNetworkStatusNotReachable ||  sg_networkStatus == kIHealthNetworkStatusUnknown ) {
                    id response = [IHealthAFNTools cahceResponseWithURL:absolute
                                                           parameters:params];
                    if (response) {
                        if (success) {
                            [self successResponse:response callback:success isParseJsonData:isParseJsonData];
                            
                            if ([self isDebug]) {
                                [self logWithSuccessResponse:response
                                                         url:absolute
                                                      params:params
                                             isParseJsonData:isParseJsonData];
                            }
                        }
                        return nil;
                    }
                }
            }
            if (refreshCache) {   // 从缓存中更新
                id response = [IHealthAFNTools cahceResponseWithURL:absolute
                                                       parameters:params];
                if (response) {
                    if (success) {
                        [self successResponse:response callback:success isParseJsonData:isParseJsonData];
                        
                        if ([self isDebug]) {
                            [self logWithSuccessResponse:response
                                                     url:absolute
                                                  params:params
                                         isParseJsonData:isParseJsonData];
                        }
                    }
                    return nil;
                }
            }
        }
        
        session = [manager POST:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [self successResponse:responseObject callback:success isParseJsonData:isParseJsonData];
            
            if (sg_cachePost) {
                [self cacheResponseObject:responseObject request:task.currentRequest  parameters:params];
            }
            
            [[self allTasks] removeObject:task];
            
            if ([self isDebug]) {
                [self logWithSuccessResponse:responseObject
                                         url:absolute
                                      params:params
                             isParseJsonData:isParseJsonData];
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [[self allTasks] removeObject:task];
            
            if ([error code] < 0 && sg_cachePost) {// 获取缓存
                id response = [IHealthAFNTools cahceResponseWithURL:absolute
                                                       parameters:params];
                
                if (response) {
                    if (success) {
                        [self successResponse:response callback:success isParseJsonData:isParseJsonData];
                        
                        if ([self isDebug]) {
                            [self logWithSuccessResponse:response
                                                     url:absolute
                                                  params:params
                                         isParseJsonData:isParseJsonData];
                        }
                    }
                } else {
                    [self handleCallbackWithError:error fail:fail];
                    
                    if ([self isDebug]) {
                        [self logWithFailError:error url:absolute params:params];
                    }
                }
            } else {
                [self handleCallbackWithError:error fail:fail];
                
                if ([self isDebug]) {
                    [self logWithFailError:error url:absolute params:params];
                }
            }
        }];
    }
    
    if (session) {
        [[self allTasks] addObject:session];
    }
    
    return session;
}

@end
