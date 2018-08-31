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

    
    NSArray *imageArr = @[[UIImage imageNamed:@"IMG_4340.JPG"],[UIImage imageNamed:@"IMG_4341.JPG"],[UIImage imageNamed:@"IMG_4342.JPG"],
                          [UIImage imageNamed:@"IMG_4343.JPG"],[UIImage imageNamed:@"IMG_4344.JPG"],[UIImage imageNamed:@"IMG_4345.JPG"],
                          [UIImage imageNamed:@"IMG_4346.JPG"]];

    
    for (int i = 0; i<imageArr.count; i++) {
        UIImage *imageNew = imageArr[i];
        
        
        
        
        //设置image的尺寸
        CGSize imagesize = imageNew.size;
        NSLog(@"i = %d width = %f,  height = %f",i,imagesize.width,imagesize.height);
        imagesize.height =480;
        imagesize.width =640;
        //对图片大小进行压缩--
        imageNew = [self imageWithImage:imageNew scaledToSize:imagesize];
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
    
    
    NSURL * videoInputUrl = [NSURL fileURLWithPath:self.videoPath];
    NSURL * audioInputUrl = [NSURL fileURLWithPath:self.audioPath];
//    //合成之后的输出路径
//    NSString *outPutPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"mergeVideo-%d.mov",arc4random() % 1000]];
    //混合后的视频输出路径
    NSURL *outPutUrl = [NSURL fileURLWithPath:self.outputPath];

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
    
    NSURL * videoInputUrl = [NSURL fileURLWithPath:self.videoPath];
    NSURL * audioInputUrl = [NSURL fileURLWithPath:self.audioPath];
    NSURL *outPutUrl = [NSURL fileURLWithPath:self.outputPath];
    
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

    CGSize newSize = CGSizeMake(640, 480);
    UIGraphicsBeginImageContext(newSize);
//    [gaussImg drawInRect:CGRectMake(-320,-240,newSize.width*2,newSize.height*2)];
    [gaussImg drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];

    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (UIImage *)coreBlurImage:(UIImage *)image
            withBlurNumber:(CGFloat)blur {
    //博客园-FlyElephant
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage  *inputImage=[CIImage imageWithCGImage:image.CGImage];
    //设置filter
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    [filter setValue:@(blur) forKey: @"inputRadius"];
    //模糊图片
    CIImage *result=[filter valueForKey:kCIOutputImageKey];
    CGImageRef outImage=[context createCGImage:result fromRect:[result extent]];
    UIImage *blurImage=[UIImage imageWithCGImage:outImage];
    CGImageRelease(outImage);
    return blurImage;
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


+ (UIImage*)getThumImgOfConextWithData:(UIImage*)img withMaxPixelSize:(int)maxPixelSize
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
