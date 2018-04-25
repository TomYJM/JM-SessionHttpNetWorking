//
//  JM_ICRequestPackage.h
//  JMTitleTabListView
//
//  Created by tomyang on 2018/4/25.
//  Copyright © 2018年 tomyang. All rights reserved.
//
//保存的请求包（请求对象和连接数据集）
#import <Foundation/Foundation.h>
#import "JM_ICSessionDataStory.h"
@interface JM_ICRequestPackage : NSObject
@property (nonatomic, retain)       NSURLSession *session;
@property (nonatomic, retain)     JM_ICSessionData *sessionData;
@property (nonatomic, retain)     id <JM_ICSessionDataStoryProtocol> baseReq;
@end
