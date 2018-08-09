//
//  OAXVPNManager.h
//  VPNTest
//
//  Created by JoeXu on 2018/6/4.
//  Copyright © 2018年 YM. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAXVPNManager : NSObject

+ (instancetype)sharedManager;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface OAXVPNManager (Operate)

- (void)prepare:(void(^)(NSError *error))complete;

- (void)connect:(void(^)(NSError *error))complete;

@end
