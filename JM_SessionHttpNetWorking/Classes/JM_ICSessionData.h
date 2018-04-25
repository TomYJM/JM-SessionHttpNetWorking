//
//  JM_ICSessionData.h
//  JMTitleTabListView
//
//  Created by tomyang on 2018/4/25.
//  Copyright © 2018年 zky. All rights reserved.
//
/*
 * 网络连接数据（请求）
 */
#import <Foundation/Foundation.h>

@interface JM_ICSessionData : NSObject
@property (nonatomic, assign)             short  mainFun;          //当前请求主功能号
@property (nonatomic, assign)             short  slaveFun;         //当前请求子功能号
@property (nonatomic, assign)             short  cmdVersion;       //当前请求协议版本号
@property (nonatomic, copy)            NSString  *url;             //当前请求地址
@property (nonatomic, assign)         NSInteger  timeout;          //超时时间
@property (nonatomic, assign)         NSInteger  reqTag;           // 请求标识

@property (nonatomic, weak)                  id  delegate;         //当前请求委托界面

@property (nonatomic, assign)          NSInteger reqSize;          //当前请求的数据长度
@property (nonatomic, retain)      NSMutableData *reqData;         //当前请求的数据流
@property (nonatomic, copy)             NSString *reqBodyString;   //当前请求的包体json串
@property (nonatomic, retain)       NSDictionary *reqHeaderDic;    //当前请求的包头字典

@property (nonatomic, retain)      NSURLResponse *receiveResponse; //当前请求返回的请求（获取http包头header内的内容）
@property (nonatomic, retain)      NSMutableData *receiveData;     //当前请求返回的数据流

@property (nonatomic, assign)     NSTimeInterval reConnectTime;    //重连时间

@property (nonatomic, retain)            NSTimer *heartBeat;       //心跳检测
@end
