//
//  ViewController.m
//  ImageToVideoDemo
//
//  Created by lx on 2018/8/17.
//  Copyright © 2018年 lx. All rights reserved.
//

#import "ViewController.h"
#import "LXImagesToVideo.h"
#import "LXImagesToVideoManager.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVKit/AVKit.h>
#import <Accelerate/Accelerate.h>


@interface ViewController ()
{
    
}

@property (nonatomic, strong) NSString *audioPath;
@property (nonatomic, strong) NSString *outputPath;

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton * button1 =[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button1 setFrame:CGRectMake(150,100, 100,50)];
    [button1 setTitle:@"视频播放"forState:UIControlStateNormal];
    [button1 addTarget:self action:@selector(playAction)forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button1];

    NSArray *imageArr = @[[UIImage imageNamed:@"house1.jpg"],[UIImage imageNamed:@"house2.jpg"],[UIImage imageNamed:@"house3.jpg"],
                          [UIImage imageNamed:@"house4.jpg"],[UIImage imageNamed:@"house5.jpg"],[UIImage imageNamed:@"house6.jpg"],
                          [UIImage imageNamed:@"house7.jpg"]];
    
    self.audioPath =[[NSBundle mainBundle] pathForResource:@"黑白" ofType:@"mp3"];
    
    //图片合成视频
    [LXImagesToVideoManager customVideoFromImages:imageArr
                                    playAnimation:@[@(0), @(1), @(2), @(3), @(4), @(5), @(5)]
                                   crossAnimation:@[@(0), @(1), @(2), @(3), @(4), @(5)]
                                        audioPath:self.audioPath
                            singleImagePlaySecond:2
                             transitionFrameCount:60
                               crossAnimationRate:20
                                         zoomRate:0.04
                                        frameSize:CGSizeMake(720, 480)
                               animateTransitions:YES
                                       onComplete:^(BOOL success, NSString *videoPath) {
                                           UISaveVideoAtPathToSavedPhotosAlbum(videoPath, self, nil, nil);
                                           self.outputPath = videoPath;
                                       }];
}

//播放
-(void)playAction {
    MPMoviePlayerViewController *theMovie =[[MPMoviePlayerViewController alloc]initWithContentURL:[NSURL fileURLWithPath:self.outputPath]];
    [self presentMoviePlayerViewControllerAnimated:theMovie];
    theMovie.moviePlayer.movieSourceType=MPMovieSourceTypeFile;
    [theMovie.moviePlayer play];
}

@end
