//
// Created by majiancheng on 2017/5/25.
// Copyright (c) 2017 poholo Inc. All rights reserved.
//

#import "MCMobileAdService.h"


#import <BaiduMobAdSDK/BaiduMobAdNative.h>
#import <GDTAd/GDTAd.h>

#import "MCAdConfig.h"
#import "MCMobAdNativeAdView.h"
#import "MCAdDto.h"
#import "NSObject+AdApi.h"
#import "MCAdvertisementDto.h"


@interface MCMobileAdService () <BaiduMobAdNativeAdDelegate, GDTNativeAdDelegate>

@property(nonatomic, assign) MCAdCategoryType adType;

@property(nonatomic, strong) BaiduMobAdNative *baiduNativeAd;
@property(nonatomic, strong) GDTNativeAd *tencentNativeAd;

@property(nonatomic, strong) NSMutableArray<MCAdDto *> *adContainers;

@property(nonatomic, assign) NSInteger containerLowValve; ///< 广告最低阀值

@property(nonatomic, assign) NSUInteger containerRuleIndex;

@property(nonatomic, assign) NSUInteger needAdNums;

@end

@implementation MCMobileAdService

- (instancetype)init {
    return nil;
}

- (instancetype)initWithConfig:(MCAdConfig *)adConfig adType:(MCAdCategoryType)adType delegate:(id <MobileAdServiceDelegate>)delegate {
    self = [super init];
    if (self) {
        self.adConfig = adConfig;
        self.adType = adType;
        self.delegate = delegate;
        self.containerLowValve = 5;
    }
    return self;
}

- (void)requestNativeAds {
    if ([self needToNextRequest]) {
        [self smartRequestNativeAds];
    }
}

- (void)requestAdsTarget:(id <MobileAdServiceDelegate>)delegate nums:(NSUInteger)nums {
    self.delegate = delegate;
    if (self.adConfig == nil || !self.adConfig.entityId) {
        NSError *error = [NSError errorWithDomain:ERROR_DOMAIM code:-1 userInfo:@{ERROR_MESSAGE: @"广告配置为空"}];
        [self nativeAdFailedLoadUnion:error];
    } else {
        if (self.adContainers.count < nums) {
            self.needAdNums = nums;
            [self requestNativeAds];
        } else {
            NSRange range = NSMakeRange(0, nums);
            __weak typeof(self) weakSelf = self;
            [self mainExecute:^{
                __strong typeof(weakSelf) strongSelf = weakSelf;

                if ([strongSelf.delegate respondsToSelector:@selector(mobileAdServiceRequestSuccess:)]) {
                    [strongSelf.delegate mobileAdServiceRequestSuccess:[strongSelf.adContainers subarrayWithRange:range]];
                    [strongSelf.adContainers removeObjectsInRange:range];
                    strongSelf.delegate = nil;
                }
            }];
        }
    }
}

- (void)smartRequestNativeAds {
    switch (self.adConfig.adSourceType) {
        case MCAdSourceBaidu: {
            [self.baiduNativeAd requestNativeAds];
        }
            break;
        case MCAdSourceTencent: {
            self.tencentNativeAd.controller = [self topController];
            [self.tencentNativeAd loadAd:(int) self.containerLowValve];
        }
            break;
        case MCAdSourceInmmobi: {

        }
            break;
        case MCAdSourceCustom: {
            [self reqCustomAds:self.containerLowValve];
        }
            break;
        default: {
        }
            break;
    }
}

- (MCAdDto *)takeOneAd {
    MCAdDto *ad = nil;
    [self requestNativeAds];
    if (self.containerRuleIndex > 0 && self.containerRuleIndex < self.adContainers.count) {
        ad = self.adContainers[self.containerRuleIndex];
        self.containerRuleIndex++;
        if (self.containerRuleIndex >= self.adContainers.count) {
            [self smartRequestNativeAds];
        }
    } else {
        ad = self.adContainers.firstObject;
        if (ad) {
            [self.adContainers removeObjectAtIndex:0];
        }
    }
    return ad;
}

- (void)updateRefer:(NSString *)refer {

}

- (void)log2ThridPlatform:(MCAdDto *)adDto attachView:(UIView *)view {
    switch (self.adConfig.adSourceType) {
        case MCAdSourceBaidu: {
        }
            break;
        case MCAdSourceTencent: {
            [self.tencentNativeAd attachAd:adDto.nativeAdDto.tencentAdData toView:view];
        }
            break;
        case MCAdSourceInmmobi: {

        }
            break;
        case MCAdSourceCustom: {

        }
            break;
        default: {
        }
            break;
    }
}

- (void)clickAd:(MCAdDto *)adDto {
    switch (self.adConfig.adSourceType) {
        case MCAdSourceBaidu: {
        }
            break;
        case MCAdSourceTencent: {
            self.tencentNativeAd.controller = [self topController];
            [self.tencentNativeAd clickAd:adDto.nativeAdDto.tencentAdData];
        }
            break;
        case MCAdSourceInmmobi: {

        }
            break;
        case MCAdSourceCustom: {
            [adDto.nativeAdDto.customAdvertisementDto startAction];
        }
            break;
        default: {
        }
            break;
    }
}

- (BOOL)needToNextRequest {
    if (self.adContainers.count == 0) {
        return YES;
    }
    if (self.containerLowValve > self.adContainers.count) {
        return YES;
    }

    return NO;
}

#pragma mark -

- (void)nativeAdSuccessLoad:(NSArray *)nativeAds {
    MCLog(@"nativeAdObjectsSuccessLoad:%lu", (unsigned long) nativeAds.count);
    if (nativeAds.count > 0) {
        self.containerRuleIndex = 0;
    }

    NSMutableArray *temArray = [[NSMutableArray alloc] init];
    [self.adContainers enumerateObjectsUsingBlock:^(MCAdDto *obj, NSUInteger idx, BOOL *stop) {
        if (![obj isExpired]) {
            [temArray addObject:obj];
        }
    }];

    [self.adContainers removeAllObjects];
    [self.adContainers addObjectsFromArray:temArray];

    __weak typeof(self) weakSelf = self;
    [nativeAds enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        MCNativeAdDto *adDto = [MCNativeAdDto creatWithAdNative:obj];
        MCAdDto *dto = [[MCAdDto alloc] initWithNativeAdDto:adDto styleId:MCAdStyleLittle];
        dto.adService = strongSelf;
        [strongSelf.adContainers insertObject:dto atIndex:0];
    }];

    if (self.adContainers.count > 0) {
        [self mainExecute:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if ([strongSelf.delegate respondsToSelector:@selector(mobileAdServiceRequestSuccess:)]) {
                if (strongSelf.adContainers.count < strongSelf.needAdNums) {
                    strongSelf.needAdNums = strongSelf.adContainers.count;
                }
                NSRange range = NSMakeRange(0, strongSelf.needAdNums);
                [strongSelf.delegate mobileAdServiceRequestSuccess:[strongSelf.adContainers subarrayWithRange:range]];
                [strongSelf.adContainers removeObjectsInRange:range];
                strongSelf.delegate = nil;
            }

        }];

        NSString *refer = ({
            NSString *r = @"";
            UIViewController *controller = nil;//[AppDelegate share].currentNavController.topViewController;
            if ([controller isKindOfClass:[UIViewController class]]) {
//                r = ((MMController *) controller).logParam.refer;
            }

            r;
        });

//        [LogService createRequestAD:[[[LogParam createWithRefer:refer] advertisment:self.apId] num:[NSString stringWithFormat:@"%lu", (unsigned long) self.adContainers.count]]];
    } else {
//        NSError *error = [NSError errorWithDomain:ERROR_DOMAIM code:-1 userInfo:@{ERROR_MESSAGE: @"This is Ads empty"}];
        [self nativeAdFailedLoadUnion:nil];
    }
}

- (void)nativeAdFailedLoadUnion:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    [self mainExecute:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;

        if ([strongSelf.delegate respondsToSelector:@selector(mobileAdServiceRequestFailed)]) {
            [strongSelf.delegate mobileAdServiceRequestFailed];
        }
    }];
}

- (void)adServiceTapUnionAd {
    __weak typeof(self) weakSelf = self;
    [self mainExecute:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;

        if ([strongSelf.delegate respondsToSelector:@selector(mobileAdServiceTapUnionAd)]) {
            [strongSelf.delegate mobileAdServiceTapUnionAd];
        }
    }];
}

- (void)adServiceCloseUnionAdDetail {
    __weak typeof(self) weakSelf = self;
    [self mainExecute:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;

        if ([strongSelf.delegate respondsToSelector:@selector(mobileAdServiceCloseUnionAdDetail)]) {
            [strongSelf.delegate mobileAdServiceCloseUnionAdDetail];
        }
    }];
}

#pragma mark - Ad BaiduMobAdNativeAdDelegate

- (NSString *)apId {
    return self.adConfig.entityId;
}

- (NSString *)publisherId {
    return self.adConfig.appId;
}

- (void)nativeAdObjectsSuccessLoad:(NSArray<BaiduMobAdNativeAdObject *> *)nativeAds {
    [self nativeAdSuccessLoad:nativeAds];
}

//广告返回失败
- (void)nativeAdsFailLoad:(BaiduMobFailReason)reason {
    MCLog(@"nativeAdsFailLoad,reason = %d", reason);
    NSError *error = [NSError errorWithDomain:ERROR_DOMAIM code:-2 userInfo:@{ERROR_MESSAGE: [NSString stringWithFormat:@"This baidu ads request failed %ud", reason]}];
    [self nativeAdFailedLoadUnion:error];
}

//对于视频广告，展现一张视频预览大图，点击开始播放视频
- (void)nativeAdVideoAreaClick:(BaiduMobAdNativeAdView *)nativeAdView {

}

//广告被点击，打开后续详情页面，如果为视频广告，可选择暂停视频
- (void)nativeAdClicked:(MCMobAdNativeAdView *)nativeAdView {
    if ([nativeAdView isKindOfClass:[MCMobAdNativeAdView class]]) {
//        [LogService createClickAD:[[[[[[[LogParam createWithRefer:nativeAdView.referId] advertisment:self.apId] changeEventType:nativeAdView.type] searchPostion:nativeAdView.postion] time:nativeAdView.resq] title:nativeAdView.title] advertismentPic:@(nativeAdView.picType)]];
    }
    [self adServiceTapUnionAd];
}

//广告详情页被关闭，如果为视频广告，可选择继续播放视频
- (void)didDismissLandingPage:(BaiduMobAdNativeAdView *)nativeAdView {
    [self adServiceCloseUnionAdDetail];
}

#pragma mark - Ad TencentAdDelegate

- (void)nativeAdSuccessToLoad:(NSArray<GDTNativeAdData *> *)nativeAds {
    MCLog(@"nativeAdObjectsSuccessLoad:%lu", (unsigned long) nativeAds.count);
    [self nativeAdSuccessLoad:nativeAds];
}

- (void)nativeAdFailToLoad:(NSError *)error {
    MCLog(@"nativeAdsFailLoad,reason = %@", error);
    NSError *err = [NSError errorWithDomain:error.domain code:-3 userInfo:error.userInfo];
    [self nativeAdFailedLoadUnion:err];
}

/**
 *  原生广告点击之后将要展示内嵌浏览器或应用内AppStore回调
 */
- (void)nativeAdWillPresentScreen {
    [self adServiceTapUnionAd];
}

/**
 *  原生广告点击之后应用进入后台时回调
 */
- (void)nativeAdApplicationWillEnterBackground {

}

/**
 * 原生广告点击以后，内置AppStore或是内置浏览器被关闭时回调
 */
- (void)nativeAdClosed {
    [self adServiceCloseUnionAdDetail];
}

#pragma mark - Custom

- (void)reqCustomAds:(NSInteger)num {
    __weak typeof(self) weakSelf = self;
    [self apiReqCustomAds:num callBack:^(BOOL success, NSDictionary *dictionary) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        MCLog(@"[Custom][AdReq] success = %d", success);
        NSMutableArray *nativeAds = [NSMutableArray new];
        for (NSDictionary *dict in dictionary[@"data"]) {
            MCAdvertisementDto *dto = [MCAdvertisementDto createDto:dict];
            [nativeAds addObject:dto];
        }
        [strongSelf nativeAdSuccessLoad:nativeAds];
    }];
}

#pragma mark - getter

- (BaiduMobAdNative *)baiduNativeAd {
    if (_baiduNativeAd == nil) {
        _baiduNativeAd = [[BaiduMobAdNative alloc] init];
        _baiduNativeAd.delegate = self;

    }
    return _baiduNativeAd;
}

- (GDTNativeAd *)tencentNativeAd {
    if (!_tencentNativeAd) {
        _tencentNativeAd = [[GDTNativeAd alloc] initWithAppkey:self.adConfig.appId placementId:self.adConfig.entityId];
        _tencentNativeAd.delegate = self;
        _tencentNativeAd.controller = [self topController];
    }
    return _tencentNativeAd;
}

- (NSMutableArray *)adContainers {
    if (_adContainers == nil) {
        _adContainers = [[NSMutableArray alloc] init];
    }
    return _adContainers;
}

#pragma mark - util

- (void)mainExecute:(dispatch_block_t)block {
    if ([NSThread isMainThread]) {
        if (block) {
            block();
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) {
                block();
            }
        });
    }
}

- (UIViewController *)topController {
    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    UINavigationController *nav;
    if ([root isKindOfClass:[UINavigationController class]]) {
        nav = (UINavigationController *) root;
    } else {
        nav = root.navigationController;
    }
    return nav.topViewController;
}


@end
