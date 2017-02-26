//
//  AppDelegate.h
//  PhotoMix
//
//  Created by mingli.zhang on 2017/2/26.
//  Copyright © 2017年 mingli.zhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "LaunchScreenView.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) LaunchScreenView *viewController;
@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

