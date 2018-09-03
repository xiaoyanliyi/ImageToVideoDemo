//
//  ViewController.m
//  ImageToVideoDemo
//
//  Created by lx on 2018/8/17.
//  Copyright © 2018年 lx. All rights reserved.
//

#import "ViewController.h"
#import "LXImagesToVideo.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVKit/AVKit.h>
#import <Accelerate/Accelerate.h>

@interface ViewController ()
{
    NSMutableArray *imageArray;//经过压缩的图片
}

@property (nonatomic, strong) NSString *theVideoPath;
@property (nonatomic, strong) NSString *videoPath;
@property (nonatomic, strong) NSString *audioPath;
@property (nonatomic, strong) NSString *outputPath;

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    imageArray = [[NSMutableArray alloc] init];
    
    UIButton * button1 =[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button1 setFrame:CGRectMake(150,100, 100,50)];
    [button1 setTitle:@"视频播放"forState:UIControlStateNormal];
    [button1 addTarget:self action:@selector(playAction)forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button1];

    
//    NSArray *imageArr = @[[UIImage imageNamed:@"IMG_4340.JPG"],[UIImage imageNamed:@"IMG_4341.JPG"],[UIImage imageNamed:@"IMG_4342.JPG"],
//                          [UIImage imageNamed:@"IMG_4343.JPG"],[UIImage imageNamed:@"IMG_4344.JPG"],[UIImage imageNamed:@"IMG_4345.JPG"],
//                          [UIImage imageNamed:@"IMG_4346.JPG"]];
    
    NSArray *imageArr = @[[UIImage imageNamed:@"house1.jpg"],[UIImage imageNamed:@"house2.jpg"],[UIImage imageNamed:@"house3.jpg"],
                          [UIImage imageNamed:@"house4.jpg"],[UIImage imageNamed:@"house5.jpg"],[UIImage imageNamed:@"house6.jpg"],
                          [UIImage imageNamed:@"house7.jpg"]];
    
    for (int i = 0; i<imageArr.count; i++) {
        UIImage *imageNew = imageArr[i];
        
        //对图片大小进行压缩--
        imageNew = [self imageWithImage:imageNew scaledToSize:DefaultFrameSize];
//        imageNew = [ViewController getThumImgOfConextWithData:imageNew withMaxPixelSize:408];
        [imageArray addObject:imageNew];
    }
    
    NSArray *pathVideo =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    self.videoPath =[[pathVideo objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"HJtest_%@.mp4",[NSDate date]]];

    self.audioPath =[[NSBundle mainBundle] pathForResource:@"黑白" ofType:@"mp3"];
    
    NSArray *pathOutput =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    self.outputPath =[[pathOutput objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"HJoutput_%@.mov",[NSDate date]]];
    
    //图片合成视频
    [LXImagesToVideo videoFromImages:imageArray
                              toPath:self.videoPath
                  animateTransitions:YES
                   withCallbackBlock:^(BOOL success) {
                       if (success) {
                           NSLog(@"Success");
                           //视频添加背景音乐
                           [self addBackGroundAudio];
                       } else {
                           NSLog(@"Failed");
                       }
                   }];
    
    
//    [LXImagesToVideo saveVideoToPhotosWithImages:imageArray
//                              animateTransitions:YES
//                               withCallbackBlock:^(BOOL success) {
//                                   if (success) {
//                                       NSLog(@"Success");
//                                   } else {
//                                       NSLog(@"Failed");
//                                   }
//                               }];

}

- (void)addBackGroundAudio {
    
    NSURL * videoInputUrl = [NSURL fileURLWithPath:self.videoPath];
    NSURL * audioInputUrl = [NSURL fileURLWithPath:self.audioPath];
    NSURL *outPutUrl = [NSURL fileURLWithPath:self.outputPath];
    
    //声音来源路径（最终混合的音频）
    NSURL   *audio_inputFileUrl = audioInputUrl;
    
    //视频来源路径
    NSURL   *video_inputFileUrl = videoInputUrl;
    
    //最终合成输出路径
    NSURL   *outputFileUrl = outPutUrl;
    
    CMTime nextClipStartTime =kCMTimeZero;
    
    //创建可变的音频视频组合
    AVMutableComposition* mixComposition =[AVMutableComposition composition];
    
    //视频采集
    AVURLAsset* videoAsset =[[AVURLAsset alloc] initWithURL:video_inputFileUrl options:nil];
    CMTimeRange video_timeRange =CMTimeRangeMake(kCMTimeZero,videoAsset.duration);
    AVMutableCompositionTrack *a_compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [a_compositionVideoTrack insertTimeRange:video_timeRange ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:nextClipStartTime error:nil];
    
    
    //声音采集
    AVURLAsset* audioAsset =[[AVURLAsset alloc]initWithURL:audio_inputFileUrl options:nil];
    CMTimeRange audio_timeRange =CMTimeRangeMake(kCMTimeZero,videoAsset.duration);//声音长度截取范围==视频长度
    AVMutableCompositionTrack *b_compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [b_compositionAudioTrack insertTimeRange:audio_timeRange ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0] atTime:nextClipStartTime error:nil];
    
    //创建一个输出
    AVAssetExportSession* _assetExport =[[AVAssetExportSession alloc]initWithAsset:mixComposition presetName:AVAssetExportPresetMediumQuality];
    _assetExport.outputFileType =AVFileTypeQuickTimeMovie;
    _assetExport.outputURL =outputFileUrl;
    _assetExport.shouldOptimizeForNetworkUse=YES;
    
    [_assetExport exportAsynchronouslyWithCompletionHandler:^(void) {
         //播放
//        dispatch_async(dispatch_get_main_queue(), ^{
//            MPMoviePlayerViewController *theMovie =[[MPMoviePlayerViewController alloc]initWithContentURL:outputFileUrl];
//            [self presentMoviePlayerViewControllerAnimated:theMovie];
//            theMovie.moviePlayer.movieSourceType=MPMovieSourceTypeFile;
//            [theMovie.moviePlayer play];
//        });
        //保存至相册
        UISaveVideoAtPathToSavedPhotosAlbum(self.outputPath, self, nil, nil);

     }];
    NSLog(@"完成！输出路径==%@",outputFileUrl);

}

//处理图片
- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    UIImage *baseImage = [self normalizedImage:image];
    UIImage *gaussBgimage = [self imageWithGaussBlur:baseImage];
    
    UIGraphicsBeginImageContext(gaussBgimage.size);
    
    [gaussBgimage drawInRect:CGRectMake(0, 0, gaussBgimage.size.width, gaussBgimage.size.height)];
    if ((baseImage.size.width / baseImage.size.height) > (newSize.width / newSize.height)) {
        CGFloat changeHeight = (baseImage.size.height / baseImage.size.width) * newSize.width;
        [baseImage drawInRect:CGRectMake(0, (newSize.height - changeHeight) / 2, newSize.width, changeHeight)];
    }
    else {
        CGFloat changeWidth = (baseImage.size.width / baseImage.size.height) * newSize.height;
        [baseImage drawInRect:CGRectMake((newSize.width - changeWidth) / 2, 0, changeWidth, newSize.height)];
    }
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

//转方向
- (UIImage *)normalizedImage:(UIImage *)image {
    if (image.imageOrientation == UIImageOrientationUp) return image;
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
}

- (UIImage *)imageWithGaussBlur:(UIImage *)image {
    UIImage *gaussImg = [self blurryImage:image withBlurLevel:1.f];

    CGSize newSize = DefaultFrameSize;
    UIGraphicsBeginImageContext(newSize);
//    [gaussImg drawInRect:CGRectMake(-320,-240,newSize.width*2,newSize.height*2)];
    [gaussImg drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];

    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (UIImage *)blurryImage:(UIImage *)image withBlurLevel:(CGFloat)blur {
    if ((blur < 0.0f) || (blur > 1.0f)) {
        blur = 0.5f;
    }
    
    int boxSize = (int)(blur * 100);
    boxSize -= (boxSize % 2) + 1;
    
    CGImageRef img = image.CGImage;
    
    vImage_Buffer inBuffer, outBuffer;
    vImage_Error error;
    void *pixelBuffer;
    
    CGDataProviderRef inProvider = CGImageGetDataProvider(img);
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);
    
    inBuffer.width = CGImageGetWidth(img);
    inBuffer.height = CGImageGetHeight(img);
    inBuffer.rowBytes = CGImageGetBytesPerRow(img);
    inBuffer.data = (void*)CFDataGetBytePtr(inBitmapData);
    
    pixelBuffer = malloc(CGImageGetBytesPerRow(img) * CGImageGetHeight(img));
    
    outBuffer.data = pixelBuffer;
    outBuffer.width = CGImageGetWidth(img);
    outBuffer.height = CGImageGetHeight(img);
    outBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL,
                                       0, 0, boxSize, boxSize, NULL,
                                       kvImageEdgeExtend);
    
    if (error) {
        NSLog(@"error from convolution %ld", error);
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(
                                             outBuffer.data,
                                             outBuffer.width,
                                             outBuffer.height,
                                             8,
                                             outBuffer.rowBytes,
                                             colorSpace,
                                             CGImageGetBitmapInfo(image.CGImage));
    
    CGImageRef imageRef = CGBitmapContextCreateImage (ctx);
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];
    
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    
    free(pixelBuffer);
    CFRelease(inBitmapData);
    
    CGImageRelease(imageRef);
    
    return returnImage;
}

//播放
-(void)playAction
{
//    NSLog(@"************%@",self.outputPath);
//    NSURL *sourceMovieURL = [NSURL fileURLWithPath:self.outputPath];
//    AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:sourceMovieURL options:nil];
//    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
//    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
//    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
//    playerLayer.frame = self.view.layer.bounds;
//    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
//    [self.view.layer addSublayer:playerLayer];
//    [player play];
    
    MPMoviePlayerViewController *theMovie =[[MPMoviePlayerViewController alloc]initWithContentURL:[NSURL fileURLWithPath:self.outputPath]];
    [self presentMoviePlayerViewControllerAnimated:theMovie];
    theMovie.moviePlayer.movieSourceType=MPMovieSourceTypeFile;
    [theMovie.moviePlayer play];
    
}

@end
