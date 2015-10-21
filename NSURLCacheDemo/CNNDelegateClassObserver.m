//
//  CNNDelegateClassObserver.m
//  WordPress
//
//  Created by wildyao on 15/8/29.
//  Copyright (c) 2015年 WordPress. All rights reserved.
//

#import "CNNDelegateClassObserver.h"
#import <objc/runtime.h>
#import <objc/message.h>
//#import <AFNetworking/AFHTTPRequestOperation.h>
#import <UIKit/UIKit.h>
#import "NSURLConnection+CNNSwizzled.h"

static BOOL _injectReceiveResponse = NO;
static BOOL _injectFinished = NO;
static BOOL _injectFailed = NO;
static BOOL _logoVariableType = NO;
static BOOL _simpleFinishedInfo = NO;
static BOOL _injectSelectRow = NO;

static NSDateFormatter *_formatter;

@class AFMultipartBodyStream;

@implementation CNNDelegateClassObserver

+ (void)cnn_injectConnectionStartSending:(BOOL)injectSending didReceiveResponse:(BOOL)injectReceiveResponse didFinishLoading:(BOOL)injectFinished didFailWithError:(BOOL)injectFailed logVariableType:(BOOL)logVariableType simpleFinishedInfoIfInjectFinished:(BOOL)simpleFinishedInfo didSelectRowAtIndexPath:(BOOL)injectSelectRow
{
    [NSURLConnection cnn_injectConnectionStartSending:injectSending];
    
    _injectReceiveResponse = injectReceiveResponse;
    _injectFinished = injectFinished;
    _injectFailed = injectFailed;
    _logoVariableType = logVariableType;
    _simpleFinishedInfo = simpleFinishedInfo;
    _injectSelectRow = injectSelectRow;
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

#ifdef DEBUG
+ (void)load
{
    dispatch_async(dispatch_get_main_queue(), ^{
        initializeDateFormatter();
        [self injectIntoDelegateClasses];
    });
}
#endif

+ (void)injectIntoDelegateClass:(Class)cls
{
    if (_injectFinished) {
        [self injectDidFinishLoadingIntoDelegateClass:cls];
    }
    
    if (_injectFailed) {
        [self injectDidFailWithErrorIntoDelegateClass:cls];
    }
    
    if (_injectReceiveResponse) {
        [self injectDidReceiveResponseIntoDelegateClass:cls];
    }
    
    if (_injectSelectRow) {
        [self injectDidSelectRowAtIndexPath:cls];
    }
}

+ (void)injectIntoDelegateClasses
{
    // 需要swizzle的SEL
    const SEL selectors[] = {
        // NSURLConnection
        @selector(connectionDidFinishLoading:),
        @selector(connection:willSendRequest:redirectResponse:),
        @selector(connection:didReceiveResponse:),
        @selector(connection:didReceiveData:),
        @selector(connection:didFailWithError:),
        // UITableView
        @selector(tableView:didSelectRowAtIndexPath:)
    };
    
    const int numSelectors = sizeof(selectors) / sizeof(SEL);
    
    Class *classes = NULL;
    int numClasses = objc_getClassList(NULL, 0);
    
    if (numClasses > 0) {
        // 所有类数组
        classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
        // 类数目
        numClasses = objc_getClassList(classes, numClasses);
        // 遍历所有类
        for (NSInteger classIndex = 0; classIndex < numClasses; ++classIndex) {
            Class class = classes[classIndex];
            
            unsigned int methodCount = 0;
            
            // 获取该类方法数组
            Method *methods = class_copyMethodList(class, &methodCount);
            BOOL matchingSelectorFound = NO;
            
            // 查看是否有和约定SEL一样的
            for (unsigned int methodIndex = 0; methodIndex < methodCount; methodIndex++) {
                for (int selectorIndex = 0; selectorIndex < numSelectors; ++selectorIndex) {
                    if (method_getName(methods[methodIndex]) == selectors[selectorIndex]) {
                        // 发现匹配
                        [self injectIntoDelegateClass:class];
                        matchingSelectorFound = YES;
                        break;
                    }
                }
                if (matchingSelectorFound) {
                    break;
                }
            }
            free(methods);
        }
        
        free(classes);
    }
}

// tableView:didSelectRowAtIndexPath
+ (void)injectDidSelectRowAtIndexPath:(Class)cls
{
    SEL originalSelector = @selector(tableView:didSelectRowAtIndexPath:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:originalSelector];
    
    typedef void (^UITableViewDidSelectRowAtIndexPathBlock)(id <UITableViewDelegate> slf, UITableView *tableView, NSIndexPath *indexPath);
    
    
    UITableViewDidSelectRowAtIndexPathBlock undefinedBlock = ^(id <UITableViewDelegate> slf, UITableView *tableView, NSIndexPath *indexPath) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    };
    
    UITableViewDidSelectRowAtIndexPathBlock implementationBlock = ^(id <UITableViewDelegate> slf, UITableView *tableView, NSIndexPath *indexPath) {
        [self sniffWithoutDuplicationForObject:tableView selector:originalSelector sniffingBlock:^{
            undefinedBlock(slf, tableView, indexPath);
        } originalImplementationBlock:^{
            ((void(*)(id, SEL, id, id))objc_msgSend)(slf, swizzledSelector, tableView, indexPath);
        }];
    };
    
    // 代理协议
    Protocol *protocol = @protocol(NSURLConnectionDataDelegate);
    if (!protocol) {
        protocol = @protocol(NSURLConnectionDelegate);
    }
    // 代理方法描述
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, originalSelector, NO, YES);
    
    [self replaceImplementationOfSelector:originalSelector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}


// connectionDidFinishLoading:
+ (void)injectDidFinishLoadingIntoDelegateClass:(Class)cls
{
    SEL originalSelector = @selector(connectionDidFinishLoading:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:originalSelector];
    
    typedef void (^NSURLConnectionDidFinishLoadingBlock)(id <NSURLConnectionDelegate> slf, NSURLConnection *connection);
    
    NSURLConnectionDidFinishLoadingBlock undefinedBlock = ^(id <NSURLConnectionDelegate> slf, NSURLConnection *connection) {
        [self logoDidFinishedLoadingResponseWithDelegateReceiver:slf andConnection:connection];
    };
    
    NSURLConnectionDidFinishLoadingBlock implementationBlock = ^(id <NSURLConnectionDelegate> slf, NSURLConnection *connection) {
        [self sniffWithoutDuplicationForObject:connection selector:originalSelector sniffingBlock:^{
            undefinedBlock(slf, connection);
        } originalImplementationBlock:^{
            ((void(*)(id, SEL, id))objc_msgSend)(slf, swizzledSelector, connection);
        }];
    };
    
    // 代理协议
    Protocol *protocol = @protocol(NSURLConnectionDataDelegate);
    if (!protocol) {
        protocol = @protocol(NSURLConnectionDelegate);
    }
    // 代理方法描述
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, originalSelector, NO, YES);
    
    [self replaceImplementationOfSelector:originalSelector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

// connection:didFailWithError:
+ (void)injectDidFailWithErrorIntoDelegateClass:(Class)class
{
    SEL originalSelector = @selector(connection:didFailWithError:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:originalSelector];
    
    typedef void (^NSURLConnectionDidFailWithErrorBlock)(id <NSURLConnectionDelegate> slf, NSURLConnection *connection, NSError *error);
    
    NSURLConnectionDidFailWithErrorBlock undefinedBlock = ^(id <NSURLConnectionDelegate> slf, NSURLConnection *connection, NSError *error) {
        [self logDidFailInfoWithRequest:connection.currentRequest error:error];
    };
    
    NSURLConnectionDidFailWithErrorBlock implementationBlock = ^(id <NSURLConnectionDelegate> slf, NSURLConnection *connection, NSError *error) {
        [self sniffWithoutDuplicationForObject:connection selector:originalSelector sniffingBlock:^{
            undefinedBlock(slf, connection, error);
        } originalImplementationBlock:^{
            ((void(*)(id, SEL, id, id))objc_msgSend)(slf, swizzledSelector, connection, error);
        }];
    };
    
    // 代理协议
    Protocol *protocol = @protocol(NSURLConnectionDelegate);
    // 代理方法描述
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, originalSelector, NO, YES);
    
    [self replaceImplementationOfSelector:originalSelector withSelector:swizzledSelector forClass:class withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

+ (void)injectDidReceiveResponseIntoDelegateClass:(Class)class
{
    SEL originalSelector = @selector(connection:didReceiveResponse:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:originalSelector];
    
    typedef void (^NSURLConnectionDidReceiveResponseBlock)(id <NSURLConnectionDelegate> slf, NSURLConnection *connection, NSURLResponse *response);
    
    NSURLConnectionDidReceiveResponseBlock undefinedBlock = ^(id <NSURLConnectionDelegate> slf, NSURLConnection *connection, NSURLResponse *response) {
        [self logDidReceiveResponseWithDelegateReceiver:slf connection:connection response:response];
    };
    
    NSURLConnectionDidReceiveResponseBlock implementationBlock = ^(id <NSURLConnectionDelegate> slf, NSURLConnection *connection, NSURLResponse *response) {
        [self sniffWithoutDuplicationForObject:connection selector:originalSelector sniffingBlock:^{
            undefinedBlock(slf, connection, response);
        } originalImplementationBlock:^{
            ((void(*)(id, SEL, id, id))objc_msgSend)(slf, swizzledSelector, connection, response);
        }];
    };
    
    // 代理协议
    Protocol *protocol = @protocol(NSURLConnectionDataDelegate);
    if (!protocol) {
        protocol = @protocol(NSURLConnectionDelegate);
    }
    // 代理方法描述
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, originalSelector, NO, YES);
    
    [self replaceImplementationOfSelector:originalSelector withSelector:swizzledSelector forClass:class withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}


/**
 * @param seletor              origin selector
 * @param swizzledSelector     swizzled selector
 * @param cls                  swizzled class
 * @param implementationBlock  实现block
 */
+ (void)replaceImplementationOfSelector:(SEL)originalSelector withSelector:(SEL)swizzledSelector forClass:(Class)class withMethodDescription:(struct objc_method_description)methodDescription implementationBlock:(id)implementationBlock undefinedBlock:(id)undefinedBlock
{
    if ([self instanceRespondsButDoesNotImplementSelector:originalSelector class:class]) {
        return;
    }
    
    // 新实现
    IMP swizzledImplementation = imp_implementationWithBlock((id)([class instancesRespondToSelector:originalSelector] ? implementationBlock : undefinedBlock));
    // old method
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    
    if (originalMethod) {       // old method存在
        // 将new selector指向block实现
        class_addMethod(class, swizzledSelector, swizzledImplementation, methodDescription.types);
        // 获取新实现的method
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        // 交换实现
        method_exchangeImplementations(originalMethod, swizzledMethod);
    } else {                // 不存在，将origin selector指向新实现
        class_addMethod(class, originalSelector, swizzledImplementation, methodDescription.types);
    }
}


+ (void)logDidReceiveResponseWithDelegateReceiver:(id <NSURLConnectionDelegate>)slf connection:(NSURLConnection *)connection response:(NSURLResponse *)response
{
    NSString *time = [_formatter stringFromDate:[NSDate date]];
    
    NSURLRequest *request = connection.currentRequest;
    NSString *urlString = [request.URL absoluteString];
    
    NSDictionary *headDictionary = request.allHTTPHeaderFields;
    // 简单过滤图片请求
    if (![headDictionary.allKeys containsObject:@"Accept"]) {
        NSLog(@"\n🐸🐸🐸🐸🐸🐸🐸🐸🐸🐸🐸🐸🐸🐸🐸🐸🐸🐸\n===============Receive Response===============\n[TIME]: %@\n[HTTP URL]: %@\n[TYPE]: %@\n[STATUSCODE]: %@\n[HEADERS]: %@\n===============End===============\n", time, urlString, request.HTTPMethod, @(((NSHTTPURLResponse *)response).statusCode), ((NSHTTPURLResponse *)response).allHeaderFields);
    }
}

+ (void)logoDidFinishedLoadingResponseWithDelegateReceiver:(id <NSURLConnectionDelegate>)slf andConnection:(NSURLConnection *)connection
{
    if (_simpleFinishedInfo) {
        NSURLRequest *request = connection.currentRequest;
        NSString *urlString = [request.URL absoluteString];
        NSString *time = [_formatter stringFromDate:[NSDate date]];
        NSLog(@"\n😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄😄\n---------------Finished---------------\n[TIME]: %@\n[URL]: %@\n", time, urlString);
    } else {
        /*
        if ([slf isKindOfClass:[AFHTTPRequestOperation class]]) {
            
            NSURLRequest *request = connection.currentRequest;
            NSDictionary *headDictionary = request.allHTTPHeaderFields;
            if (![headDictionary.allKeys containsObject:@"Accept"]) {
                AFHTTPRequestOperation *afOperation = (AFHTTPRequestOperation *)slf;
                NSData *responseData = [afOperation.outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
                if (responseData) {
                    NSError *error = nil;
                    id JSON = [NSJSONSerialization JSONObjectWithData:responseData
                                                              options:NSJSONReadingAllowFragments
                                                                error:&error];
                    if (error != nil) {
                        return;
                    }
                    
                    NSString *urlString = [request.URL absoluteString];
                    NSString *time = [_formatter stringFromDate:[NSDate date]];
                    NSLog(@"\n😝😝😝😝😝😝😝😝😝😝😝😝😝😝😝😝😝\n---------------Response---------------\n[TIME]: %@\n[URL]: %@\n[RESPONSE]: %@\n---------------End---------------\n", time, urlString, JSON);
                    
                    if (_logoVariableType) {
                        NSMutableSet *containerSet = [NSMutableSet set];
                        if ([JSON isKindOfClass:[NSDictionary class]]) {
                            [self traverseDictionary:JSON set:containerSet];
                        } else if ([JSON isKindOfClass:[NSArray class]]) {
                            [self traverseArray:JSON set:containerSet];
                        } else {
                            [containerSet addObject:[NSString stringWithFormat:@"Obj %@   isKindOfClass:   %@", JSON, NSStringFromClass([JSON class])]];
                        }
                        
                        NSLog(@"\n😈😈😈😈😈😈😈😈😈😈😈😈😈😈😈😈😈😈😈😈😈\n~~~~~~~~~~~~~~~Variable Type Set~~~~~~~~~~~~~~~\n[URL]: %@\n[TYPE SET]: \n%@\n~~~~~~~~~~~~~~~End~~~~~~~~~~~~~~~\n", urlString, containerSet);
                    }
                }
                
            }
        }
         */
    }
}

+ (void)logDidFailInfoWithRequest:(NSURLRequest *)request error:(NSError *)error
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
        NSLog(@"\n😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡\n===============Failed===============\n[TIME]: %@\n[HTTP URL]: %@\n[TYPE]: %@\n[HEADERS]: %@\n[BODY]: %@\n[ERROR]: %@\n===============End===============\n", time, urlString, request.HTTPMethod, headDictionary, bodyString, error.userInfo[NSLocalizedDescriptionKey]);
    }
}

// 遍历json
+ (void)traverseDictionary:(NSDictionary *)dictionary set:(NSMutableSet *)containerSet
{
    NSArray *keys = [dictionary allKeys];
    for (NSString *key in keys) {
        id obj = dictionary[key];
        if ([obj isKindOfClass:[NSDictionary class]]) {
            [self traverseDictionary:obj set:containerSet];
        } else if ([obj isKindOfClass:[NSArray class]]) {
            [self traverseArray:obj set:containerSet];
        } else {
            if (![obj isKindOfClass:[NSNull class]]) {
                [containerSet addObject:[NSString stringWithFormat:@"Key [%@]   isKindOfClass   [%@]", key, NSStringFromClass([obj class])]];
            }
        }
    }
}

+ (void)traverseArray:(NSArray *)array set:(NSMutableSet *)containerSet
{
    for (id obj in array) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            [self traverseDictionary:obj set:containerSet];
        } else if ([obj isKindOfClass:[NSArray class]]) {
            [self traverseArray:obj set:containerSet];
        } else {
            if (![obj isKindOfClass:[NSNull class]]) {
                [containerSet addObject:[NSString stringWithFormat:@"Obj [%@]   isKindOfClass   [%@]", obj, NSStringFromClass([obj class])]];
            }
        }
    }
}

+ (SEL)swizzledSelectorForSelector:(SEL)selector
{
    return NSSelectorFromString([NSString stringWithFormat:@"swizzle_%@_%x", NSStringFromSelector(selector), arc4random()]);
}

+ (BOOL)instanceRespondsButDoesNotImplementSelector:(SEL)selector class:(Class)cls
{
    if ([cls instancesRespondToSelector:selector]) {
        unsigned int numMethods = 0;
        Method *methods = class_copyMethodList(cls, &numMethods);
        
        // 是否实现了方法
        BOOL implementsSelector = NO;
        for (int index = 0; index < numMethods; index++) {
            SEL methodSelector = method_getName(methods[index]);
            if (selector == methodSelector) {
                implementsSelector = YES;
                break;
            }
        }
        
        free(methods);
        
        if (!implementsSelector) {
            return YES;
        }
    }
    
    return NO;
}


/// All swizzled delegate methods should make use of this guard.
/// This will prevent duplicated sniffing when the original implementation calls up to a superclass implementation which we've also swizzled.
/// The superclass implementation (and implementations in classes above that) will be executed without inteference if called from the original implementation.
+ (void)sniffWithoutDuplicationForObject:(NSObject *)object selector:(SEL)selector sniffingBlock:(void (^)(void))sniffingBlock originalImplementationBlock:(void (^)(void))originalImplementationBlock
{
    // If we don't have an object to detect nested calls on, just run the original implmentation and bail.
    // This case can happen if someone besides the URL loading system calls the delegate methods directly.
    if (!object) {
        originalImplementationBlock();
        return;
    }
    
    const void *key = selector;
    
    // Don't run the sniffing block if we're inside a nested call
    if (!objc_getAssociatedObject(object, key)) {
        sniffingBlock();
    }
    
    // Mark that we're calling through to the original so we can detect nested calls
    
    // key是SEL
    objc_setAssociatedObject(object, key, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    originalImplementationBlock();
    objc_setAssociatedObject(object, key, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
