//
//  IHCloudUserTool.m
//  iHealth_AiJiaKang
//
//  Created by yang yang on 16/5/24.
//  Copyright © 2016年 九安. All rights reserved.
//

#import "IHCloudUserTool.h"

@implementation IHCloudUserTool

/**
 *  第三方登录成功后 登录ihealth 云
 */
+ (void)loginIHealthCloudafterThirdLoginSuccessWithUserDic:(NSDictionary *)infoDic queueNub:(NSNumber *)queue
{
    NSString *thirdID = [infoDic valueForKey:@"ThirdID"];
    NSString *thirdName = [infoDic valueForKey:@"ThirdName"];
}

@end
