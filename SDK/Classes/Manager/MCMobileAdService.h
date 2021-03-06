//
// Created by majiancheng on 2017/5/25.
// Copyright (c) 2017 poholo Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MCAdsManager.h"

@protocol MobileAdServiceDelegate <NSObject>

- (void)mobileAdServiceRequestSuccess:(NSArray<MCAdDto *> *)adDtos;

- (void)mobileAdServiceRequestFailed;

- (void)mobileAdServiceTapUnionAd;

- (void)mobileAdServiceCloseUnionAdDetail;

@end

@interface MCMobileAdService : NSObject

@property(nonatomic, strong) MCAdConfig *adConfig;
@property(nonatomic, weak) id <MobileAdServiceDelegate> delegate;
@property(nonatomic, readonly) NSMutableArray<MCAdDto *> *adContainers;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithConfig:(MCAdConfig *)adConfig adType:(MCAdCategoryType)adType delegate:(id <MobileAdServiceDelegate>)delegate;

- (void)requestNativeAds;

- (void)requestAdsTarget:(id <MobileAdServiceDelegate>)delegate nums:(NSUInteger)nums;

- (MCAdDto *)takeOneAd;

- (NSString *)apId;

- (void)updateRefer:(NSString *)refer;

- (void)log2ThridPlatform:(MCAdDto *)adDto attachView:(UIView *)view;

- (void)clickAd:(MCAdDto *)adDto;

@end