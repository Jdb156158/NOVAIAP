//
//  NOVAIAPUserDefaultProductStore.h
//  NOVAIAP
//
//  Created by John Shu on 2020/1/20.
//  Copyright © 2020 shupeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NOVAIAPProductStore.h"

NS_ASSUME_NONNULL_BEGIN

@interface NOVAIAPUserDefaultProductStore : NSObject <NOVAIAPProductStore>
+ (instancetype)shared;

- (NSInteger)countForConsumableProduct:(NSString *)productIdentifier;

- (void)consumeProduct:(NSString *)productIdentifier count:(NSInteger)count;

- (void)cleanConsumeProducts:(NSArray<NSString *> *)productIdentifiers;

- (BOOL)isActivatedForForeverProduct:(NSString *)productIdentifier;

- (BOOL)isActivatedForRenewSubscriptionProduct:(NSString *)productIdentifier;
@end

NS_ASSUME_NONNULL_END
