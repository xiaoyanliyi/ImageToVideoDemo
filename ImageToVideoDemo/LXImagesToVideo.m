//
//  LXImagesToVideo.m
//  ImageToVideoDemo
//
//  Created by lx on 2018/8/17.
//  Copyright © 2018年 lx. All rights reserved.
//

#import "LXImagesToVideo.h"

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

CGSize const DefaultFrameSize                             = (CGSize){480, 320};

NSInteger const DefaultShowPicSecond                      = 2;
NSInteger const DefaultFrameRate                          = 1;
NSInteger const TransitionFrameCount                      = 50;
NSInteger const FramesToWaitBeforeTransition              = 40;
NSInteger const crossTransition                           = 10; // crossTransition = TransitionFrameCount - FramesToWaitBeforeTransition


BOOL const DefaultTransitionShouldAnimate = YES;

@implementation LXImagesToVideo


#pragma mark - Public Method

+ (void)videoFromImages:(NSArray *)images
                 toPath:(NSString *)path
      withCallbackBlock:(SuccessBlock)callbackBlock
{
    [LXImagesToVideo videoFromImages:images
                              toPath:path
                            withSize:DefaultFrameSize
                             withFPS:DefaultFrameRate
                  animateTransitions:DefaultTransitionShouldAnimate
                   withCallbackBlock:callbackBlock];
}

+ (void)videoFromImages:(NSArray *)images
                 toPath:(NSString *)path
     animateTransitions:(BOOL)animate
      withCallbackBlock:(SuccessBlock)callbackBlock
{
    [LXImagesToVideo videoFromImages:images
                              toPath:path
                            withSize:DefaultFrameSize
                             withFPS:DefaultFrameRate
                  animateTransitions:animate
                   withCallbackBlock:callbackBlock];
}

+ (void)videoFromImages:(NSArray *)images
                 toPath:(NSString *)path
                withFPS:(int)fps
     animateTransitions:(BOOL)animate
      withCallbackBlock:(SuccessBlock)callbackBlock
{
    [LXImagesToVideo videoFromImages:images
                              toPath:path
                            withSize:DefaultFrameSize
                             withFPS:fps
                  animateTransitions:animate
                   withCallbackBlock:callbackBlock];
}

+ (void)videoFromImages:(NSArray *)images
                 toPath:(NSString *)path
               withSize:(CGSize)size
     animateTransitions:(BOOL)animate
      withCallbackBlock:(SuccessBlock)callbackBlock
{
    [LXImagesToVideo videoFromImages:images
                              toPath:path
                            withSize:size
                             withFPS:DefaultFrameRate
                  animateTransitions:animate
                   withCallbackBlock:callbackBlock];
}

+ (void)videoFromImages:(NSArray *)images
                 toPath:(NSString *)path
               withSize:(CGSize)size
                withFPS:(int)fps
     animateTransitions:(BOOL)animate
      withCallbackBlock:(SuccessBlock)callbackBlock
{
    [LXImagesToVideo writeImageAsMovie:images
                                toPath:path
                                  size:size
                                   fps:fps
                    animateTransitions:animate
                     withCallbackBlock:callbackBlock];
}

+ (void)saveVideoToPhotosWithImages:(NSArray *)images
                  withCallbackBlock:(SuccessBlock)callbackBlock
{
    [LXImagesToVideo saveVideoToPhotosWithImages:images
                                        withSize:DefaultFrameSize
                              animateTransitions:DefaultTransitionShouldAnimate
                               withCallbackBlock:callbackBlock];
}

+ (void)saveVideoToPhotosWithImages:(NSArray *)images
                 animateTransitions:(BOOL)animate
                  withCallbackBlock:(SuccessBlock)callbackBlock
{
    [LXImagesToVideo saveVideoToPhotosWithImages:images
                                        withSize:DefaultFrameSize
                              animateTransitions:animate
                               withCallbackBlock:callbackBlock];
}

+ (void)saveVideoToPhotosWithImages:(NSArray *)images
                           withSize:(CGSize)size
                 animateTransitions:(BOOL)animate
                  withCallbackBlock:(SuccessBlock)callbackBlock
{
    [LXImagesToVideo saveVideoToPhotosWithImages:images
                                        withSize:size
                                         withFPS:DefaultFrameRate
                              animateTransitions:animate
                               withCallbackBlock:callbackBlock];
}

+ (void)saveVideoToPhotosWithImages:(NSArray *)images
                            withFPS:(int)fps
                 animateTransitions:(BOOL)animate
                  withCallbackBlock:(SuccessBlock)callbackBlock
{
    [LXImagesToVideo saveVideoToPhotosWithImages:images
                                        withSize:DefaultFrameSize
                                         withFPS:fps
                              animateTransitions:animate
                               withCallbackBlock:callbackBlock];
}

+ (void)saveVideoToPhotosWithImages:(NSArray *)images
                           withSize:(CGSize)size
                            withFPS:(int)fps
                 animateTransitions:(BOOL)animate
                  withCallbackBlock:(SuccessBlock)callbackBlock
{
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
                          [NSString stringWithFormat:@"temp.mp4"]];
    [[NSFileManager defaultManager] removeItemAtPath:tempPath error:NULL];
    
    [LXImagesToVideo videoFromImages:images
                              toPath:tempPath
                            withSize:size
                             withFPS:fps
                  animateTransitions:animate
                   withCallbackBlock:^(BOOL success) {
                       
                       if (success) {
                           UISaveVideoAtPathToSavedPhotosAlbum(tempPath, self, nil, nil);
                       }
                       
                       if (callbackBlock) {
                           callbackBlock(success);
                       }
                   }];
}

#pragma mark - Private Method

+ (void)writeImageAsMovie:(NSArray *)array
                   toPath:(NSString*)path
                     size:(CGSize)size
                      fps:(int)fps
       animateTransitions:(BOOL)shouldAnimateTransitions
        withCallbackBlock:(SuccessBlock)callbackBlock
{
    NSLog(@"path : %@", path);
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path]
                                                           fileType:AVFileTypeMPEG4
                                                              error:&error];
    if (error) {
        if (callbackBlock) {
            callbackBlock(NO);
        }
        return;
    }
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = @{AVVideoCodecKey: AVVideoCodecH264,
                                    AVVideoWidthKey: [NSNumber numberWithInt:size.width],
                                    AVVideoHeightKey: [NSNumber numberWithInt:size.height]};
    
    AVAssetWriterInput* writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                         outputSettings:videoSettings];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                                                                                     sourcePixelBufferAttributes:nil];
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    [videoWriter addInput:writerInput];
    
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    CVPixelBufferRef buffer;
    CVPixelBufferPoolCreatePixelBuffer(NULL, adaptor.pixelBufferPool, &buffer);
    
    CMTime presentTime = CMTimeMake(0, fps);
    
    int i = 0;
    while (1)
    {
        
        if(writerInput.readyForMoreMediaData){
            
            presentTime = CMTimeMake(i * DefaultShowPicSecond, fps);
            
            if (i >= [array count]) {
                buffer = NULL;
            } else {
                CMTime fadeTime = CMTimeMake(DefaultShowPicSecond, fps*TransitionFrameCount);
                //画面不动
                //                buffer = [LXImagesToVideo pixelBufferFromCGImage:[array[i] CGImage] size:DefaultFrameSize];
                
                //0-40 播放图片
                for (int j = 0; j < FramesToWaitBeforeTransition; j++) {
                    
//                    if (i <= 2) {//缩小效果
                    
                        CGRect baseFrame = CGRectMake(-DefaultFrameSize.width * 0.04 / 2, -DefaultFrameSize.height * 0.04 / 2, DefaultFrameSize.width * 1.04, DefaultFrameSize.height * 1.04);
                        CGRect toFrame = CGRectMake(0, 0, DefaultFrameSize.width, DefaultFrameSize.height);

                        buffer = [LXImagesToVideo playScaleInFromImage:[array[i] CGImage]
                                                              fromSize:DefaultFrameSize
                                                             baseFrame:baseFrame
                                                               toFrame:toFrame
                                                                   ctm:j];
//                    }
//                    else if (i <= 4){ //放大效果
//                        CGRect baseFrame = CGRectMake(0, 0, DefaultFrameSize.width, DefaultFrameSize.height);
//                        CGRect toFrame = CGRectMake(-DefaultFrameSize.width * 0.04 / 2, -DefaultFrameSize.height * 0.04 / 2, DefaultFrameSize.width * 1.04, DefaultFrameSize.height * 1.04);
//
//                        buffer = [LXImagesToVideo playScaleInFromImage:[array[i] CGImage]
//                                                          fromSize:DefaultFrameSize
//                                                         baseFrame:baseFrame
//                                                           toFrame:toFrame
//                                                               ctm:j];
//                    }
//                    else {
//                        CGRect baseFrame = CGRectMake(-DefaultFrameSize.width*0.04, 0, DefaultFrameSize.width * 1.04, DefaultFrameSize.height * 1.04);
//                        CGRect toFrame = CGRectMake(0, 0, DefaultFrameSize.width * 1.04, DefaultFrameSize.height * 1.04);
//
//                        buffer = [LXImagesToVideo playLeftToRightFromImage:[array[i] CGImage]
//                                                                    atSize:DefaultFrameSize
//                                                                 baseFrame:baseFrame
//                                                                   toFrame:toFrame
//                                                                       ctm:j];
                    
//                    }
                    
                    
                    
                    BOOL appendSuccess = [LXImagesToVideo appendToAdapter:adaptor
                                                              pixelBuffer:buffer
                                                                   atTime:presentTime
                                                                withInput:writerInput];
                    presentTime = CMTimeAdd(presentTime, fadeTime);
                    NSAssert(appendSuccess, @"Failed to append");
                }
            }
            if (buffer) {
                if (shouldAnimateTransitions && i + 1 < array.count) {
                    
                    CMTime fadeTime = CMTimeMake(DefaultShowPicSecond, fps*TransitionFrameCount);
                    
                    //40-50 转场动画
                    for (double j = 0; j < crossTransition; j++) {
//                        if (i <= 1) {
//                            CGRect baseFrame = CGRectMake(0, 0, DefaultFrameSize.width, DefaultFrameSize.height);
//                            CGRect toFrame = CGRectMake(-DefaultFrameSize.width * 0.04 / 2, -DefaultFrameSize.height * 0.04 / 2, DefaultFrameSize.width * 1.04, DefaultFrameSize.height * 1.04);
//
//                            buffer = [LXImagesToVideo crossFadeImage:[array[i] CGImage]
//                                                             toImage:[array[i + 1] CGImage]
//                                                              atSize:DefaultFrameSize
//                                                           baseFrame:baseFrame
//                                                             toframe:toFrame
//                                                                 ctm:j];
//                        }
//                        else if (i == 2) {
                        
//                            CGRect baseFrame = CGRectMake(0, 0, DefaultFrameSize.width, DefaultFrameSize.height);
//                            CGRect toFrame = CGRectMake(-DefaultFrameSize.width * 0.04 / 2, -DefaultFrameSize.height * 0.04 / 2, DefaultFrameSize.width * 1.04, DefaultFrameSize.height * 1.04);
//
//                            buffer = [LXImagesToVideo crossLeftToRightFromImage:[array[i] CGImage]
//                                                                        toImage:[array[i + 1] CGImage]
//                                                                         atSize:DefaultFrameSize
//                                                                      baseFrame:baseFrame
//                                                                        toframe:toFrame
//                                                                            ctm:j];
//                        }
//                        else {
//
//
//                            CGRect toFrame = CGRectMake(-DefaultFrameSize.width*0.04, 0, DefaultFrameSize.width * 1.04, DefaultFrameSize.height * 1.04);
//
//                            buffer = [LXImagesToVideo crossZoomInImage:[array[i] CGImage]
//                                                               toImage:[array[i + 1] CGImage]
//                                                                atSize:DefaultFrameSize
//                                                               toframe:toFrame
//                                                             baseScale:1.04
//                                                               toScale:1.04
//                                                                  zoom:j];
                        
                        
                            CGRect baseFrame = CGRectMake(0, 0, DefaultFrameSize.width, DefaultFrameSize.height);
                            CGRect toFrame = CGRectMake(0, 0, DefaultFrameSize.width, DefaultFrameSize.height);
                        
                            buffer = [LXImagesToVideo crossTopRotateFromImage:[array[i] CGImage]
                                                                      toImage:[array[i + 1] CGImage]
                                                                       atSize:DefaultFrameSize
                                                                    baseFrame:baseFrame
                                                                      toframe:toFrame
                                                                          ctm:j];

                        
                        
//                        }

                        BOOL appendSuccess = [LXImagesToVideo appendToAdapter:adaptor
                                                                  pixelBuffer:buffer
                                                                       atTime:presentTime
                                                                    withInput:writerInput];
                        presentTime = CMTimeAdd(presentTime, fadeTime);
                        
                        NSAssert(appendSuccess, @"Failed to append");
                    }
                }
                i++;
            } else {
                //Finish the session:
                [writerInput markAsFinished];
                
                [videoWriter finishWritingWithCompletionHandler:^{
                    NSLog(@"Successfully closed video writer");
                    if (videoWriter.status == AVAssetWriterStatusCompleted) {
                        if (callbackBlock) {
                            callbackBlock(YES);
                        }
                    } else {
                        if (callbackBlock) {
                            callbackBlock(NO);
                        }
                    }
                }];
                
                CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
                
                NSLog (@"Done");
                break;
            }
        }
    }
}

+ (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image
                                      size:(CGSize)imageSize
{
    NSDictionary *options = @{(id)kCVPixelBufferCGImageCompatibilityKey: @YES,
                              (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES};
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, imageSize.width,
                                          imageSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, imageSize.width,
                                                 imageSize.height, 8, 4*imageSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    CGContextDrawImage(context, CGRectMake(0 + (imageSize.width-CGImageGetWidth(image))/2,
                                           (imageSize.height-CGImageGetHeight(image))/2,
                                           CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}


+ (BOOL)appendToAdapter:(AVAssetWriterInputPixelBufferAdaptor*)adaptor
            pixelBuffer:(CVPixelBufferRef)buffer
                 atTime:(CMTime)presentTime
              withInput:(AVAssetWriterInput*)writerInput
{
    while (!writerInput.readyForMoreMediaData) {
        usleep(1);
    }
    
    return [adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
}



#pragma mark - play Animation

+ (CVPixelBufferRef)playScaleInFromImage:(CGImageRef)baseImage
                                fromSize:(CGSize)fromImageSize
                               baseFrame:(CGRect)baseFrame
                                 toFrame:(CGRect)toFrame
                                     ctm:(NSInteger)ctm
{
    NSDictionary *options = @{(id)kCVPixelBufferCGImageCompatibilityKey: @YES,
                              (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES};
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, fromImageSize.width,
                                          fromImageSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, fromImageSize.width,
                                                 fromImageSize.height, 8, 4*fromImageSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    CGRect drawRect;
    if (baseFrame.size.width > toFrame.size.width) { //缩小效果
        drawRect = CGRectMake((baseFrame.origin.x - toFrame.origin.x) / FramesToWaitBeforeTransition * (FramesToWaitBeforeTransition - ctm),
                              (baseFrame.origin.y - toFrame.origin.y) / FramesToWaitBeforeTransition * (FramesToWaitBeforeTransition - ctm),
                              (baseFrame.size.width - toFrame.size.width) / FramesToWaitBeforeTransition * (FramesToWaitBeforeTransition - ctm) + toFrame.size.width,
                              (baseFrame.size.height - toFrame.size.height) / FramesToWaitBeforeTransition * (FramesToWaitBeforeTransition - ctm) + toFrame.size.height);
    }
    else { //放大
        drawRect = CGRectMake((baseFrame.origin.x - toFrame.origin.x) / FramesToWaitBeforeTransition * ctm,
                              (baseFrame.origin.y - toFrame.origin.y) / FramesToWaitBeforeTransition * ctm,
                              (baseFrame.size.width - toFrame.size.width) / FramesToWaitBeforeTransition * ctm + toFrame.size.width,
                              (baseFrame.size.height - toFrame.size.height) / FramesToWaitBeforeTransition * ctm + toFrame.size.height);
    }
    
    CGContextBeginTransparencyLayer(context, nil);
    CGContextDrawImage(context, drawRect, baseImage);
    CGContextEndTransparencyLayer(context);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

+ (CVPixelBufferRef)playLeftToRightFromImage:(CGImageRef)baseImage
                                      atSize:(CGSize)imageSize
                                   baseFrame:(CGRect)baseFrame
                                     toFrame:(CGRect)toFrame
                                         ctm:(NSInteger)ctm
{
    NSDictionary *options = @{(id)kCVPixelBufferCGImageCompatibilityKey: @YES,
                              (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES};
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, imageSize.width,
                                          imageSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, imageSize.width,
                                                 imageSize.height, 8, 4*imageSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    CGRect drawRectBase = baseFrame;
    
    CGContextBeginTransparencyLayer(context, nil);
    CGContextTranslateCTM(context, (toFrame.origin.x - baseFrame.origin.x)/FramesToWaitBeforeTransition*ctm, (toFrame.origin.y - baseFrame.origin.y)/FramesToWaitBeforeTransition*ctm);
    
    CGContextDrawImage(context, drawRectBase, baseImage);
    
    CGContextEndTransparencyLayer(context);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

#pragma mark - cross Animation

+ (CVPixelBufferRef)crossFadeImage:(CGImageRef)baseImage
                           toImage:(CGImageRef)fadeInImage
                            atSize:(CGSize)imageSize
                         baseFrame:(CGRect)baseFrame
                           toframe:(CGRect)toFrame
                               ctm:(NSInteger)ctm
{
    NSDictionary *options = @{(id)kCVPixelBufferCGImageCompatibilityKey: @YES,
                              (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES};
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, imageSize.width,
                                          imageSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, imageSize.width,
                                                 imageSize.height, 8, 4*imageSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    CGRect drawRectBase = baseFrame;
    
    CGRect drawRectFadeIn = toFrame;
    
    CGContextDrawImage(context, drawRectBase, baseImage);
   
    CGContextBeginTransparencyLayer(context, nil);
    CGContextSetAlpha(context, (CGFloat)ctm/crossTransition);
    CGContextScaleCTM(context, 1, 1);
    CGContextDrawImage(context, drawRectFadeIn, fadeInImage);
    CGContextEndTransparencyLayer(context);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

+ (CVPixelBufferRef)crossLeftToRightFromImage:(CGImageRef)baseImage
                                      toImage:(CGImageRef)fadeInImage
                                       atSize:(CGSize)imageSize
                                    baseFrame:(CGRect)baseFrame
                                      toframe:(CGRect)toFrame
                                          ctm:(NSInteger)ctm
{
    NSDictionary *options = @{(id)kCVPixelBufferCGImageCompatibilityKey: @YES,
                              (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES};
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, imageSize.width,
                                          imageSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, imageSize.width,
                                                 imageSize.height, 8, 4*imageSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    CGRect drawRectBase = baseFrame;
    
    CGRect drawRectFadeIn = CGRectMake(-toFrame.size.width,
                                       toFrame.origin.y,
                                       toFrame.size.width,
                                       toFrame.size.height);
    
    CGContextBeginTransparencyLayer(context, nil);
    CGContextTranslateCTM(context, ((toFrame.size.width - baseFrame.size.width) / 2 + baseFrame.size.width) / crossTransition * (ctm+1), 0);
    
    CGContextDrawImage(context, drawRectBase, baseImage);
    
    CGContextDrawImage(context, drawRectFadeIn, fadeInImage);
    CGContextEndTransparencyLayer(context);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

+ (CVPixelBufferRef)crossZoomInImage:(CGImageRef)baseImage
                             toImage:(CGImageRef)fadeInImage
                              atSize:(CGSize)imageSize
                             toframe:(CGRect)toFrame
                           baseScale:(CGFloat)baseScaleFloat
                             toScale:(CGFloat)toScaleFloat
                                zoom:(NSInteger)zoom //缩放系数 帧率
{
    NSDictionary *options = @{(id)kCVPixelBufferCGImageCompatibilityKey: @YES,
                              (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES};
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, imageSize.width,
                                          imageSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, imageSize.width,
                                                 imageSize.height, 8, 4*imageSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    CGRect drawRectBase = CGRectMake((imageSize.width / 2) * ((CGFloat)zoom / crossTransition),
                                     (imageSize.height / 2) * ((CGFloat)zoom / crossTransition),
                                     imageSize.width * ((CGFloat)(crossTransition - zoom) / crossTransition),
                                     imageSize.height * ((CGFloat)(crossTransition - zoom) / crossTransition));
    
    CGRect drawRectFadeIn = toFrame;
    
    CGContextSaveGState(context);
    CGContextDrawImage(context, drawRectFadeIn, fadeInImage);
    CGContextRestoreGState(context);
    
    CGContextBeginTransparencyLayer(context, nil);
    CGContextScaleCTM(context, baseScaleFloat, baseScaleFloat);
    CGContextDrawImage(context, drawRectBase, baseImage);
    CGContextEndTransparencyLayer(context);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

+ (CVPixelBufferRef)crossTopRotateFromImage:(CGImageRef)baseImage
                                    toImage:(CGImageRef)fadeInImage
                                     atSize:(CGSize)imageSize
                                  baseFrame:(CGRect)baseFrame
                                    toframe:(CGRect)toFrame
                                        ctm:(NSInteger)ctm
{
    NSDictionary *options = @{(id)kCVPixelBufferCGImageCompatibilityKey: @YES,
                              (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES};
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, imageSize.width,
                                          imageSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, imageSize.width,
                                                 imageSize.height, 8, 4*imageSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    CGRect drawRectBase = baseFrame;
    CGRect drawRectFadeIn = CGRectMake(-toFrame.size.width/2, -toFrame.size.height, toFrame.size.width, toFrame.size.height);
    
    CGContextDrawImage(context, drawRectBase, baseImage);
    
    CGContextTranslateCTM(context, imageSize.width/2, imageSize.height);
    CGContextRotateCTM(context, (180 * M_PI / 180));

    CGContextBeginTransparencyLayer(context, nil);
    
    CGContextRotateCTM(context, (-180 * M_PI / 180) * ((CGFloat)ctm / crossTransition));
    
    CGContextDrawImage(context, drawRectFadeIn, fadeInImage);
    CGContextEndTransparencyLayer(context);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}


+ (CVPixelBufferRef)crossTransitionType:(ImgToVideoTransitionAnimationType)crossType
                              baseImage:(CGImageRef)baseImage
                                toImage:(CGImageRef)fadeInImage
                                 atSize:(CGSize)imageSize
                              baseScale:(CGFloat)baseScaleFloat
                                toScale:(CGFloat)toScaleFloat
                               baseRect:(CGRect)baseRect
                                 toRect:(CGRect)toRect
                                   zoom:(NSInteger)zoom //缩放系数 帧率
{
    NSDictionary *options = @{(id)kCVPixelBufferCGImageCompatibilityKey: @YES,
                              (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES};
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, imageSize.width,
                                          imageSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, imageSize.width,
                                                 imageSize.height, 8, 4*imageSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    CGRect drawRectBase = baseRect;
    CGRect drawRectFadeIn = toRect;
    
    
    CGContextSaveGState(context);
    CGContextScaleCTM(context, toScaleFloat, toScaleFloat);
    CGContextDrawImage(context, drawRectFadeIn, fadeInImage);
    CGContextRestoreGState(context);
    
    CGContextSaveGState(context);
    CGContextScaleCTM(context, baseScaleFloat, baseScaleFloat);
    CGContextDrawImage(context, drawRectBase, baseImage);
    CGContextRestoreGState(context);
    
    
    CGContextBeginTransparencyLayer(context, nil);
    CGContextTranslateCTM(context, 0, 0);
    CGContextDrawImage(context, drawRectFadeIn, fadeInImage);
    CGContextScaleCTM(context, toScaleFloat, toScaleFloat);
    CGContextDrawImage(context, drawRectBase, baseImage);
    
    CGContextEndTransparencyLayer(context);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}


@end
