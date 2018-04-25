//
//  JM_ICNetWorkManager.h
//  JMTitleTabListView
//
//  Created by tomyang on 2018/4/25.
//  Copyright © 2018年 tomyang. All rights reserved.
//
/** icomet服务器技术 支持http长连接行情主推 */
#import <Foundation/Foundation.h>
#import "JM_TCPReachabilityManager.h"
#import "JM_ICSessionData.h"
#import "JM_ICReceiverData.h"
#import "JM_ICRequestPackage.h"
#import "JM_ICSessionDataStory.h"
#define kICNetConnectStatusChangedNotification @"kICNetConnectStatusChangedNotification"

/** 对应 SRReadyState */
typedef NS_ENUM(NSInteger, JMIC_WsReadyState) {
    JMIC_WsConnecting = 0,    ///< 未连接
    JMIC_WsOpen       = 1,    ///< 已连接
    JMIC_WsClosed     = 2,    ///< 已断开
};

/*********************************网络请求需要的数据集  end***********************************/

/** 服务器返回的状态码 */
typedef enum {
    JMHQZT_SessionStatusCode_SError = -1001,      // 服务器原因失败
    JMHQZT_SessionStatusCode_CError = -1009,      // 客户端没有网络原因失败
    JMHQZT_SessionStatusCode_SeError   = -1200       // 网络安全验证问题
}JMHQZT_SessionStatusCode;

/*!
 * @abstract URLDataReceiverDelegate protocol.
 */
@protocol JM_URLDataReceiverDelegate
/*!
 * @abstract Notify delegate that loading has finished.
 *
 * The delegate can use lastError to query if there is any error.
 */
@optional
/** 网络请求成功 */
- (void)jm_URLDataReceiverDidFinish:(JM_ICReceiverData *)receiverData;
/** 网络请求成功但是逻辑错误(携带网络返回的错误信息) */
- (void)jm_URLDataReceiverDidFinishButError:(JM_ICReceiverData *)receiverData;
/** 网络请求错误 */
- (void)jm_URLDataReceiverFail:(JM_ICReceiverData *)receiverData error:(NSError *)error;

@end

@interface JM_ICNetWorkManager : NSObject<NSURLSessionDelegate> {
    NSRecursiveLock *fLock_;
    NSRecursiveLock *cancelLock_;
}
@property (nonatomic, retain) NSMutableArray *sessionArray;
/** 最后连接的请求 */
@property (nonatomic, retain) id lastReq;
/** 最后连接请求的委托界面 */
@property (nonatomic, weak)   id lastDelegate;
/** 当前连接状态 */
@property (nonatomic, assign, readonly) JMIC_WsReadyState wsState;
// 其他的全局变量
@property (nonatomic, assign) NetworkStatus netWorkstatus;      //当前网络状态
/** 当前连接的 ip+端口 */
@property (nonatomic, copy, readonly) NSURL *currentURL;

/** 单例 */
+ (instancetype)sharedICNetWorkManager;

/** 加入请求队列中 */
- (void)hqzt_startRequest:(id<JM_ICSessionDataStoryProtocol>)baseReq delegate:(id)delegate;
/** 取消指定的请求包 */
- (void)hqzt_cancelRequest:(JM_ICSessionData *)requestData object:(id)object;
/** 取消委托页面的所有请求 */
- (void)hqzt_cancelObjectRequest:(id)delegate;
/** 判断请求是否在队列中 */
- (BOOL)hqzt_isRepeatRequest:(id<JM_ICSessionDataStoryProtocol>)baseReq delegate:(id)delegate;
/** 删除队列中请求 */
- (void)hqzt_deleteRequest:(JM_ICSessionData *)requestData;
/** 重新恢复委托页面的所有请求 */
- (void)hqzt_reStartCurrentObjectRequest;
/** 取消当前委托页面的所有请求 */
- (void)hqzt_cancelCurrentObjectRequest;
@end
