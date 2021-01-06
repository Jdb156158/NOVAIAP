//
//  NOVAIAP.m
//  NOVAIAP
//
//  Created by John Shu on 2020/1/19.
//  Copyright © 2020 shupeng. All rights reserved.
//

#import "NOVAIAP.h"
#import <NOVUtilities/NOVAUtilities.h>

@interface NOVAIAP () <SKPaymentTransactionObserver, SKProductsRequestDelegate>
@property(nonatomic, copy) void (^refreshComplete)(NSError *);
@end

@implementation NOVAIAP

+ (instancetype)shared {
    static id _shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[self alloc] init];
    });

    return _shared;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }

    return self;
}

- (void)fetchProductsInfo:(NSArray <NSString *> *)products {
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:products]];
    request.delegate = self;
    [request start];
}

- (void)buyProduct:(NSString *)productIdentifier {
    if (![SKPaymentQueue canMakePayments]) {
        NSError *error = [NSError errorWithDomain:@"NOVAIAPErrorDomain" code:1 userInfo:@{NSLocalizedDescriptionKey: @"can not make payment now!"}];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNOVAIAPPaidFailedNotification object:error];
        return;
    }
    
    SKProduct *product = [self.products first:^BOOL(SKProduct *obj) {
        return [obj.productIdentifier isEqualToString:productIdentifier];
    }];
    
    if (product == nil) {
        NSError *error = [NSError errorWithDomain:@"NOVAIAPErrorDomain" code:2 userInfo:@{NSLocalizedDescriptionKey: @"can not find the product specified!"}];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNOVAIAPPaidFailedNotification object:error];
        return;
    }
    
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)refreshReceipt:(void (^)(NSError *error))complete {
    SKReceiptRefreshRequest *request = [[SKReceiptRefreshRequest alloc] initWithReceiptProperties:nil];
    self.refreshComplete = complete;
    request.delegate = self;
    [request start];
}

- (void)restore {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)validateReceiptDataAndDeleiverProductsForeUpdate:(BOOL)force {
    NSData *receiptData = [self bundleReceiptData];
    if (receiptData == nil) {
        if (force) {
            [self refreshReceipt:^(NSError *error) {
                if (error) {
                    NSLog(@"[NOVAIAP] 强制更新receipt失败, %@", [error localizedDescription]);
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNOVAIAPValidateReceiptFailedNotification object:error];
                } else {
                    [self validateReceiptDataAndDeleiverProducts:receiptData];
                }
            }];
        } else {
            NSLog(@"[NOVAIAP] 校验receipt失败! %@", @"未发现票据信息");
            NSError *error = [NSError errorWithDomain:@"NOVAIAPErrorDomain" code:3 userInfo:@{NSLocalizedDescriptionKey: @"recepit is null!"}];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNOVAIAPValidateReceiptFailedNotification object:error];
        }
    } else {
        [self validateReceiptDataAndDeleiverProducts:receiptData];
    }
}

- (void)validateReceiptDataAndDeleiverProducts:(NSData *)receiptData {
    [self.validator validateReceiptData:receiptData complete:^(NSArray<NSString *> *nonRenewProductIdentifiers, NSDictionary *renewProductDic, NSError *error) {
        if (error) {
            NSLog(@"[NOVAIAP] 校验receipt失败! %@", [error localizedDescription]);
            [[NSNotificationCenter defaultCenter] postNotificationName:kNOVAIAPValidateReceiptFailedNotification object:error];
        } else {
            NSLog(@"[NOVAIAP] 校验完成");
            NSArray *foreverProducts = [nonRenewProductIdentifiers filter:^BOOL(NSString *obj) {
                return [self.delegate typeForProduct:obj] == NOVAIAPProductForever;
            }];

            [self.store activeForeverProducts:foreverProducts];
            NSDate *currentDate = [NSDate date];
            [renewProductDic enumerateKeysAndObjectsUsingBlock:^(NSString *productIdentifier, NSDate *expireDate, BOOL *stop) {
                if ([expireDate timeIntervalSinceDate:currentDate] > 0) {
                    [self.store activeAutoRenewSubscriptionProducts:@[productIdentifier]];
                } else {
                    [self.store deactiveAutoRenewSubscriptionProducts:@[productIdentifier]];
                }
            }];

            [[NSNotificationCenter defaultCenter] postNotificationName:kNOVAIAPValidateReceiptSuccessNotification object:nil];
        }
    }];
}

- (void)deleiverProduct:(NSString *)productIdentifier {
    if ([self.delegate respondsToSelector:@selector(typeForProduct:)]) {
        NOVAIAPProductType type = [self.delegate typeForProduct:productIdentifier];

        if (type == NOVAIAPProductConsumable) {
            if ([self.store respondsToSelector:@selector(deleiverConsumableProduct:)]) {
                [self.store deleiverConsumableProduct:productIdentifier];
            }
        } else if (type == NOVAIAPProductForever) {
            if ([self.store respondsToSelector:@selector(activeForeverProducts:)]) {
                [self.store activeForeverProducts:@[productIdentifier]];
            }
        } else if (type == NOVAIAPProductAutoRenewSubscription) {
            if ([self.store respondsToSelector:@selector(activeAutoRenewSubscriptionProducts:)]) {
                [self.store activeAutoRenewSubscriptionProducts:@[productIdentifier]];
            }
        }
    }
}

- (NSData *)bundleReceiptData {
    return [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
}

#pragma mark - 苹果支付队列回调

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    [transactions forEach:^(SKPaymentTransaction *transaction) {
        switch (transaction.transactionState) {

                // 正在购买。。。不做任何处理
            case SKPaymentTransactionStatePurchasing:
                // Transaction is being added to the server queue.
                NSLog(@"[NOVAIAP] 正在购买... %@ %@", transaction.payment.productIdentifier, transaction.transactionIdentifier);

                break;


                // 交易成功。
                // 后续进行验证和发货的流程
            case SKPaymentTransactionStatePurchased:
                // Transaction is in queue, user has been charged.  Client should complete the transaction.
            {
                NSString *productIdentifier = transaction.payment.productIdentifier;

                NSLog(@"[NOVAIAP] 购买成功! %@ %@", productIdentifier, transaction.transactionIdentifier);
                NSData *receiptData = [self bundleReceiptData];

                // 没有票据信息
                if (receiptData == nil) {
                    NSLog(@"[NOVAIAP] 校验失败!%@， 没有找到票据。我们依然进行发货处理", productIdentifier);
                    // 发货
                    [self deleiverProduct:productIdentifier];

                    // 通知购买成功
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNOVAIAPPaidSuccessNotification object:productIdentifier];

                    // 结束交易
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                }

                // 有票据信息
                else {
                    NSLog(@"[NOVAIAP] 开始校验商品 %@", productIdentifier);
                    [self.validator validateTransaction:transaction withReceipt:receiptData complete:^(NSError *error) {
                        if (error == nil) {
                            NSLog(@"[NOVAIAP] 校验成功! %@", productIdentifier);
                            // 发货
                            NSLog(@"[NOVAIAP] 开始发货");
                            [self deleiverProduct:productIdentifier];

                            // 通知购买成功
                            [[NSNotificationCenter defaultCenter] postNotificationName:kNOVAIAPPaidSuccessNotification object:productIdentifier];


                            // 结束交易
                            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                        } else {
                            NSLog(@"[NOVAIAP] 校验失败! %@", productIdentifier);
                            // 通知购买后校验失败
                            [[NSNotificationCenter defaultCenter] postNotificationName:kNOVAIAPPaidFailedNotification object:error];

                            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                        }
                    }];
                }
            }
                break;

                // 购买失败， 通知代理处理。 并立即结束交易
            case SKPaymentTransactionStateFailed: {
                NSString *productIdentifier = transaction.payment.productIdentifier;

                // Transaction was cancelled or failed before being added to the server queue.
                NSLog(@"[NOVAIAP] 购买失败:%@ %@ %@", [transaction.error localizedDescription], productIdentifier, transaction.transactionIdentifier);

                // 通知购买失败
                [[NSNotificationCenter defaultCenter] postNotificationName:kNOVAIAPPaidFailedNotification object:transaction.error];

                // 购买失败直接结束事务.
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            }

                // 恢复购买， 交给恢复成功的回调中进行处理。这里对恢复的交易统一做结束处理
            case SKPaymentTransactionStateRestored:
                // Transaction was restored from user's purchase history.  Client should complete the transaction.
                NSLog(@"[NOVAIAP] 购买被恢复! %@ %@", transaction.payment.productIdentifier, transaction.transactionIdentifier);

                // 恢复直接结束事务.
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;


                // 延迟购买。暂不做处理
            case SKPaymentTransactionStateDeferred:
                // The transaction is in the queue, but its final status is pending external action.
                NSLog(@"[NOVAIAP] 购买已被延迟! %@ %@", transaction.payment.productIdentifier, transaction.transactionIdentifier);
                break;
        }
    }];
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {

}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    NSLog(@"[NOVAIAP] 用户进行恢复操作, 已完成!");

    [[NSNotificationCenter defaultCenter] postNotificationName:kNOVAIAPRestoreSuccessNotification object:nil];

}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    NSLog(@"[NOVAIAP] 用户进行恢复操作, 操作失败! : %@", [error localizedDescription]);
    [[NSNotificationCenter defaultCenter] postNotificationName:kNOVAIAPRestoreFailedNotification object:error];

}

// MARK: 获取商品回调

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    self.products = response.products;

    NSString *validProducts = [[self.products map:^id(SKProduct *obj) {
        return obj.productIdentifier;
    }] componentsJoinedByString:@","];

    NSLog(@"[NOVAIAP] 获取有效商品列表: %@", validProducts);
    NSString *invalidPorducts = [response.invalidProductIdentifiers componentsJoinedByString:@","];
    if (invalidPorducts.length > 0) {
        NSLog(@"[NOVAIAP] 获取无效商品列表: %@", invalidPorducts);
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:kNOVAIAPFetchProductSuccessNotification object:nil];
}

// MARK: request基类的回调

- (void)requestDidFinish:(SKRequest *)request {
    if ([request isKindOfClass:[SKReceiptRefreshRequest class]]) {
        self.refreshComplete(nil);
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    if ([request isKindOfClass:[SKProductsRequest class]]) {
        NSLog(@"[NOVAIAP] 获取商品列表失败: %@", [error localizedDescription]);

        [[NSNotificationCenter defaultCenter] postNotificationName:kNOVAIAPFetchProductFailedNotification object:error];
    } else if ([request isKindOfClass:[SKReceiptRefreshRequest class]]) {
        self.refreshComplete(error);
    }
}

@end
