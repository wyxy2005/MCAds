//
//  MCAdPlayerView.m
//  MCAds
//
//  Created by majiancheng on 2017/8/30.
//  Copyright © 2017年 poholo Inc. All rights reserved.
//

#import "MCAdPlayerView.h"


@interface MCAdPlayerView ()

@property(nonatomic, strong) UIImageView *coverImageView;

@end

@implementation MCAdPlayerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.playerStyle = PlayerStyleSizeRegularAuto;
    }
    return self;
}

- (void)prepareUI {
    [self addSubview:self.coverImageView];
}

- (void)updatePlayerLayer:(CALayer *)layer {
    [super updatePlayerLayer:layer];
    [self sendSubviewToBack:self.coverImageView];
}

- (void)updatePlayerView:(UIView *)drawPlayerView {
    [super updatePlayerView:drawPlayerView];
    [self sendSubviewToBack:self.coverImageView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.coverImageView.frame = self.bounds;
}


#pragma mark - getter

- (UIImageView *)coverImageView {
    if (!_coverImageView) {
        _coverImageView = [[UIImageView alloc] init];
    }
    return _coverImageView;
}

@end
