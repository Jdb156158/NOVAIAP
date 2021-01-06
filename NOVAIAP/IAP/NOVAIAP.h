//
//  NOVAIAP.h
//  NOVAIAP
//
//  Created by John Shu on 2020/1/19.
//  Copyright © 2020 shupeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "NOVAIAPProductValidator.h"
#import "NOVAIAPProductStore.h"

// 成功获取商品列表
#define kNOVAIAPFetchProductSuccessNotification  @"kNOVAIAPFetchProductSuccessNotification"

// 获取商品列表失败
#define kNOVAIAPFetchProductFailedNotification   @"kNOVAIAPFetchProductFailedNotification"

// 购买成功
#define kNOVAIAPPaidSuccessNotification          @"kNOVAIAPPaidSuccessNotification"

// 购买失败
#define kNOVAIAPPaidFailedNotification           @"kNOVAIAPPaidFailedNotification"

/**
 恢复交易成功的回调

 恢复交易仅能恢复永久性商品、自动订阅类商品。
 恢复交易成功后，用户应该进行check操作。来刷新有效商品。
 */
#define kNOVAIAPRestoreSuccessNotification       @"kNOVAIAPRestoreSuccessNotification"

// 恢复交易失败的回调
#define kNOVAIAPRestoreFailedNotification        @"kNOVAIAPRestoreFailedNotification"

// check成功的回调
#define kNOVAIAPValidateReceiptSuccessNotification         @"kNOVAIAPValidateReceiptSuccessNotification"

// check失败的回调
#define kNOVAIAPValidateReceiptFailedNotification          @"kNOVAIAPValidateReceiptFailedNotification"


typedef NS_ENUM(NSUInteger, NOVAIAPProductType) {
    NOVAIAPProductConsumable,
    NOVAIAPProductForever,
    NOVAIAPProductAutoRenewSubscription,
};

@protocol NOVAIAPDelegate <NSObject>
- (NOVAIAPProductType)typeForProduct:(NSString *)productIdentifier;
@end

@interface NOVAIAP : NSObject
+ (instancetype)shared;

/// 所有商品
@property(nonatomic, strong) NSArray<SKProduct *> *products;

/// 回调
@property(nonatomic, weak) id <NOVAIAPDelegate> delegate;

/// 商品验证器
@property(nonatomic, weak) id <NOVAIAPProductValidator> validator;

/// 商品存储器
@property(nonatomic, weak) id <NOVAIAPProductStore> store;

/// 拉取商品信息
- (void)fetchProductsInfo:(NSArray <NSString *> *)products;

/// 获取当前沙盒内的票据数据
- (NSData *)bundleReceiptData;

/// 购买商品
- (void)buyProduct:(NSString *)productIdentifier;

/// 检查永久性商品和订阅类商品是否依然有效
/// @param force force update receipt if bundle receipt is not exist
- (void)validateReceiptDataAndDeleiverProductsForeUpdate:(BOOL)force;

/// 恢复购买
- (void)restore;
@end
