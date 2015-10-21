//
//  AppDelegate.m
//  NSURLCacheDemo
//
//  Created by wildyao on 15/2/18.
//  Copyright (c) 2015年 wildyao. All rights reserved.
//

#import "AppDelegate.h"
#import "CNNDelegateClassObserver.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [self startClassObserveDebug];
    
    return YES;
}

- (void)startClassObserveDebug
{
#ifdef DEBUG
    // 配置拦截参数，应该在delegate中调用，否则所配置参数不起作用，而是按照默认值，啥都不截获
    
    /**
     * @params logHierarchy 是否追踪vc层级
     * @params logDealloc   是否追踪dealloc调用情况，该参数功能与CNNViewControllerInterceptor中方法功能一致
     */
    //    [UIViewController cnn_logViewControllerHierarchy:YES logDealloc:NO];
    
    /**
     * @params injectSending         是否截获发送包，包括发送时间、url、head、body等
     * @params injectReceiveResponse 是否截获服务端回应
     * @params injectFinished        是否截获完成回调，默认打印返回的数据、返回时间还有url
     * @params injectFailed          是否截获失败回调，比如超时或者断网，打印失败原因以及失败时间和请求的相关信息
     * @params logVariableType       是否打印服务端返回数据的类型，当injectFinished为YES并且simpleFinishedInfo为NO的时候才有效
     * @params simpleFinishedInfo    是否打印简略的完成信息（只包括时间和完成的url）而不是返回数据，因为有时候我们只关心该请求是否完成，当injectFinished为YES的时候才有效
     * @params injectSelectRow       是否截获UITableView的tableView:didSelectRowAtIndexPath:代理，如设为YES，默认处理为取消选中，即点击cell之后默认将其取消
     */
    
    [CNNDelegateClassObserver cnn_injectConnectionStartSending:YES didReceiveResponse:YES didFinishLoading:YES didFailWithError:YES logVariableType:NO simpleFinishedInfoIfInjectFinished:NO didSelectRowAtIndexPath:NO];
#endif
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
