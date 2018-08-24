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

@interface ViewController ()
{
//    NSArray *imageArr;//未压缩的图片
    NSMutableArray *imageArray;//经过压缩的图片
}

@property (nonatomic, strong) NSString *theVideoPath;
@property (nonatomic, strong) NSString *HJVideoPath;
@property (nonatomic, strong) NSString *HJAudioPath;
@property (nonatomic, strong) NSString *HJOutputPath;

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
    
    NSArray *imageArr = @[[UIImage imageNamed:@"IMG_4340.JPG"],[UIImage imageNamed:@"IMG_4341.JPG"],[UIImage imageNamed:@"IMG_4342.JPG"],
                          [UIImage imageNamed:@"IMG_4343.JPG"],[UIImage imageNamed:@"IMG_4344.JPG"],[UIImage imageNamed:@"IMG_4345.JPG"],
                          [UIImage imageNamed:@"IMG_4346.JPG"],[UIImage imageNamed:@"IMG_4347.JPG"],[UIImage imageNamed:@"IMG_4348.JPG"],
                          [UIImage imageNamed:@"IMG_4349.JPG"],[UIImage imageNamed:@"IMG_4350.JPG"]];

    
    for (int i = 0; i<imageArr.count; i++) {
        UIImage *imageNew = imageArr[i];
        //设置image的尺寸
        CGSize imagesize = imageNew.size;
        imagesize.height =320;
        imagesize.width =480;
        //对图片大小进行压缩--
        imageNew = [self imageWithImage:imageNew scaledToSize:imagesize];
//        imageNew = [ViewController getThumImgOfConextWithData:imageNew withMaxPixelSize:408];
        [imageArray addObject:imageNew];
    }
    
    NSArray *pathVideo =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    self.HJVideoPath =[[pathVideo objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"HJtest_%@.mp4",[NSDate date]]];

    self.HJAudioPath =[[NSBundle mainBundle] pathForResource:@"黑白" ofType:@"mp3"];
    
    NSArray *pathOutput =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    self.HJOutputPath =[[pathOutput objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"HJoutput_%@.mov",[NSDate date]]];
    
    //图片合成视频
    [LXImagesToVideo videoFromImages:imageArray
                              toPath:self.HJVideoPath
                  animateTransitions:YES
                   withCallbackBlock:^(BOOL success) {
                       if (success) {
                           NSLog(@"Success");
                           //视频添加背景音乐
                           [self addBackGroundAudioTwo];
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
    
    
    NSURL * videoInputUrl = [NSURL fileURLWithPath:self.HJVideoPath];
    NSURL * audioInputUrl = [NSURL fileURLWithPath:self.HJAudioPath];
//    //合成之后的输出路径
//    NSString *outPutPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"mergeVideo-%d.mov",arc4random() % 1000]];
    //混合后的视频输出路径
    NSURL *outPutUrl = [NSURL fileURLWithPath:self.HJOutputPath];

    //时间起点
    CMTime nextClistartTime = kCMTimeZero;
    //创建可变的音视频组合
    AVMutableComposition * comosition = [AVMutableComposition composition];
    
    //视频采集
    AVURLAsset * videoAsset = [[AVURLAsset alloc] initWithURL:videoInputUrl options:nil];
    //视频时间范围
    CMTimeRange videoTimeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
    // 视频通道 枚举 kCMPersistentTrackID_Invalid = 0
    AVMutableCompositionTrack * videoTrack = [comosition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    //视频采集通道
    AVAssetTrack * videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    //把采集轨道数据加入到可变轨道中
    [videoTrack insertTimeRange:videoTimeRange ofTrack:videoAssetTrack atTime:nextClistartTime error:nil];
    
    
    
    //声音采集
    AVURLAsset * audioAsset = [[AVURLAsset alloc] initWithURL:audioInputUrl options:nil];
    //因为视频较短 所以直接用了视频的长度 如果想要自动化需要自己写判断
    CMTimeRange audioTimeRange = videoTimeRange;
    //音频通道
    AVMutableCompositionTrack * audioTrack = [comosition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    //音频采集通道
    AVAssetTrack * audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    //加入合成轨道中
    [audioTrack insertTimeRange:audioTimeRange ofTrack:audioAssetTrack atTime:nextClistartTime error:nil];
    
    
    
#warning test
    // 3.1 - Create AVMutableVideoCompositionInstruction
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
    
    // 3.2 - Create an AVMutableVideoCompositionLayerInstruction for the video track and fix the orientation.
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    UIImageOrientation videoAssetOrientation_  = UIImageOrientationUp;
    BOOL isVideoAssetPortrait_  = NO;
    CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
        videoAssetOrientation_ = UIImageOrientationRight;
        isVideoAssetPortrait_ = YES;
    }
    if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
        videoAssetOrientation_ =  UIImageOrientationLeft;
        isVideoAssetPortrait_ = YES;
    }
    if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
        videoAssetOrientation_ =  UIImageOrientationUp;
    }
    if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
        videoAssetOrientation_ = UIImageOrientationDown;
    }
    [videolayerInstruction setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];
    [videolayerInstruction setOpacity:0.0 atTime:videoAsset.duration];
    
    // 3.3 - Add instructions
    mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];
    
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    
    CGSize naturalSize;
    if(isVideoAssetPortrait_){
        naturalSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width);
    } else {
        naturalSize = videoAssetTrack.naturalSize;
    }
    float renderWidth, renderHeight;
    renderWidth = naturalSize.width;
    renderHeight = naturalSize.height;
    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
#warning test end 如果没有这段代码，合成后的视频会旋转90度
    
    //创建输出
    AVAssetExportSession * assetExport = [[AVAssetExportSession alloc] initWithAsset:comosition presetName:AVAssetExportPresetMediumQuality];
    assetExport.outputURL = outPutUrl;//输出路径
    assetExport.outputFileType = AVFileTypeQuickTimeMovie;//输出类型
    assetExport.shouldOptimizeForNetworkUse = YES;//是否优化   不太明白
    assetExport.videoComposition = mainCompositionInst;
    [assetExport exportAsynchronouslyWithCompletionHandler:^{
        switch (assetExport.status) {
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"AVAssetExportSessionStatusCancelled");
                break;
            case AVAssetExportSessionStatusUnknown:
                NSLog(@"AVAssetExportSessionStatusUnknown");
                break;
            case AVAssetExportSessionStatusWaiting:
                NSLog(@"AVAssetExportSessionStatusWaiting");
                break;
            case AVAssetExportSessionStatusExporting:
                NSLog(@"AVAssetExportSessionStatusExporting");
                break;
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"AVAssetExportSessionStatusCompleted");
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"AVAssetExportSessionStatusFailed");
                NSLog(@"failed  ---%@",assetExport.error.description);
                break;
        }
        if (assetExport.status == AVAssetExportSessionStatusCompleted) {
            NSLog(@" outputURL ---- %@", assetExport.outputURL);
        }
    }];
    
}


- (void)addBackGroundAudioTwo {
    
    NSURL * videoInputUrl = [NSURL fileURLWithPath:self.HJVideoPath];
    NSURL * audioInputUrl = [NSURL fileURLWithPath:self.HJAudioPath];
    NSURL *outPutUrl = [NSURL fileURLWithPath:self.HJOutputPath];
    
    //声音来源路径（最终混合的音频）
    NSURL   *audio_inputFileUrl = audioInputUrl;
    
    //视频来源路径
    NSURL   *video_inputFileUrl = videoInputUrl;
    
    //最终合成输出路径
//    NSString *outputFilePath =[documentsDirectorystringByAppendingPathComponent:@"final_video.mp4"];
    NSURL   *outputFileUrl = outPutUrl;
    
//    if([[NSFileManagerdefaultManager]fileExistsAtPath:outputFilePath])
//        [[NSFileManagerdefaultManager]removeItemAtPath:outputFilePatherror:nil];
    
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
    AVMutableCompositionTrack*b_compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
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
     }];
    NSLog(@"完成！输出路径==%@",outputFileUrl);

}

//对图片尺寸进行压缩--

-(UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize
{
    //    新创建的位图上下文 newSize为其大小
    UIGraphicsBeginImageContext(newSize);
    //    对图片进行尺寸的改变
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    //    从当前上下文中获取一个UIImage对象  即获取新的图片对象
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    // Return the new image.
    return newImage;
}

+ (UIImage*) getThumImgOfConextWithData:(UIImage*)img withMaxPixelSize:(int)maxPixelSize
{
    UIImage *imgResult = nil;
    if(img == nil)         { return imgResult; }
    if(maxPixelSize <= 0)   { return imgResult; }
    
    const int sizeTo = maxPixelSize; // 图片最大的宽/高
    CGSize sizeResult;
    if(img.size.width > img.size.height){ // 根据最大的宽/高 值，等比例计算出最终目标尺寸
        float value = img.size.width/ sizeTo;
        int height = img.size.height / value;
        sizeResult = CGSizeMake(sizeTo, height);
    } else {
        float value = img.size.height/ sizeTo;
        int width = img.size.width / value;
        sizeResult = CGSizeMake(width, sizeTo);
    }
    
    UIGraphicsBeginImageContextWithOptions(sizeResult, NO, 0);
    [img drawInRect:CGRectMake(0, 0, sizeResult.width, sizeResult.height)];
    img = nil;
    imgResult = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return imgResult;
}


-(void)testCompressionSession
{
    //设置mov路径
    NSArray *paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *moviePath =[[paths objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mov",@"test"]];
    self.theVideoPath=moviePath;
    
    //定义视频的大小320 480 倍数
    CGSize size =CGSizeMake(320,480);
    
    //        [selfwriteImages:imageArr ToMovieAtPath:moviePath withSize:sizeinDuration:4 byFPS:30];//第2中方法
    
    NSError *error =nil;
    //    转成UTF-8编码
    unlink([moviePath UTF8String]);
    NSLog(@"path->%@",moviePath);
    //     iphone提供了AVFoundation库来方便的操作多媒体设备，AVAssetWriter这个类可以方便的将图像和音频写成一个完整的视频文件
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:moviePath] fileType:AVFileTypeQuickTimeMovie error:&error];
    
    NSParameterAssert(videoWriter);
    if(error)
        NSLog(@"error =%@", [error localizedDescription]);
    //mov的格式设置 编码格式 宽度 高度
    NSDictionary *videoSettings =[NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264,AVVideoCodecKey,
                                  [NSNumber numberWithInt:size.width],AVVideoWidthKey,
                                  [NSNumber numberWithInt:size.height],AVVideoHeightKey,nil];
    
    AVAssetWriterInput *writerInput =[AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    NSDictionary*sourcePixelBufferAttributesDictionary =[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32ARGB],kCVPixelBufferPixelFormatTypeKey,nil];
    //    AVAssetWriterInputPixelBufferAdaptor提供CVPixelBufferPool实例,
    //    可以使用分配像素缓冲区写入输出文件。使用提供的像素为缓冲池分配通常
    //    是更有效的比添加像素缓冲区分配使用一个单独的池
    AVAssetWriterInputPixelBufferAdaptor *adaptor =[AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    
    if ([videoWriter canAddInput:writerInput])
    {
        NSLog(@"11111");
    }
    else
    {
        NSLog(@"22222");
    }
    
    [videoWriter addInput:writerInput];
    
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    //合成多张图片为一个视频文件
    dispatch_queue_t dispatchQueue =dispatch_queue_create("mediaInputQueue",NULL);
    int __block frame =0;
    [writerInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
        
        while([writerInput isReadyForMoreMediaData])
        {
            if(++frame >=[imageArray count]*10)
            {
                [writerInput markAsFinished];
                [videoWriter finishWriting];
                //              [videoWriterfinishWritingWithCompletionHandler:nil];
                break;
            }
            CVPixelBufferRef buffer =NULL;
            int idx =frame/10;
            NSLog(@"idx==%d",idx);
            buffer = (CVPixelBufferRef)[self pixelBufferFromCGImage:[[imageArray objectAtIndex:idx] CGImage] size:size];
            
            if (buffer)
            {
                if(![adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(frame,30)])//设置每秒钟播放图片的个数
                {
                    NSLog(@"FAIL");
                }
                else
                {
                    NSLog(@"OK");
                }
                
                CFRelease(buffer);
            }
        }
    }];
    
}

- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size
{
    NSDictionary *options =[NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithBool:YES],kCVPixelBufferCGImageCompatibilityKey,
                            [NSNumber numberWithBool:YES],kCVPixelBufferCGBitmapContextCompatibilityKey,nil];
    CVPixelBufferRef pxbuffer =NULL;
    CVReturn status =CVPixelBufferCreate(kCFAllocatorDefault,size.width,size.height,kCVPixelFormatType_32ARGB,(__bridge CFDictionaryRef) options,&pxbuffer);
    
    NSParameterAssert(status ==kCVReturnSuccess && pxbuffer !=NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer,0);
    
    void *pxdata =CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata !=NULL);
    CGColorSpaceRef rgbColorSpace=CGColorSpaceCreateDeviceRGB();
    //    当你调用这个函数的时候，Quartz创建一个位图绘制环境，也就是位图上下文。当你向上下文中绘制信息时，Quartz把你要绘制的信息作为位图数据绘制到指定的内存块。一个新的位图上下文的像素格式由三个参数决定：每个组件的位数，颜色空间，alpha选项
    CGContextRef context =CGBitmapContextCreate(pxdata,size.width,size.height,8,4*size.width,rgbColorSpace,kCGImageAlphaPremultipliedFirst);
    NSParameterAssert(context);
    
    //使用CGContextDrawImage绘制图片  这里设置不正确的话 会导致视频颠倒
    //    当通过CGContextDrawImage绘制图片到一个context中时，如果传入的是UIImage的CGImageRef，因为UIKit和CG坐标系y轴相反，所以图片绘制将会上下颠倒
    CGContextDrawImage(context,CGRectMake(0,0,CGImageGetWidth(image),CGImageGetHeight(image)), image);
    // 释放色彩空间
    CGColorSpaceRelease(rgbColorSpace);
    // 释放context
    CGContextRelease(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(pxbuffer,0);
    
    return pxbuffer;
}

//播放
-(void)playAction
{
//    NSLog(@"************%@",self.HJOutputPath);
//    NSURL *sourceMovieURL = [NSURL fileURLWithPath:self.HJOutputPath];
//    AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:sourceMovieURL options:nil];
//    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
//    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
//    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
//    playerLayer.frame = self.view.layer.bounds;
//    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
//    [self.view.layer addSublayer:playerLayer];
//    [player play];
    
    MPMoviePlayerViewController *theMovie =[[MPMoviePlayerViewController alloc]initWithContentURL:[NSURL fileURLWithPath:self.HJOutputPath]];
    [self presentMoviePlayerViewControllerAnimated:theMovie];
    theMovie.moviePlayer.movieSourceType=MPMovieSourceTypeFile;
    [theMovie.moviePlayer play];
    
}

@end
