//
//  NOVAIAPProductStore.h
//  NOVAIAP
//
//  Created by John Shu on 2020/1/19.
//  Copyright © 2020 shupeng. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 用户的商品存储器
@protocol NOVAIAPProductStore <NSObject>
// 发货--消耗品
- (void)deleiverConsumableProduct:(NSString *)productIdentifier;

// 激活--永久性商品
- (void)activeForeverProducts:(NSArray<NSString *> *)productIdentifiers;

// 取消激活--永久性商品
- (void)deactiveForeverProducts:(NSArray<NSString *> *)productIdentifiers;

// 激活--订阅类商品
- (void)activeAutoRenewSubscriptionProducts:(NSArray<NSString *> *)productIdentifiers;

// 取消激活--订阅类商品
- (void)deactiveAutoRenewSubscriptionProducts:(NSArray<NSString *> *)productIdentifiers;
@end

NS_ASSUME_NONNULL_END
