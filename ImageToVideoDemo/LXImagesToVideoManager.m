//
//  LXImagesToVideoManager.m
//  ImageToVideoDemo
//
//  Created by lx on 2018/9/5.
//  Copyright © 2018年 lx. All rights reserved.
//

#import "LXImagesToVideoManager.h"
#import "LXImagesToVideo.h"

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVKit/AVKit.h>
#import <Accelerate/Accelerate.h>


@implementation LXImagesToVideoManager


+ (void)customVideoFromImages:(NSArray *)imageArray
                playAnimation:(NSArray *)playAnimationArray
               crossAnimation:(NSArray *)crossAnimationArray
                    audioPath:(NSString *)audioPathStr
        singleImagePlaySecond:(NSInteger)second
         transitionFrameCount:(NSInteger)transitionFrameCount
           crossAnimationRate:(NSInteger)crossRate
                     zoomRate:(CGFloat)zoomRate
                    frameSize:(CGSize)frameSize
           animateTransitions:(BOOL)animate
                   onComplete:(LXImageToVideoCallBackBlock)callBackBlock
{
    
    NSArray *pathVideo = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *videoPath = [[pathVideo objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"LXImageToVideo_%@.mp4",[NSDate date]]];
    
    NSArray *pathOutput = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *outputPath = [[pathOutput objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"LXoutput_%@.mov",[NSDate date]]];
    
    
    LXVideoParameter *param = [[LXVideoParameter alloc] init];
    param.showPicSecond = second;
    param.frameRate = 1;
    param.frameSize = frameSize;
    param.crossTransition = crossRate;
    param.transitionShouldAnimate = animate;
    param.videoPathStr = videoPath;
    param.transitionFrameCount = transitionFrameCount;
    param.zoomRate = zoomRate;
    
    NSMutableArray *outputImgArr = [NSMutableArray new];
    for (int i = 0; i<imageArray.count; i++) {
        UIImage *imageNew = imageArray[i];
        
        //对图片大小进行压缩
        imageNew = [LXImagesToVideoManager imageWithImage:imageNew scaledToSize:param.frameSize];
        [outputImgArr addObject:imageNew];
    }
    
    [LXImagesToVideo writeImageAsMovie:outputImgArr
                         playAnimation:playAnimationArray
                        crossAnimation:crossAnimationArray
                        videoParamater:param
                     withCallbackBlock:^(BOOL success) {
                         if (success) {
                             NSLog(@"Success");
                             //视频添加背景音乐
                             [LXImagesToVideoManager addBackGroundAudio:audioPathStr
                                                              audioPath:videoPath
                                                             outputPath:outputPath
                                                             onComplete:callBackBlock];
                         } else {
                             NSLog(@"Failed");
                         }
                     }];
}


+ (void)addBackGroundAudio:(NSString *)audioPath
                 audioPath:(NSString *)videoPath
                outputPath:(NSString *)outputPath
                onComplete:(LXImageToVideoCallBackBlock)callBackBlock
{
    
    NSURL * video_inputFileUrl = [NSURL fileURLWithPath:videoPath];
    NSURL * audio_inputFileUrl = [NSURL fileURLWithPath:audioPath];
    NSURL *outputFileUrl = [NSURL fileURLWithPath:outputPath];

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
        
        callBackBlock(YES, outputPath);
    }];
    NSLog(@"完成！输出路径==%@",outputFileUrl);
}

//处理图片
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    UIImage *baseImage = [LXImagesToVideoManager normalizedImage:image];
    UIImage *gaussBgimage = [LXImagesToVideoManager imageWithGaussBlur:baseImage Size:newSize];
    
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
+ (UIImage *)normalizedImage:(UIImage *)image {
    if (image.imageOrientation == UIImageOrientationUp) return image;
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
}

+ (UIImage *)imageWithGaussBlur:(UIImage *)image Size:(CGSize)size {
    UIImage *gaussImg = [LXImagesToVideoManager blurryImage:image withBlurLevel:1.f];
    
    UIGraphicsBeginImageContext(size);
    [gaussImg drawInRect:CGRectMake(0,0,size.width,size.height)];
    
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (UIImage *)blurryImage:(UIImage *)image withBlurLevel:(CGFloat)blur {
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


@end
