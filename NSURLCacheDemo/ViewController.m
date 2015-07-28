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
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.urlCache = [NSURLCache sharedURLCache];
    // 设置缓存的大小为1MB
    [self.urlCache setMemoryCapacity:1*1024*1024];
    
    NSString *paramURLAsString= @"http://www.baidu.com";
    
    NSURL *url = [NSURL URLWithString:paramURLAsString];
    self.request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0f];
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
    
    // 从请求中获取缓存输出
    NSCachedURLResponse *response = [self.urlCache cachedResponseForRequest:self.request];
    // 判断是否有缓存
    if (response != nil){
        NSLog(@"有缓存，从缓存中获取数据");
        [self.request setCachePolicy:NSURLRequestReturnCacheDataDontLoad];
    } else {
        NSLog(@"无缓存，从网络中获取数据");
    }
    
    NSURLConnection *newConnection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:YES];
    self.connection = newConnection;
}

- (IBAction)clear:(id)sender {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSLog(@"清除缓存成功，下一次请求将从网络获取");
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
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse{
    NSLog(@"将缓存输出: \ndata.length: %ld\nuserInfo: %@\nresponse: %@", cachedResponse.data.length, cachedResponse.userInfo, cachedResponse.response);
    return(cachedResponse);
//    return nil;  // 返回nil则不会缓存
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSLog(@"请求完成");
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSLog(@"请求失败");
}

@end
