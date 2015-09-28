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
    
    self.allData = [NSMutableData data];
    
    
//    NSString *paramURLAsString = @"http://118.192.93.31:8038/personInfo";
//    NSURL *url = [NSURL URLWithString:paramURLAsString];
//    self.request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0f];
//    [self.request setHTTPMethod:@"POST"];
//    [self.request setValue:@"Token token=6c73b86978f95d9551f0fdb2fc55ee1f" forHTTPHeaderField:@"Authorization"];
    
    
    NSString *paramURLAsString = @"http://118.192.93.31:8038/api/v1/cheniu_orders/trade_records?order_code=150666513294";
    NSURL *url = [NSURL URLWithString:paramURLAsString];

    // 1 使用协议缓存策略，在HTTP协议的response头中，有一个字段是cache-control，由服务器来告诉客户端如何使用缓存。
    self.request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0f];
    
    // 2 无论缓存是否过期，先使用本地缓存数据。如果缓存中没有请求所对应的数据，那么从原始地址加载数据
//    self.request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60.0f];
    
    // 3 无论缓存是否过期，先使用本地缓存数据。如果缓存中没有请求所对应的数据，那么放弃从原始地址加载数据，请求视为失败（即：“离线”模式）（如果没有缓存，即使联网，也会请求失败）
//    self.request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataDontLoad timeoutInterval:60.0f];
    
    // 4 从原始地址确认缓存数据的合法性后，缓存数据就可以使用，否则从原始地址加载。
//    self.request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadRevalidatingCacheData timeoutInterval:60.0f];
    
    // 5 数据需要从原始地址加载。不使用现有缓存
//    self.request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60.0f];
    
    // 6 不仅忽略本地缓存，同时也忽略代理服务器或其他中间介质目前已有的、协议允许的缓存
//    self.request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60.0f];
    


    [self.request setHTTPMethod:@"GET"];
    [self.request setValue:@"Token token=6c73b86978f95d9551f0fdb2fc55ee1f" forHTTPHeaderField:@"Authorization"];
//    [self.request setValue:@"zh-Hans;q=1" forHTTPHeaderField:@"Accept-Language"];
//    [self.request setValue:@"cheniu_store" forHTTPHeaderField:@"AppName"];
//    [self.request setValue:@"1" forHTTPHeaderField:@"AppBuild"];
//    [self.request setValue:@"cheniu/1.0.0 (iPhone Simulator; iOS 8.4; Scale/2.00)" forHTTPHeaderField:@"User-Agent"];
}

- (IBAction)request:(id)sender {
    /*
     NSURLRequestUseProtocolCachePolicy： 对特定的URL请求使用网络协议中实现的缓存逻辑。这是默认的策略。
     NSURLRequestReloadIgnoringLocalCacheData：数据需要从原始地址加载。不使用现有缓存。
     NSURLRequestReloadIgnoringLocalAndRemoteCacheData：不仅忽略本地缓存，同时也忽略代理服务器或其他中间介质目前已有的、协议允许的缓存。
     NSURLRequestReturnCacheDataElseLoad：无论缓存是否过期，先使用本地缓存数据。如果缓存中没有请求所对应的数据，那么从原始地址加载数据。
     NSURLRequestReturnCacheDataDontLoad：无论缓存是否过期，先使用本地缓存数据。如果缓存中没有请求所对应的数据，那么放弃从原始地址加载数据，请求视为失败（即：“离线”模式）。
     NSURLRequestReloadRevalidatingCacheData：从原始地址确认缓存数据的合法性后，缓存数据就可以使用，否则从原始地址加载。
     */
    
    self.allData.length = 0;
    
    // 从请求中获取缓存输出
//    NSCachedURLResponse *response = [self.urlCache cachedResponseForRequest:self.request];
//    // 判断是否有缓存
//    if (response != nil){
//        NSLog(@"有缓存，从缓存中获取数据");
//        [self.request setCachePolicy:NSURLRequestReturnCacheDataDontLoad];
//    } else {
//        NSLog(@"无缓存，从网络中获取数据");
//    }
    
    NSURLConnection *newConnection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:YES];
    self.connection = newConnection;
}

- (IBAction)clear:(id)sender {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
//    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:]
    NSLog(@"清除缓存成功");
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse{
    NSLog(@"即将发送请求");
    return(request);
}

- (void)connection:(NSURLConnection *)connection
  didReceiveResponse:(NSURLResponse *)response{
    NSLog(@"将接收输出");
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    NSLog(@"接受数据");
    NSLog(@"数据长度为 = %lu", (unsigned long)[data length]);
    
    [self.allData appendData:data];

}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse{
    NSLog(@"将缓存输出: \ndata.length: %ld\nuserInfo: %@\nresponse: %@", cachedResponse.data.length, cachedResponse.userInfo, cachedResponse.response);
    return(cachedResponse);

//    return nil;  // 返回nil则不会缓存
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
