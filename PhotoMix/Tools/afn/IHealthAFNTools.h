//
//  iHealthAFNTools.h
//  iHealth_AiJiaKang
//
//  Created by yang yang on 16/5/6.
//  Copyright © 2016年 九安. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"

typedef NS_ENUM(NSUInteger, IHealthResponseType) {
    kIHealthResponseTypeJSON = 1, // 默认
    kIHealthResponseTypeXML  = 2, // XML
    // 特殊情况下，一转换服务器就无法识别的，默认会尝试转换成JSON，若失败则需要自己去转换
    kIHealthResponseTypeData = 3
};

typedef NS_ENUM(NSUInteger, IHealthRequestType) {
    kIHealthRequestTypeJSON = 1, // JSON
    kIHealthRequestTypePlainText  = 2 // 默认 普通text/html
};

typedef NS_ENUM(NSInteger, IHealthNetworkStatus) {
    kIHealthNetworkStatusUnknown          = -1,//未知网络
    kIHealthNetworkStatusNotReachable     = 0,//网络无连接
    kIHealthNetworkStatusReachableViaWWAN = 1,//2，3，4G网络
    kIHealthNetworkStatusReachableViaWiFi = 2,//WIFI网络
};

@class NSURLSessionTask;
// 请勿直接使用NSURLSessionDataTask,以减少对第三方的依赖
// 所有接口返回的类型都是基类NSURLSessionTask，若要接收返回值
// 且处理，请转换成对应的子类类型
typedef NSURLSessionTask IHealthURLSessionTask;
typedef void(^IHealthResponseSuccess)(id response);
typedef void(^IHealthResponseFail)(NSError *error);

/*!
 *  基于AFNetworking的网络层封装类.
 *
 *  @note 这里只提供公共api
 */
@interface IHealthAFNTools : NSObject

/*!
 *  用于指定网络请求接口的基础url，如：
 *  http://henishuo.com或者http://101.200.209.244
 *  通常在AppDelegate中启动时就设置一次就可以了。如果接口有来源
 *  于多个服务器，可以调用更新
 *
 *  @param baseUrl 网络接口的基础ur`l
 */
+ (void)updateBaseUrl:(NSString *)baseUrl;
+ (NSString *)baseUrl;

/**
 *	设置请求超时时间，默认为15秒
 *
 *	@param timeout 超时时间
 */
+ (void)setTimeout:(NSTimeInterval)timeout;

/**
 *	当检查到网络异常时，是否从从本地提取数据。默认为NO。一旦设置为YES,当设置刷新缓存时，
 *  若网络异常也会从缓存中读取数据。同样，如果设置超时不回调，同样也会在网络异常时回调，除非
 *  本地没有数据！
 *
 *	@param shouldObtain	YES/NO
 */
+ (void)obtainDataFromLocalWhenNetworkUnconnected:(BOOL)shouldObtain;

/**
 *	默认只缓存GET请求的数据，对于POST请求是不缓存的。如果要缓存POST获取的数据，需要手动调用设置
 *  对JSON类型数据有效，对于PLIST、XML不确定！
 *
 *	@param isCacheGet			默认为YES
 *	@param shouldCachePost	默认为NO
 */
+ (void)cacheGetRequest:(BOOL)isCacheGet shoulCachePost:(BOOL)shouldCachePost;

/**
 *	获取缓存总大小/bytes
 *
 *	@return 缓存大小
 */
+ (unsigned long long)totalCacheSize;

/**
 *	清除缓存
 */
+ (void)clearCaches;

/*!
 *  开启或关闭接口打印信息
 *
 *  @param isDebug 开发期，最好打开，默认是YES
 */
+ (void)enableInterfaceDebug:(BOOL)isDebug;

/*!
 *  配置请求格式，默认为JSON。如果要求传XML或者PLIST，请在全局配置一下
 *
 *  @param requestType 请求格式，默认为JSON
 *  @param responseType 响应格式，默认为JSON，
 *  @param shouldAutoEncode YES or NO,默认为NO，是否自动encode url
 *  @param shouldCallbackOnCancelRequest 当取消请求时，是否要回调，默认为YES
 */
+ (void)configRequestType:(IHealthRequestType)requestType
             responseType:(IHealthResponseType)responseType
      shouldAutoEncodeUrl:(BOOL)shouldAutoEncode
  callbackOnCancelRequest:(BOOL)shouldCallbackOnCancelRequest;

/*!
 *  配置公共的请求头，只调用一次即可，通常放在应用启动的时候配置就可以了
 *
 *  @param httpHeaders 只需要将与服务器商定的固定参数设置即可
 */
+ (void)configCommonHttpHeaders:(NSDictionary *)httpHeaders;

/**
 *	取消所有请求
 */
+ (void)cancelAllRequest;

/**
 *	取消某个请求。如果是要取消某个请求，最好是引用接口所返回来的IHealthURLSessionTask对象，
 *  然后调用对象的cancel方法。如果不想引用对象，这里额外提供了一种方法来实现取消某个请求
 *
 *	@param url				URL，可以是绝对URL，也可以是path（也就是不包括baseurl）
 */
+ (void)cancelRequestWithURL:(NSString *)url;

/*!
 *  GET请求接口，若不指定baseurl，可传完整的url
 *
 *  @param url     接口路径，如/path/getArticleList
 *  @param refreshCache 是否缓存刷新。由于请求成功也可能没有数据，对于业务失败，只能通过人为手动判断
 *  @param params  接口中所需要的拼接参数，如@{"categoryid" : @(12)}
 *  @param success 接口成功请求到数据的回调
 *  @param fail    接口请求数据失败的回调
 *
 *  @return 返回的对象中有可取消请求的API
 */
+ (IHealthURLSessionTask *)getWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                          success:(IHealthResponseSuccess)success
                             fail:(IHealthResponseFail)fail;
// 多一个params参数
+ (IHealthURLSessionTask *)getWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                           params:(NSDictionary *)params
                          success:(IHealthResponseSuccess)success
                             fail:(IHealthResponseFail)fail;

/*!
 *  POST请求接口，若不指定baseurl，可传完整的url
 *
 *  @param url     接口路径，如/path/getArticleList
 *  @param params  接口中所需的参数，如@{"categoryid" : @(12)}
 *  @param success 接口成功请求到数据的回调
 *  @param fail    接口请求数据失败的回调
 *
 *  @return 返回的对象中有可取消请求的API
 */
+ (IHealthURLSessionTask *)postWithUrl:(NSString *)url
                      refreshCache:(BOOL)refreshCache
                            params:(NSDictionary *)params
                           success:(IHealthResponseSuccess)success
                              fail:(IHealthResponseFail)fail;

+ (IHealthURLSessionTask *)postWithUrl:(NSString *)url
                                params:(NSDictionary *)params
                                isParseJsonData:(BOOL)isParseJsonData
                               success:(IHealthResponseSuccess)success
                                  fail:(IHealthResponseFail)fail;

+ (IHealthURLSessionTask *)postWithUrl:(NSString *)url
                                params:(NSDictionary *)params
               isJSONRequestSerializer:(BOOL)isJSONRequestSerializer
                               success:(IHealthResponseSuccess)success
                                  fail:(IHealthResponseFail)fail;

+ (IHealthURLSessionTask *)postWithUrl:(NSString *)url
                                params:(NSDictionary *)params
                       isParseJsonData:(BOOL)isParseJsonData
               isJSONRequestSerializer:(BOOL)isJSONRequestSerializer
                               success:(IHealthResponseSuccess)success
                                  fail:(IHealthResponseFail)fail;

@end
