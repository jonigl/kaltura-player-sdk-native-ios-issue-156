//
//  ViewController.m
//  kaltura-player-sdk-native-ios-issue#156
//
//  Created by Jonathan Lowenstern on 4/13/16.
//  Copyright © 2016 Jonathan Lowenstern. All rights reserved.
//

#import "ViewController.h"
#import <KALTURAPlayerSDK/KPViewController.h>

@interface ViewController () <KPViewControllerDelegate>
@property (retain, nonatomic) KPViewController *player;
@end

@implementation ViewController{
    NSArray *playlist;
    int playlistIndex;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // I delegate the player
    self.player.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self presentViewController:self.player animated:YES completion:nil];
}

- (KPViewController *)player {
    if (!_player) {
        // Account Params
        KPPlayerConfig *config = [[KPPlayerConfig alloc] initWithServer:@"http://kaltura.com"
                                                               uiConfID:@"34494681"
                                                              partnerId:@"2113721"];
        playlistIndex = 0;
        playlist = [NSArray arrayWithObjects: @"1_07xj69s6",@"1_t7ftad3f",@"1_ca5xzw36",@"1_xo9lr5dz",@"1_y1or1817",@"1_49aai1r2",@"1_6o67ru53",@"1_m22igpgy", nil];
        [config setEntryId: playlist[playlistIndex]];
        [config addConfigKey:@"autoPlay" withValue:@"true"];
        [config addConfigKey:@"controlBarContainer.plugin" withValue:@"false"];
        [config addConfigKey:@"EmbedPlayer.HidePosterOnStart" withValue:@"true"];
        [config addConfigKey:@"topBarContainer.plugin" withValue:@"false"];
        [config addConfigKey:@"largePlayBtn.plugin" withValue:@"false"];
        [config addConfigKey:@"loadingSpinner.plugin" withValue:@"false"];
        _player = [[KPViewController alloc] initWithConfiguration:config];
        NSLog(@"PLAYER CONFIGURED");
    }
    return _player;
}

- (void)kPlayer:(KPViewController *)player playerPlaybackStateDidChange:(KPMediaPlaybackState)state{
    [self logPlaybackState: state];
    if (state == KPMediaPlaybackStateEnded && playlistIndex < [playlist count] - 1){
        NSLog(@"NEXT VIDEO");
        playlistIndex++;
        [player changeMedia:playlist[playlistIndex]];
    }
    if (state == KPMediaPlaybackStatePaused && playlistIndex != [playlist count] - 1){
        //[player.playerController play];
    }
}


-(void)logPlaybackState: (KPMediaPlaybackState)state {
    NSLog(@"PLAYER PLAYBACK STATE DID CHANGE TO:");
    switch (state) {
        case KPMediaPlaybackStateUnknown:
            NSLog(@"KPMediaPlaybackStateUnknown");
            break;
        case KPMediaPlaybackStateLoaded:
            NSLog(@"KPMediaPlaybackStateLoaded");
            break;
        case KPMediaPlaybackStateReady:
            NSLog(@"KPMediaPlaybackStateReady");
            break;
        case KPMediaPlaybackStatePlaying:
            NSLog(@"KPMediaPlaybackStatePlaying");
            break;
        case KPMediaPlaybackStatePaused:
            NSLog(@"KPMediaPlaybackStatePaused");
            break;
        case KPMediaPlaybackStateEnded:
            NSLog(@"KPMediaPlaybackStateEnded");
            break;
        case KPMediaPlaybackStateInterrupted:
            NSLog(@"KPMediaPlaybackStateInterrupted");
            break;
        case KPMediaPlaybackStateSeekingForward:
            NSLog(@"KPMediaPlaybackStateSeekingForward");
            break;
        case KPMediaPlaybackStateSeekingBackward:
            NSLog(@"KPMediaPlaybackStateSeekingBackward");
            break;
        default:
            break;
    }
}

@end
