//
//  NOVAIAPUserDefaultProductStore.m
//  NOVAIAP
//
//  Created by John Shu on 2020/1/20.
//  Copyright © 2020 shupeng. All rights reserved.
//

#import "NOVAIAPUserDefaultProductStore.h"

@implementation NOVAIAPUserDefaultProductStore
+ (instancetype)shared {
    static id _shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[self alloc] init];
    });

    return _shared;
}

- (NSString *)productkey:(NSString *)productIdentifier {
    return [@"NOVAIAPUserDefaultProductStore-" stringByAppendingString:productIdentifier];
}

- (void)deleiverConsumableProduct:(NSString *)productIdentifier {
    NSInteger count = [[NSUserDefaults standardUserDefaults] integerForKey:[self productkey:productIdentifier]];
    count++;

    [[NSUserDefaults standardUserDefaults] setInteger:count forKey:[self productkey:productIdentifier]];
}

- (NSInteger)countForConsumableProduct:(NSString *)productIdentifier {
    NSInteger originCount = [[NSUserDefaults standardUserDefaults] integerForKey:[self productkey:productIdentifier]];

    return originCount;
}

- (void)consumeProduct:(NSString *)productIdentifier count:(NSInteger)count {
    NSInteger originCount = [[NSUserDefaults standardUserDefaults] integerForKey:[self productkey:productIdentifier]];
    NSInteger newCount = originCount - count;
    if (newCount <= 0) {
        newCount = 0;
    }

    [[NSUserDefaults standardUserDefaults] setInteger:newCount forKey:[self productkey:productIdentifier]];
}

- (void)cleanConsumeProducts:(NSArray<NSString *> *)productIdentifiers {
    [productIdentifiers enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:[self productkey:obj]];
    }];
}

- (void)activeForeverProducts:(NSArray<NSString *> *)productIdentifiers {
    [productIdentifiers enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:[self productkey:obj]];
    }];
}

- (void)deactiveForeverProducts:(NSArray<NSString *> *)productIdentifiers {
    [productIdentifiers enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:[self productkey:obj]];
    }];
}

- (BOOL)isActivatedForForeverProduct:(NSString *)productIdentifier {
    return [[NSUserDefaults standardUserDefaults] boolForKey:[self productkey:productIdentifier]];
}

- (void)activeAutoRenewSubscriptionProducts:(NSArray<NSString *> *)productIdentifiers {
    [productIdentifiers enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:[self productkey:obj]];
    }];
}

- (void)deactiveAutoRenewSubscriptionProducts:(NSArray<NSString *> *)productIdentifiers {
    [productIdentifiers enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:[self productkey:obj]];
    }];
}

- (BOOL)isActivatedForRenewSubscriptionProduct:(NSString *)productIdentifier {
    return [[NSUserDefaults standardUserDefaults] boolForKey:[self productkey:productIdentifier]];
}

@end
