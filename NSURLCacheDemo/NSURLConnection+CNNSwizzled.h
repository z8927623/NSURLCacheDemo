//
//  NSURLConnection+CNNSwizzled.h
//  cheniu
//
//  Created by wildyao on 15/8/27.
//  Copyright (c) 2015年 葛亮. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLConnection (CNNSwizzled)

/**
 * 配置截获参数，应该在delegate中调用，否则所配置参数不起作用，而是按照默认值，啥都不截获
 *
 * @params injectSending 是否截获发送请求
 */
+ (void)cnn_injectConnectionStartSending:(BOOL)injectSending;

@end
