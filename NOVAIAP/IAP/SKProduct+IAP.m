// 
// Created by John Shu on 2020/4/24 11:25.
// Copyright © 2020 shupeng. All rights reserved.
//

#import "SKProduct+IAP.h"

@implementation SKProduct (IAP)

- (NSString *)localizedPriceDescription {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:self.priceLocale];
    NSString *formattedPrice = [numberFormatter stringFromNumber:self.price];
    
    return formattedPrice;
}
@end
