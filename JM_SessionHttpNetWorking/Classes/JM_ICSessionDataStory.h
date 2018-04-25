//
//  JM_ICSessionDataStory.h
//  JMTitleTabListView
//
//  Created by tomyang on 2018/4/25.
//  Copyright © 2018年 zky. All rights reserved.
//

#ifndef JM_ICSessionDataStory_h
#define JM_ICSessionDataStory_h
@class JM_ICSessionData;
@protocol JM_ICSessionDataStoryProtocol <NSObject>

@property (nonatomic, assign)   short  mainFun;                 //主功能号
@property (nonatomic, assign)   short  slaveFun;                //子功能号
@property (nonatomic, assign)   short  cmdVersion;              //版本号
@property (nonatomic, assign)   short  marketID;                //交易所代码
@property (nonatomic, copy)     NSString *funUrl;               //代码功能的url地址返回信息
@property (nonatomic, assign)   NSInteger timeoutInterval;      //超时时间
@property (nonatomic, assign)   NSInteger reqTag;               //请求标志（0默认，设置此值最好不是0）
//@property (nonatomic, retain)   GPBMessage *gpbMessage; //主功能号

//创建连接整体数据集并添加请求相关的字段
- (JM_ICSessionData *)getRequestData;
//获取请求地址
- (NSString *)urlPathRequest:(JM_ICSessionData *)requestData isCutOverSwitch:(BOOL)bSwitch;
// 行情推送code
- (int)hqts_gpbCode:(short)mainFun subFun:(short)subFun data:(id)data;
// 行情推送messge
- (NSString *)hqts_gpbMessage:(short)mainFun subFun:(short)subFun data:(id)data;
// 行情推送细分模块
- (NSString *)hqts_gpbMessage:(short)mainFun subFun:(short)subFun;
// 处理服务器返回的数据流  className解析模型类名
- (id)handleReceiverData:(NSData *)data parseClassName:(NSString *)className;
@end
#endif /* JM_ICSessionDataStory_h */
