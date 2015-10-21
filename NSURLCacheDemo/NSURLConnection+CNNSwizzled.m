
//  NSURLConnection+CNNSwizzled.m
//  cheniu
//
//  Created by wildyao on 15/8/27.
//  Copyright (c) 2015年 葛亮. All rights reserved.
//

#import "NSURLConnection+CNNSwizzled.h"
#import <objc/runtime.h>

static BOOL _isSwizzled = NO;

static BOOL _injectSending = NO;

static NSDateFormatter *_formatter;

@implementation NSURLConnection (CNNSwizzled)

+ (void)cnn_injectConnectionStartSending:(BOOL)injectSending
{
    _injectSending = injectSending;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"
static void initializeDateFormatter()
{
    _formatter = [[NSDateFormatter alloc] init];
    _formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    _formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT+8"];
}
#pragma clang diagnostic pop

+ (void)load {
    dispatch_async(dispatch_get_main_queue(), ^{
        initializeDateFormatter();
        [self swizzle];
    });
}

+ (void)swizzle
{
    if (_isSwizzled || !_injectSending) {
        return;
    }
    _isSwizzled = YES;
    
    swizzleInstance([self class], @selector(initWithRequest:delegate:startImmediately:), @selector(swizzleInitWithRequest:delegate:startImmediately:));
    swizzleInstance([self class], @selector(initWithRequest:delegate:), @selector(swizzleInitWithRequest:delegate:));
    
    swizzleClass([self class], @selector(connectionWithRequest:delegate:), @selector(swizzleConnectionWithRequest:delegate:));
    swizzleClass([self class], @selector(sendAsynchronousRequest:queue:completionHandler:), @selector(swizzleSendAsynchronousRequest:queue:completionHandler:));
}

+ (void)undoSwizzle
{
    if (!_isSwizzled) {
        return;
    }
    _isSwizzled = NO;
    
    swizzleInstance([self class], @selector(swizzleInitWithRequest:delegate:startImmediately:), @selector(initWithRequest:delegate:startImmediately:));
    swizzleInstance([self class], @selector(swizzleInitWithRequest:delegate:), @selector(initWithRequest:delegate:));
    
    swizzleClass([self class], @selector(swizzleConnectionWithRequest:delegate:), @selector(connectionWithRequest:delegate:));
    swizzleClass([self class], @selector(swizzleSendAsynchronousRequest:queue:completionHandler:), @selector(sendAsynchronousRequest:queue:completionHandler:));
}

static void swizzleInstance(Class class, SEL originalSelector, SEL swizzledSelector)
{
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

static void swizzleClass(Class class, SEL originalSelector, SEL swizzledSelector)
{
    Method originalMethod = class_getClassMethod(class, originalSelector);
    Method swizzledMethod = class_getClassMethod(class, swizzledSelector);
    
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

- (id)swizzleInitWithRequest:(NSURLRequest *)request delegate:(id <NSURLConnectionDelegate>)delegate startImmediately:(BOOL)startImmediately
{
    [NSURLConnection logInfoWithRequest:request error:nil];
    
    return [self swizzleInitWithRequest:request delegate:delegate startImmediately:startImmediately];
}

- (id)swizzleInitWithRequest:(NSURLRequest *)request delegate:(id <NSURLConnectionDelegate>)delegate
{
    [NSURLConnection logInfoWithRequest:request error:nil];
    
    return [self swizzleInitWithRequest:request delegate:delegate];
}

+ (id)swizzleConnectionWithRequest:(NSURLRequest *)request delegate:(id <NSURLConnectionDelegate>)delegate
{
    [NSURLConnection logInfoWithRequest:request error:nil];
    
    return [self swizzleConnectionWithRequest:request delegate:delegate];
}

+ (void)swizzleSendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue completionHandler:(void (^)(NSURLResponse *, NSData *, NSError *))handler
{
    [NSURLConnection logInfoWithRequest:request error:nil];
    
    [self swizzleSendAsynchronousRequest:request queue:queue completionHandler:handler];
}

+ (void)logInfoWithRequest:(NSURLRequest *)request error:(NSError *)error
{
    NSString *time = [_formatter stringFromDate:[NSDate date]];
    
    NSString *urlString = [request.URL absoluteString];
    NSString *bodyString = nil;
    
    if ([request.HTTPMethod isEqualToString:@"POST"] ||
        [request.HTTPMethod isEqualToString:@"PUT"] ||
        [request.HTTPMethod isEqualToString:@"PATCH"]) {
        bodyString = [[NSString alloc] initWithData:[request HTTPBody]
                                           encoding:NSUTF8StringEncoding];
    }
    
    NSDictionary *headDictionary = request.allHTTPHeaderFields;
    // 简单过滤图片请求
    if (![headDictionary.allKeys containsObject:@"Accept"]) {
        if (!error) {
            NSLog(@"\n🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶\n===============Sending===============\n[TIME]: %@\n[HTTP URL]: %@\n[TYPE]: %@\n[HEADERS]: %@\n[BODY]: %@\n[TIMEOUT]: %@\n===============End===============\n", time, urlString, request.HTTPMethod, headDictionary, bodyString, @(request.timeoutInterval));
        } else {
            NSLog(@"\n😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡\n===============Failed Sending===============\n[TIME]: %@\n[HTTP URL]: %@\n[TYPE]: %@\n[HEADERS]: %@\n[BODY]: %@\n[ERROR]: %@\n===============End===============\n", time, urlString, request.HTTPMethod, headDictionary, bodyString, error.userInfo[NSLocalizedDescriptionKey]);
        }
    }
}

@end
