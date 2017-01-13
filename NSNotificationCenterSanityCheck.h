//
//  NSNotificationCenterSanityCheck.h
//  tinder
//
//  Created by Razvan Bangu on 2017-01-10.
//  Copyright © 2017 Razio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNotificationCenterSanityCheck : NSObject

+ (void)addObserver:(void * _Nonnull * _Nonnull)observer forName:(NSString * _Nonnull)name;
+ (void)removeObserver:(void * _Nonnull * _Nonnull)observer forName:(NSString * _Nullable)name;

+ (void)objectHasBeenDeallocd:(void * _Nonnull * _Nonnull)object;

@end
