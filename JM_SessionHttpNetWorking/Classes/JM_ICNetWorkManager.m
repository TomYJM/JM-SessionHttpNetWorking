//
//  JM_ICNetWorkManager.m
//  JMTitleTabListView
//
//  Created by tomyang on 2018/4/25.
//  Copyright © 2018年 tomyang. All rights reserved.
//

#import "JM_ICNetWorkManager.h"
#define dispatch_main_async_safe(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}

@implementation JM_ICNetWorkManager
static const int kReconnectTimeInterval = 0;   // 请求失败重连的时间清零值
static const float kHeartTimeInterval = 15.0f; //心跳设置为15s，NAT超时一般为5分钟 3*60.0f
static JM_ICNetWorkManager *_sharedWebSocket;

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedWebSocket = [super allocWithZone:zone];
    });
    return _sharedWebSocket;
}

#pragma mark - api
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init {
    self = [super init];
    if (self) {
        self.sessionArray = [NSMutableArray array];
        fLock_           = [[NSRecursiveLock alloc] init];
        cancelLock_      = [[NSRecursiveLock alloc] init];
        _wsState = JMIC_WsClosed;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityAble:) name:kReachabilityChangedNotification object:nil];
    }
    return self;
}

+ (instancetype)sharedICNetWorkManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedWebSocket = [[self alloc] init];
    });
    return _sharedWebSocket;
}

#pragma mark - Public
//加入请求队列中
- (void)hqzt_startRequest:(id <JM_ICSessionDataStoryProtocol>)baseReq delegate:(id)delegate {
    [fLock_ lock];
    
    JM_ICSessionData *sessionData = [baseReq getRequestData];
    sessionData.delegate = delegate;
    // 记录最新的推送请求
    self.lastReq = baseReq;
    self.lastDelegate = delegate;
    _wsState = JMIC_WsConnecting;
    NSURLSession *session = [self urlRequest:baseReq requestData:sessionData isCutOverSwitch:NO];
    if (session) {
        JM_ICRequestPackage *package = [[JM_ICRequestPackage alloc] init];
        package.baseReq = baseReq;
        package.session = session;
        package.sessionData = sessionData;
        [_sessionArray addObject:package];
    }
    
    [fLock_ unlock];
}

//取消指定的请求包
- (void)hqzt_cancelRequest:(JM_ICSessionData *)requestData object:(id)object {
    for (int i = 0; i < [_sessionArray count]; i++) {
        JM_ICRequestPackage *package = (JM_ICRequestPackage *)[_sessionArray objectAtIndex:i];
        JM_ICSessionData *tempConnectData = package.sessionData;
        NSURLSession *session = package.session;
        
        if (requestData.mainFun == tempConnectData.mainFun
            && requestData.slaveFun == tempConnectData.slaveFun
            && [object isEqual:tempConnectData.delegate]) {
            [session invalidateAndCancel];
            [self destoryHeartBeatRequestData:tempConnectData];
            [_sessionArray removeObjectAtIndex:i];
            break;
        }
    }
}

//取消委托页面的所有请求
- (void)hqzt_cancelObjectRequest:(id)delegate {
    [cancelLock_ lock];
    
    NSMutableArray *newArray = [NSMutableArray array];
    for (int i = 0; i < [_sessionArray count]; i++) {
        JM_ICRequestPackage *package = (JM_ICRequestPackage *)[_sessionArray objectAtIndex:i];
        JM_ICSessionData *tempConnectData = package.sessionData;
        NSURLSession *session = package.session;
        
        if ([delegate isEqual:tempConnectData.delegate]) {
            [session invalidateAndCancel];
            [self destoryHeartBeatRequestData:tempConnectData];
        } else {
            [newArray addObject:package];
        }
    }
    self.sessionArray = newArray;
    [cancelLock_ unlock];
}

//判断请求是否在队列中
- (BOOL)hqzt_isRepeatRequest:(id <JM_ICSessionDataStoryProtocol>)baseReq delegate:(id)delegate {
    for (int i = 0; i < [_sessionArray count]; i++) {
        JM_ICRequestPackage *package = (JM_ICRequestPackage *)[_sessionArray objectAtIndex:i];
        JM_ICSessionData *tempConnectData = package.sessionData;
        
        if (baseReq.mainFun == tempConnectData.mainFun
            && baseReq.slaveFun == tempConnectData.slaveFun
            && [delegate isEqual:tempConnectData.delegate]) {
            return YES;
        }
    }
    return NO;
}

//删除队列中请求
- (void)hqzt_deleteRequest:(JM_ICSessionData *)sessionData {
    for (int i = 0; i < [_sessionArray count]; i++) {
        JM_ICRequestPackage *package = (JM_ICRequestPackage *)[_sessionArray objectAtIndex:i];
        JM_ICSessionData *tempConnectData = package.sessionData;
        NSURLSession *session = package.session;
        
        if (tempConnectData == sessionData) {
            [session invalidateAndCancel];
            [self destoryHeartBeatRequestData:tempConnectData];
            [_sessionArray removeObjectAtIndex:i];
            break;
        }
    }
}

//重新恢复委托页面的所有请求
- (void)hqzt_reStartCurrentObjectRequest {
    if (self.lastDelegate) {
        [self hqzt_cancelRequest:self.lastReq object:self.lastDelegate];
    }
}

//取消当前委托页面的所有请求
- (void)hqzt_cancelCurrentObjectRequest {
    [self hqzt_cancelRequest:self.lastReq object:self.lastDelegate];
}

// 获取当前请求链接对应的请求包
- (JM_ICSessionData *)hqzt_getRequestData:(NSURLSession *)session {
    for (int i = 0; i < [_sessionArray count]; i++) {
        JM_ICRequestPackage *package = (JM_ICRequestPackage *)[_sessionArray objectAtIndex:i];
        NSURLSession *tempConnect = package.session;
        
        if (session == tempConnect) {
            return package.sessionData;
            break;
        }
    }
    return nil;
}

// 获取当前请求链接对应的请求源
- (id <JM_ICSessionDataStoryProtocol>)hqzt_getReq:(NSURLSession *)session {
    for (int i = 0; i < [_sessionArray count]; i++) {
        JM_ICRequestPackage *package = (JM_ICRequestPackage *)[_sessionArray objectAtIndex:i];
        NSURLSession *tempConnect = package.session;
        
        if (session == tempConnect) {
            return package.baseReq;
            break;
        }
    }
    return nil;
}

// 获取当前请求数据链接对应的请求源
- (id <JM_ICSessionDataStoryProtocol>)hqzt_getReqModel:(JM_ICSessionData *)sessionData {
    for (int i = 0; i < [_sessionArray count]; i++) {
        JM_ICRequestPackage *package = (JM_ICRequestPackage *)[_sessionArray objectAtIndex:i];
        JM_ICSessionData *tempData = package.sessionData;
        
        if (sessionData == tempData) {
            return package.baseReq;
            break;
        }
    }
    return nil;
}

//创建请求对象 NSURLConnection   是否切换站点
- (NSURLSession *)urlRequest:(id <JM_ICSessionDataStoryProtocol>)baseReq requestData:(JM_ICSessionData *)sessionData isCutOverSwitch:(BOOL)bSwitch {
    NSInteger timeoutInterval = 60.0f;
    NSString *urlPath = [baseReq urlPathRequest:sessionData isCutOverSwitch:bSwitch];
    NSURL *url = [NSURL URLWithString:urlPath];
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:timeoutInterval];
    [urlRequest setHTTPMethod:@"POST"];
    
    //设置cookie
    //    NSDictionary *headers = [NSHTTPCookie requestHeaderFieldsWithCookies:@[]];
    //    [urlRequest setHTTPShouldHandleCookies:YES];
    //    [urlRequest setAllHTTPHeaderFields:headers];//把cookie添加到请求对象中
    //    [urlRequest setValue:[headers objectForKey:@"Cookie"] forHTTPHeaderField:@"Cookie"];
    [urlRequest setHTTPBody:sessionData.reqData];   //包体
    //    [urlRequest addValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
    
    //其接收数据此时应该用委托方法来接收
    NSURLSessionConfiguration *conf = [NSURLSessionConfiguration defaultSessionConfiguration];
    conf.URLCredentialStorage = nil;
    NSURLSession *mysession = [NSURLSession sessionWithConfiguration:conf delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSessionDataTask *task = [mysession dataTaskWithRequest:urlRequest];
    [task resume];
    
    return mysession;
}

// 重连
- (void)reConnectstartReConnectRequestData:(JM_ICSessionData *)sessionData
                                     error:(NSError *)error
                           isCutOverSwitch:(BOOL)bSwitch {
    dispatch_main_async_safe(^{
        [[JM_ICNetWorkManager sharedICNetWorkManager] hqzt_cancelRequest:sessionData object:sessionData.delegate];
        NSURLSession *session = [self urlRequest:[self hqzt_getReqModel:sessionData] requestData:sessionData isCutOverSwitch:YES];
        if (session) {
            JM_ICRequestPackage *package = [[JM_ICRequestPackage alloc] init];
            package.session = session;
            package.sessionData = sessionData;
            [_sessionArray addObject:package];
        } else {
            NSLog(@"startswitchRequestData return nil, requestData.delegate:%@", sessionData.delegate);
            if ([sessionData.delegate respondsToSelector:@selector(jm_URLDataReceiverFail:error:)]) {
                JM_ICReceiverData *receiverData = [[JM_ICReceiverData alloc] init];
                receiverData.mainFun    = sessionData.mainFun;
                receiverData.slaveFun   = sessionData.slaveFun;
                receiverData.cmdVersion = sessionData.cmdVersion;
                receiverData.url        = sessionData.url;
                receiverData.responseTag = sessionData.reqTag;
                
                [sessionData.delegate jm_URLDataReceiverFail:receiverData error:error];
            }
            [self hqzt_deleteRequest:sessionData];
        }
    });
}

//请求失败重连 切换站点或提示失败
- (void)startReConnectRequestData:(JM_ICSessionData *)sessionData
                            error:(NSError *)error
                  isCutOverSwitch:(BOOL)bSwitch {
    [[JM_ICNetWorkManager sharedICNetWorkManager] hqzt_deleteRequest:sessionData];
    //超过一分钟就不再重连 所以只会重连5次 2^5 = 64
    if (sessionData.reConnectTime > 64) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kICNetConnectStatusChangedNotification object:[NSNumber numberWithBool:NO]];
        _wsState = JMIC_WsClosed;
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sessionData.reConnectTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self reConnectstartReConnectRequestData:sessionData error:error isCutOverSwitch:bSwitch];
    });
    
    //重连时间2的指数级增长
    if (sessionData.reConnectTime == kReconnectTimeInterval) {
        sessionData.reConnectTime = 2;
    } else {
        sessionData.reConnectTime *= 2;
    }
}

/** 添加心跳定时器 */
- (void)initHeartBeatRequestData:(JM_ICSessionData *)sessionData {
    if (sessionData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self destoryHeartBeatRequestData:sessionData];
            //心跳设置为15秒钟，NAT超时一般为5分钟
            sessionData.heartBeat = [NSTimer scheduledTimerWithTimeInterval:kHeartTimeInterval target:self selector:@selector(longConnectHeartBeatAction:) userInfo:sessionData repeats:NO];
            [[NSRunLoop currentRunLoop] addTimer:sessionData.heartBeat forMode:NSRunLoopCommonModes];
        });
    }
}

/** 取消心跳检测 */
- (void)destoryHeartBeatRequestData:(JM_ICSessionData *)sessionData {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (sessionData.heartBeat) {
            [sessionData.heartBeat invalidate];
            sessionData.heartBeat = nil;
        }
    });
}

/** 心跳检测 */
- (void)longConnectHeartBeatAction:(NSTimer *)heartBeat {
    NSLog(@"heart");
    if (heartBeat.userInfo && [heartBeat.userInfo isKindOfClass:[JM_ICSessionData class]]) {
        JM_ICSessionData *sessionData = (JM_ICSessionData *)heartBeat.userInfo;
        //TODO: 心跳时间没返回数据，并且没有发生请求失败重连，就重新发起请求
        if (sessionData.reConnectTime == 0) {
            [self reConnectstartReConnectRequestData:sessionData error:nil isCutOverSwitch:NO];
        }
    }
}

#pragma mark - NSURLSessionDataDelegate
//1:接收响应的方法
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(nonnull NSURLResponse *)response completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition))completionHandler {
    //返回的包头信息
    JM_ICSessionData *sessionData = [self hqzt_getRequestData:session];
    // 重连时间清零
    sessionData.reConnectTime = kReconnectTimeInterval;
    sessionData.receiveResponse = response;
    // 连接成功
    [[NSNotificationCenter defaultCenter] postNotificationName:kICNetConnectStatusChangedNotification object:[NSNumber numberWithBool:YES]];
    _wsState = JMIC_WsOpen;
    completionHandler(NSURLSessionResponseAllow);
}

//2:接收数据的方法,这个方法有可能被调用很多次，每调一次收到服务器的一股数据
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(nonnull NSData *)data {
    JM_ICSessionData *sessionData = [self hqzt_getRequestData:session];
    // 重连时间清零
    sessionData.reConnectTime = kReconnectTimeInterval;
    sessionData.receiveData = [NSMutableData dataWithData:data];
    JM_ICReceiverData *receiverData = [[JM_ICReceiverData alloc] init];
    receiverData.mainFun    = sessionData.mainFun;
    receiverData.slaveFun   = sessionData.slaveFun;
    receiverData.cmdVersion = sessionData.cmdVersion;
    receiverData.url        = sessionData.url;
    receiverData.responseTag = sessionData.reqTag;
    NSLog(@"data%@----字节长度%d",sessionData.receiveData,(unsigned)sessionData.receiveData.length);
    
    //接收推送数据包开始发送心跳
    [self initHeartBeatRequestData:sessionData];
    if (data.length > 0) {
        NSString *className = [[self hqzt_getReq:session] hqts_gpbMessage:receiverData.mainFun subFun:receiverData.slaveFun];
        receiverData.data = [[self hqzt_getReq:session] handleReceiverData:data parseClassName:className];
        if (!receiverData.data) {
            receiverData.data     = nil;
            receiverData.errorNo  = 0;
            receiverData.errorMeg = @"网路繁忙!";
        } else {
            int code = [[self hqzt_getReq:session] hqts_gpbCode:receiverData.mainFun subFun:receiverData.slaveFun data:receiverData.data];
            if (code != 0 && code != 1) {
                receiverData.data = nil;
                receiverData.errorMeg = [NSString stringWithFormat:@"%@！！",[[self hqzt_getReq:session] hqts_gpbMessage:receiverData.mainFun subFun:receiverData.slaveFun data:receiverData.data]];
                receiverData.errorNo  = 0;
            }
        }
    } else {
        receiverData.data = nil;
        receiverData.errorMeg = @"网路繁忙!";
        receiverData.errorNo  = 0;
    }
    if (!receiverData.data
        || receiverData.errorNo!=0
        || receiverData.errorMeg) {
        // 返回数据为空 或者二进制数据返回错误
        if (sessionData.delegate && [(id)sessionData.delegate respondsToSelector:@selector(jm_URLDataReceiverDidFinishButError:)]) {
            [sessionData.delegate performSelector:@selector(jm_URLDataReceiverDidFinishButError:)
                                       withObject:receiverData];
        }
    } else {   // 返回数据不为空
        if (sessionData.delegate && [(id)sessionData.delegate respondsToSelector:@selector(jm_URLDataReceiverDidFinish:)]) {
            [sessionData.delegate performSelector:@selector(jm_URLDataReceiverDidFinish:) withObject:receiverData];
        }
    }
}

// 3:请求完成
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    JM_ICSessionData *sessionData = [self hqzt_getRequestData:session];
    JM_ICReceiverData *receiverData = [[JM_ICReceiverData alloc] init];
    receiverData.mainFun    = sessionData.mainFun;
    receiverData.slaveFun   = sessionData.slaveFun;
    receiverData.cmdVersion = sessionData.cmdVersion;
    receiverData.url        = sessionData.url;
    receiverData.responseTag = sessionData.reqTag;
    
    NSLog(@"receiverData：main:%d slave:%d cmdVersion:%d userInfo = %@", receiverData.mainFun, receiverData.slaveFun, receiverData.cmdVersion, error.userInfo);
    if (NotReachable == [[Reachability reachabilityForInternetConnection] currentReachabilityStatus]) {
        self.netWorkstatus = NotReachable;
        [[NSNotificationCenter defaultCenter] postNotificationName:kICNetConnectStatusChangedNotification object:[NSNumber numberWithBool:NO]];
        _wsState = JMIC_WsClosed;
        return;
    }
    if (error.code > JMHQZT_SessionStatusCode_CError
        && error.code <= JMHQZT_SessionStatusCode_SError) {
        NSLog(@"返回正确------切换站点   错误码：%ld",(long)error.code);
        [self startReConnectRequestData:sessionData error:error isCutOverSwitch:YES];
        return;
    }
    if (error.code > JMHQZT_SessionStatusCode_SeError
        && error.code <= JMHQZT_SessionStatusCode_CError) {
        NSLog(@"网络不稳定重连   错误码：%ld",(long)error.code);
        [self startReConnectRequestData:sessionData error:error isCutOverSwitch:NO];
        return;
    }
    // 失败信息
    if (error != nil) {
        if (sessionData.delegate && [sessionData.delegate respondsToSelector:@selector(jm_URLDataReceiverFail:error:)]) {
            [sessionData.delegate jm_URLDataReceiverFail:receiverData error:error];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kICNetConnectStatusChangedNotification object:[NSNumber numberWithBool:NO]];
    _wsState = JMIC_WsClosed;
    [[JM_ICNetWorkManager sharedICNetWorkManager] hqzt_deleteRequest:sessionData];
}

/**
 *  监控网络状态改变
 *
 *  @param note 通知
 */
- (void)reachabilityAble:(NSNotification *)note {
    Reachability *curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    NetworkStatus status = [curReach currentReachabilityStatus];
    
    if (NotReachable != status && NotReachable == self.netWorkstatus) {
        self.netWorkstatus = status;
        if (_sessionArray.count) {
            JM_ICRequestPackage *package = (JM_ICRequestPackage *)[_sessionArray firstObject];
            JM_ICSessionData *sessionData = package.sessionData;
            [self startReConnectRequestData:sessionData error:nil isCutOverSwitch:NO];
        }
    }
}
@end
