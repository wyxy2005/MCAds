//
// Created by majiancheng on 15/12/8.
// Copyright (c) 2015 poholo. All rights reserved.
//


#import "MCAdsManager.h"

#import <GDTAd/GDTTrack.h>

#import "MCAdDto.h"
#import "MCMobileAdService.h"
#import "MCAdConfig.h"
#import "NSObject+AdApi.h"
#import "MCSplashService.h"
#import "MCApiConfig.h"
#import "MCColorConfig.h"
#import "MCStyleConfig.h"
#import "MCFontConfig.h"


@interface MCAdsManager ()

@property(nonatomic, strong) MCAdConfig *preConfig;
@property(nonatomic, strong) MCAdConfig *splashConfig;

@property(nonatomic, strong) MCMobileAdService *preAdService;
@property(nonatomic, strong) MCMobileAdService *flowAdService;
@property(nonatomic, strong) MCMobileAdService *playerPauseAdService;
@property(nonatomic, strong) MCSplashService *splashService;

@property(nonatomic, strong) MCApiConfig *apiConfig;
@property(nonatomic, strong) MCColorConfig *colorConfig;
@property(nonatomic, strong) MCStyleConfig *styleConfig;
@property(nonatomic, strong) MCFontConfig *fontConfig;

@end

@implementation MCAdsManager

+ (MCAdsManager *)share {
    static MCAdsManager *_instance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        _instance = [[self alloc] init];
    });

    return _instance;
}

- (void)activateApp {
    switch (self.splashConfig.adSourceType) {
        case MCAdSourceBaidu: {

        }
            break;
        case MCAdSourceInmmobi: {

        }
            break;
        case MCAdSourceTencent: {
            [GDTTrack activateApp];
        }
            break;
        default: {
        }
            break;
    }

}


- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (MCAdConfig *)splashConfig {
    if (_splashConfig == nil) {
        _splashConfig = [self localConfig:MCAdCategorySplash];
    }

    return _splashConfig;
}

- (MCAdConfig *)findSuitConfigFromData:(id)data MCAdCategoryType:(MCAdCategoryType)adType {
    if ([data isKindOfClass:[NSArray class]] && ((NSArray *) data).count > 0) {
        return [MCAdConfig createDto:((NSArray *) data).firstObject];
    } else if ([data isKindOfClass:[NSDictionary class]]) {
        return [MCAdConfig createDto:data];
    } else {

    }
    return nil;
}

- (MCAdConfig *)localConfig:(MCAdCategoryType)adType {
    switch (adType) {
        case MCAdCategorySplash: {
            return [MCAdConfig createSplashDefault];
        }
            break;
        case MCAdCategoryDataFlow: {
            return [MCAdConfig createDataFlow];
        }
            break;
        case MCAdCategoryDataPre : {
            return [MCAdConfig createPreConfig];
        }
            break;
        case MCAdCategoryDataPause: {
            return [MCAdConfig createPauseConfig];
        }
            break;
        default: {
        }
            break;
    }
    return nil;
}

- (void)loadConfig {
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *fileName = [path stringByAppendingPathComponent:@"MCAdConfig.json"];
    NSDictionary *result = [NSDictionary dictionaryWithContentsOfFile:fileName];
    NSDictionary *config = result[@"adConfig"];
    if (config) {
        [self __loadCommenFactory:config];
        [self requestAllData];
    }
    [self loadNextConfig];
}

- (void)loadNextConfig {
    //获取下一次的配置
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *fileName = [path stringByAppendingPathComponent:@"MCAdConfig.json"];

    __weak typeof(self) weakSelf = self;
    [self apiAdConfigMaterial:^(BOOL success, NSDictionary *dict) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (success) {
            NSDictionary *config = dict[@"adConfig"];
            [strongSelf __loadCommenFactory:config];
            [dict writeToFile:fileName atomically:YES];
            [strongSelf requestAllData];
        } else {
            if (strongSelf.preConfig == nil) {
                strongSelf.preConfig = [strongSelf localConfig:MCAdCategoryDataPre];
            }

            if (strongSelf.splashConfig == nil) {
                strongSelf.splashConfig = [strongSelf localConfig:MCAdCategorySplash];
            }

            if (strongSelf.flowAdService == nil || strongSelf.flowAdService.adConfig == nil) {
                strongSelf.flowAdService = [[MCMobileAdService alloc] initWithConfig:[strongSelf localConfig:MCAdCategoryDataFlow]
                                                                              adType:MCAdCategoryDataFlow delegate:nil];
            }

            if (strongSelf.playerPauseAdService == nil || strongSelf.playerPauseAdService.adConfig == nil) {
                strongSelf.playerPauseAdService = [[MCMobileAdService alloc] initWithConfig:[strongSelf localConfig:MCAdCategoryDataPause]
                                                                                     adType:MCAdCategoryDataPause delegate:nil];
            }

            [strongSelf requestAllData];
        }
    }];

}

- (void)changeConfig:(MCAdSourceType)sourceType {
    //获取下一次的配置
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *fileName = [path stringByAppendingPathComponent:@"MCAdConfig.json"];

    __weak typeof(self) weakSelf = self;
    [self apiAdConfigMaterialSourceType:sourceType callBack:^(BOOL success, NSDictionary *dict) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (success) {
            NSDictionary *config = dict[@"adConfig"];
            [strongSelf __loadCommenFactory:config];
            [dict writeToFile:fileName atomically:YES];
            [strongSelf requestAllData];
        } else {
            if (strongSelf.preConfig == nil) {
                strongSelf.preConfig = [strongSelf localConfig:MCAdCategoryDataPre];
            }

            if (strongSelf.splashConfig == nil) {
                strongSelf.splashConfig = [strongSelf localConfig:MCAdCategorySplash];
            }

            if (strongSelf.flowAdService == nil || strongSelf.flowAdService.adConfig == nil) {
                strongSelf.flowAdService = [[MCMobileAdService alloc] initWithConfig:[strongSelf localConfig:MCAdCategoryDataFlow]
                                                                              adType:MCAdCategoryDataFlow delegate:nil];
            }

            if (strongSelf.playerPauseAdService == nil || strongSelf.playerPauseAdService.adConfig == nil) {
                strongSelf.playerPauseAdService = [[MCMobileAdService alloc] initWithConfig:[strongSelf localConfig:MCAdCategoryDataPause]
                                                                                     adType:MCAdCategoryDataPause delegate:nil];
            }

            [strongSelf requestAllData];
        }
        MCLog(@"[MCAdsManager]changeMeterial %d", success);
    }];
}


- (void)__loadCommenFactory:(NSDictionary *)dict {

    NSDictionary *pre = dict[@"dataPre"];
    NSDictionary *splash = dict[@"splash"];
    NSDictionary *flow = dict[@"dataFlow"];
    NSDictionary *dataPause = dict[@"dataPause"];

    self.preConfig = [self findSuitConfigFromData:pre MCAdCategoryType:MCAdCategoryDataPre];
    self.splashConfig = [self findSuitConfigFromData:splash MCAdCategoryType:MCAdCategorySplash];

    self.preAdService = [[MCMobileAdService alloc] initWithConfig:[self findSuitConfigFromData:pre MCAdCategoryType:MCAdCategoryDataPre]
                                                           adType:MCAdCategoryDataPre delegate:nil];

    self.flowAdService = [[MCMobileAdService alloc] initWithConfig:[self findSuitConfigFromData:flow MCAdCategoryType:MCAdCategoryDataFlow]
                                                            adType:MCAdCategoryDataFlow delegate:nil];

    self.playerPauseAdService = [[MCMobileAdService alloc] initWithConfig:[self findSuitConfigFromData:dataPause MCAdCategoryType:MCAdCategoryDataPause]
                                                                   adType:MCAdCategoryDataPause delegate:nil];
}

- (void)requestAllData {
    [self.flowAdService requestNativeAds];
    [self.playerPauseAdService requestNativeAds];
}

- (void)requestNativeAds:(MCAdCategoryType)adType {
    switch (adType) {
        case MCAdCategorySplash : {

        }
            break;
        case MCAdCategoryDataFlow : {
            [self.flowAdService requestNativeAds];
        }
            break;
        case MCAdCategoryDataPre : {
        }
            break;
        case MCAdCategoryDataPause : {
            [self.playerPauseAdService requestNativeAds];
        }
            break;
    }
}

- (MCAdDto *)takeOneAd:(MCAdCategoryType)adType {
    switch (adType) {
        case MCAdCategorySplash : {

        }
            break;
        case MCAdCategoryDataFlow : {
            return [self.flowAdService takeOneAd];
        }
            break;
        case MCAdCategoryDataPre : {
        }
            break;
        case MCAdCategoryDataPause : {
            return [self.playerPauseAdService takeOneAd];
        }
            break;
    }
    return nil;
}

- (NSString *)apIdAdType:(MCAdCategoryType)adType {
    switch (adType) {
        case MCAdCategorySplash : {

        }
            break;
        case MCAdCategoryDataFlow : {
            return [self.flowAdService apId];
        }
            break;
        case MCAdCategoryDataPre : {
            return [self.preAdService apId];
        }
            break;
        case MCAdCategoryDataPause : {
            return [self.playerPauseAdService apId];
        }
            break;
    }
    return nil;
}

- (void)updoateRefer:(MCAdCategoryType)adType refer:(NSString *)refer {
    switch (adType) {
        case MCAdCategorySplash : {

        }
            break;
        case MCAdCategoryDataFlow : {
            [self.flowAdService updateRefer:refer];
        }
            break;
        case MCAdCategoryDataPre : {
        }
            break;
        case MCAdCategoryDataPause : {
        }
            break;
    }
}

#pragma mark - getter

- (MCSplashService *)splashService {
    if (!_splashService) {
        _splashService = [MCSplashService new];
    }
    return _splashService;
}

- (MCApiConfig *)apiConfig {
    if (!_apiConfig) {
        _apiConfig = [MCApiConfig new];
    }
    return _apiConfig;
}

- (MCColorConfig *)colorConfig {
    if (!_colorConfig) {
        _colorConfig = [MCColorConfig new];
    }
    return _colorConfig;
}

- (MCStyleConfig *)styleConfig {
    if (!_styleConfig) {
        _styleConfig = [MCStyleConfig new];
    }
    return _styleConfig;
}

- (MCFontConfig *)fontConfig {
    if (!_fontConfig) {
        _fontConfig = [MCFontConfig new];
    }
    return _fontConfig;
}

@end
