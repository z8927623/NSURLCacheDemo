//
//  CNNDelegateClassObserver.h
//  WordPress
//
//  Created by wildyao on 15/8/29.
//  Copyright (c) 2015年 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CNNDelegateClassObserver : NSObject

/**
 * 配置拦截参数，应该在delegate中调用，否则所配置参数不起作用，而是按照默认值，啥都不截获
 *
 * @params injectSending         是否截获发送包，包括发送时间、url、head、body等
 * @params injectReceiveResponse 是否截获服务端回应
 * @params injectFinished        是否截获完成回调，默认打印返回的数据、返回时间还有url
 * @params injectFailed          是否截获失败回调，比如超时或者断网，打印失败原因以及失败时间和请求的相关信息
 * @params logVariableType       是否打印服务端返回数据的类型，当injectFinished为YES并且simpleFinishedInfo为NO的时候才有效
 * @params simpleFinishedInfo    是否打印简略的完成信息（只包括时间和完成的url）而不是返回数据，因为有时候我们只关心该请求是否完成，当injectFinished为YES的时候才有效
 * @params injectSelectRow       是否截获UITableView的tableView:didSelectRowAtIndexPath:代理，如设为YES，默认处理为取消选中，即点击cell之后默认将其取消
 */
+ (void)cnn_injectConnectionStartSending:(BOOL)injectSending didReceiveResponse:(BOOL)injectReceiveResponse didFinishLoading:(BOOL)injectFinished didFailWithError:(BOOL)injectFailed logVariableType:(BOOL)logVariableType simpleFinishedInfoIfInjectFinished:(BOOL)simpleFinishedInfo didSelectRowAtIndexPath:(BOOL)injectSelectRow;

@end
