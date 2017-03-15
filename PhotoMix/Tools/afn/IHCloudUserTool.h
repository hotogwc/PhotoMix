//
//  IHCloudUserTool.h
//  iHealth_AiJiaKang
//
//  Created by yang yang on 16/5/24.
//  Copyright © 2016年 九安. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IHCloudUserTool : NSObject

/**
 *  第三方登录成功后 登录ihealth 云
 */
+ (void)loginIHealthCloudafterThirdLoginSuccessWithUserDic:(NSDictionary *)infoDic queueNub:(NSNumber *)queue
;

@end
