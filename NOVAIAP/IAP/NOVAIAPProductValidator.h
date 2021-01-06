//
//  NOVAIAPProductValidator.h
//  NOVAIAP
//
//  Created by John Shu on 2020/1/19.
//  Copyright © 2020 shupeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NOVAIAPProductValidator <NSObject>
/**
 校验某次购买的成功或者失败

 @param transaction 某次交易
 @param receiptData 票据信息
 @param complete 如果失败, 返回error
 */
- (void)validateTransaction:(SKPaymentTransaction *)transaction withReceipt:(NSData *)receiptData complete:(void (^)(NSError *error))complete;

/**
 校验票据里的永久性、订阅类商品

 @param receiptData receipt description
 @param complete 需要返回永久性商品列表。自动续订类的截止日期。
 */
- (void)validateReceiptData:(NSData *)receiptData complete:(void (^)(NSArray<NSString *> *nonRenewProductIdentifiers, NSDictionary *renewProductDic, NSError *error))complete;
@end

NS_ASSUME_NONNULL_END
