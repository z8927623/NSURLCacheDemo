//
//  ViewController.m
//  NSURLCacheDemo
//
//  Created by wildyao on 15/2/18.
//  Copyright (c) 2015年 wildyao. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableURLRequest *request;
@property (nonatomic, strong) NSURLCache *urlCache;
@property (nonatomic, strong) NSMutableData *allData;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    

//    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024 diskCapacity:20 * 1024 * 1024 diskPath:nil];
//    [NSURLCache setSharedURLCache:URLCache];
    
    
    self.allData = [NSMutableData data];
    
    NSString *paramURLAsString = @"http://118.192.93.31:8038/api/v1/cheniu_orders/trade_records?order_code=150666513294";
    NSURL *url = [NSURL URLWithString:paramURLAsString];
    
    // 1 使用协议缓存策略，在HTTP协议的response头中，有一个字段是cache-control，由服务器来告诉客户端如何使用缓存。
    self.request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0f];
    
    // 2、数据需要从原始地址加载，不使用现有缓存
//    self.request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60.0f];
    
    // 3、无论缓存是否过期，先使用本地缓存数据，如果缓存中没有请求所对应的数据，那么从原始地址加载数据
//    self.request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60.0f];
    
    // 4、无论缓存是否过期，先使用本地缓存数据，如果缓存中没有请求所对应的数据，那么放弃从原始地址加载数据，请求视为失败（即：“离线”模式）
//    self.request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataDontLoad timeoutInterval:60.0f];


    [self.request setHTTPMethod:@"GET"];
    [self.request setValue:@"Token token=6c73b86978f95d9551f0fdb2fc55ee1f" forHTTPHeaderField:@"Authorization"];
}

- (IBAction)request:(id)sender {
    
    self.allData.length = 0;
    
    NSString *logInfo = nil;
    
    NSURLRequestCachePolicy cachePolicy = self.request.cachePolicy;
    if (cachePolicy == NSURLRequestUseProtocolCachePolicy) {
        logInfo = [NSString stringWithFormat:@"\n缓存政策为：NSURLRequestUseProtocolCachePolicy"];
        
        NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:self.request];
        
        if (cachedResponse) {
            
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)cachedResponse.response;
            
            logInfo = [logInfo stringByAppendingFormat:@"\n缓存命中"];
            
            NSDictionary *headers = response.allHeaderFields;
            if ([headers objectForKey:@"cache-control"]) {
                NSString *cacheControl = headers[@"cache-control"];
                if ([cacheControl containsString:@"must-revalidate"]) {
                    logInfo = [logInfo stringByAppendingFormat:@"\nResponse含有must-revalidate字段，从服务器验证，发送HEAD请求（只返回头部信息）判断资源是否已修改，如果返回304 Not Modified，则使用缓存；否则，从原始地址加载"];
                } else {
                    logInfo = [logInfo stringByAppendingFormat:@"\nResponse没有must-revalidate字段，检验max-age或expired字段，如果判断出来足够新，则使用缓存，返回response；否则，从服务器验证，发送HEAD请求（只返回头部信息）判断资源是否已修改，如果返回304 Not Modified，则使用缓存；否则，从原始地址加载"];
                }
            }
        } else {
            logInfo = [logInfo stringByAppendingFormat:@"\n缓存不存在，从原始地址加载"];
        }
    } else if (cachePolicy == NSURLRequestReloadIgnoringLocalCacheData) {
        logInfo = @"\n缓存政策为：NSURLRequestReloadIgnoringLocalCacheData\n每次都从网络加载，不使用缓存";
    } else if (cachePolicy == NSURLRequestReturnCacheDataElseLoad) {
  
        logInfo = [NSString stringWithFormat:@"\n缓存政策为：NSURLRequestReturnCacheDataElseLoad"];

        NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:self.request];
        
        if (cachedResponse) {
            logInfo = [logInfo stringByAppendingFormat:@"\n缓存命中"];
            logInfo = [logInfo stringByAppendingFormat:@"\n使用本地数据"];
        } else {
            logInfo = [logInfo stringByAppendingFormat:@"\n缓存不存在，从原始地址加载"];
        }
        
    } else if (cachePolicy == NSURLRequestReturnCacheDataDontLoad) {
        
        logInfo = [NSString stringWithFormat:@"\n缓存政策为：NSURLRequestReturnCacheDataDontLoad"];
        
        NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:self.request];
        
        if (cachedResponse) {
            logInfo = [logInfo stringByAppendingFormat:@"\n缓存命中"];
            logInfo = [logInfo stringByAppendingFormat:@"\n使用本地数据"];
        } else {
            logInfo = [logInfo stringByAppendingFormat:@"\n缓存不存在，放弃从原始地址加载数据，请求视为失败（即：“离线”模式）"];
        }
    }
    
    NSLog(@"%@", logInfo);
    
    NSURLConnection *newConnection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:YES];
    self.connection = newConnection;
}

- (IBAction)clear:(id)sender {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
//    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:]
    NSLog(@"清除缓存成功");
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    return(request);
}

- (void)connection:(NSURLConnection *)connection
  didReceiveResponse:(NSURLResponse *)response{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    [self.allData appendData:data];
}

// 响应头部有缓存相关的字段，如cache-control
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    /////////////////////////////// 当我们不需要缓存的时候，返回nil则不会缓存
//    return nil;
    
    ////////////////////////////// 可以修改缓存的内容
//    NSMutableDictionary *mutableUserInfo = [[cachedResponse userInfo] mutableCopy];
//    NSError *error = nil;
//    NSMutableDictionary *jsonDictionary = [[NSJSONSerialization JSONObjectWithData:[cachedResponse data] options:NSJSONReadingAllowFragments error:&error] mutableCopy];
//    NSParameterAssert(error == nil);
//    [jsonDictionary setObject:@"Hi" forKeyedSubscript:@"Hello"];
//    NSData *modifiedData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:NSJSONWritingPrettyPrinted error:&error];
//    NSParameterAssert(error == nil);
//    NSURLCacheStoragePolicy storagePolicy = NSURLCacheStorageAllowed;
//    
//    return [[NSCachedURLResponse alloc] initWithResponse:[cachedResponse response]
//                                                    data:modifiedData
//                                                userInfo:mutableUserInfo
//                                           storagePolicy:storagePolicy];
    
    return cachedResponse;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSLog(@"请求完成");
    
    NSError *error = nil;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:self.allData options:NSJSONReadingAllowFragments error:&error];
    if (!error) {
        NSLog(@"dic: %@", dic);
    } else {
        NSLog(@"error: %@", error);
    }
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSLog(@"请求失败");
}

@end
