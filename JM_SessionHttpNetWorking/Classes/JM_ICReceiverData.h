//
//  JM_ICReceiverData.h
//  JMTitleTabListView
//
//  Created by tomyang on 2018/4/25.
//  Copyright © 2018年 zky. All rights reserved.
//
/**
 *  网络请求 返回的信息
 */
#import <Foundation/Foundation.h>

@interface JM_ICReceiverData : NSObject
@property (nonatomic, assign)     short  mainFun;      //当前请求主功能号
@property (nonatomic, assign)     short  slaveFun;     //当前请求子功能号
@property (nonatomic, assign)     short  cmdVersion;   //当前请求协议版本号
@property (nonatomic, assign)  NSInteger responseTag;  // 返回标识，对应请求标识，用于区分请求

@property (nonatomic, retain)        id  data;         //直接返回可以使用的数据集
@property (nonatomic, assign)     short  errorNo;      //如果没有返回数据记录返回的错误号
@property (nonatomic, copy)    NSString *errorMeg;     //如果没有返回数据记录返回的错误信息

@property (nonatomic, copy)    NSString *url;          //json协议请求的地址
@end
