//
//  NOVAIAPLocalReceiptValidator.m
//  NOVAIAP
//
//  Created by John Shu on 2020/1/20.
//  Copyright © 2020 shupeng. All rights reserved.
//

#import <NOVUtilities/NOVAUtilities.h>
#import "NOVAIAPLocalReceiptValidator.h"
#import "RMAppReceipt.h"


@implementation NOVAIAPLocalReceiptValidator

- (NSString *)tmpReceiptDataPath {
    NSString * path = [DocPath() stringByAppendingPathComponent:@"receipt.data"];
    return path;
}

- (RMAppReceipt *)receiptFromData:(NSData *)data {
    [data writeToFile:[self tmpReceiptDataPath] atomically:true];
    RMAppReceipt *receipt = [[RMAppReceipt alloc] initWithASN1Data:[RMAppReceipt dataFromPCKS7Path:[self tmpReceiptDataPath]]];

    return receipt;
}

- (NSError *)validateReceiptBasics:(RMAppReceipt *)receipt {
    if (receipt == nil) {
        NSError *error = [NSError errorWithDomain:@"NOVAIAPLocalReceiptValidatorErrorDomain" code:1 userInfo:@{NSLocalizedDescriptionKey: @"recepit is null!"}];
        return error;
    }

    if (![receipt.bundleIdentifier isEqualToString:[[NSBundle mainBundle] bundleIdentifier]]) {
        NSError *error = [NSError errorWithDomain:@"NOVAIAPLocalReceiptValidatorErrorDomain" code:2 userInfo:@{NSLocalizedDescriptionKey: @"bundle identifier not equal!"}];
        return error;
    }

    if (![receipt verifyReceiptHash]) {
        NSError *error = [NSError errorWithDomain:@"NOVAIAPLocalReceiptValidatorErrorDomain" code:3 userInfo:@{NSLocalizedDescriptionKey: @"recepit hash is not equal!"}];
        return error;
    }

    return nil;
}

- (void)validateTransaction:(SKPaymentTransaction *)transaction withReceipt:(NSData *)receiptData complete:(void (^)(NSError *error))complete {
    RMAppReceipt *receipt = [self receiptFromData:receiptData];

    NSError *error = [self validateReceiptBasics:receipt];
    if (error) {
        complete(error);
        return;
    }

    if ([receipt containsInAppPurchaseOfProductIdentifier:transaction.payment.productIdentifier]) {
        complete(nil);
    } else {
        NSError *error = [NSError errorWithDomain:@"NOVAIAPLocalReceiptValidatorErrorDomain" code:4 userInfo:@{NSLocalizedDescriptionKey: @"can not find product in receipt!"}];
        complete(error);
    }
}

- (void)validateReceiptData:(NSData *)receiptData complete:(void (^)(NSArray<NSString *> *nonRenewProductIdentifiers, NSDictionary *renewProductDic, NSError *error))complete {
    RMAppReceipt *receipt = [self receiptFromData:receiptData];

    NSError *error = [self validateReceiptBasics:receipt];
    if (error) {
        complete(nil, nil, error);
        return;
    }

    NSMutableArray *nonRenewProducts = [NSMutableArray array];
    NSMutableDictionary *renewProductExpireDateDic = [NSMutableDictionary dictionary];

    [receipt.inAppPurchases enumerateObjectsUsingBlock:^(RMAppReceiptIAP  * _Nonnull inAppPurchase, NSUInteger idx, BOOL * _Nonnull stop) {
        // 非订阅类
        if (inAppPurchase.subscriptionExpirationDate == nil) {
            [nonRenewProducts addObject:inAppPurchase.productIdentifier];
        }
        // 订阅类
        else {
            // 找到同类商品中时间最新的一个
            NSDate *maxDate = renewProductExpireDateDic[inAppPurchase.productIdentifier];
            if (maxDate == nil) {
                renewProductExpireDateDic[inAppPurchase.productIdentifier] = inAppPurchase.subscriptionExpirationDate;
            } else {
                NSDate *newDate = inAppPurchase.subscriptionExpirationDate;
                if ([newDate timeIntervalSinceDate:maxDate] > 0) {
                    renewProductExpireDateDic[inAppPurchase.productIdentifier] = newDate;
                }
            }
        }
    }];

    complete(nonRenewProducts, renewProductExpireDateDic, nil);
}

@end
