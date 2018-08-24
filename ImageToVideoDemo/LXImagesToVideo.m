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

BOOL const DefaultTransitionShouldAnimate = YES;

@implementation LXImagesToVideo

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
                    
                    if (i <= 2) {//缩小效果
                        buffer = [LXImagesToVideo playScaleInFromImage:[array[i] CGImage]
                                                              fromSize:DefaultFrameSize
                                                             FromScale:1.04
                                                               Toscale:1.04-j*0.001];
                    }
                    else if (i <= 4){
                        buffer = [LXImagesToVideo playScaleInFromImage:[array[i] CGImage]
                                                              fromSize:DefaultFrameSize
                                                             FromScale:1
                                                               Toscale:1+j*0.001];
                    }
                    else {
                        buffer = [LXImagesToVideo playLeftToRightFromImage:[array[i] CGImage]
                                                                    atSize:DefaultFrameSize
                                                                 withframe:CGPointMake(j*(DefaultFrameSize.width*0.04/FramesToWaitBeforeTransition), j*(DefaultFrameSize.height*0.04/FramesToWaitBeforeTransition))
                                                                 baseScale:1.04];
                    }
                    
                    
                    
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
                    
                    NSInteger framesToFadeCount = TransitionFrameCount - FramesToWaitBeforeTransition;
                    
                    //40-50 转场动画
                    for (double j = 0; j < framesToFadeCount; j++) {
                        if (i <= 1) {
                            buffer = [LXImagesToVideo crossFadeImage:[array[i] CGImage]
                                                             toImage:[array[i + 1] CGImage]
                                                              atSize:DefaultFrameSize
                                                           withAlpha:j/framesToFadeCount
                                                           baseScale:1
                                                             toScale:1.04];
                        }
                        else if (i == 2) {
                            buffer = [LXImagesToVideo crossLeftToRightFromImage:[array[i] CGImage]
                                                                        toImage:[array[i + 1] CGImage]
                                                                         atSize:DefaultFrameSize
                                                                      withframe:CGPointMake(j*(DefaultFrameSize.width/framesToFadeCount), j*(DefaultFrameSize.height/framesToFadeCount))
                                                                      baseScale:1];
                        }
                        else {
                            buffer = [LXImagesToVideo crossLeftToRightFromImage:[array[i] CGImage]
                                                                        toImage:[array[i + 1] CGImage]
                                                                         atSize:DefaultFrameSize
                                                                      withframe:CGPointMake(j*(DefaultFrameSize.width/framesToFadeCount), j*(DefaultFrameSize.height/framesToFadeCount))
                                                                      baseScale:1.04];
                        }

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

+ (CVPixelBufferRef)crossFadeImage:(CGImageRef)baseImage
                           toImage:(CGImageRef)fadeInImage
                            atSize:(CGSize)imageSize
                         withAlpha:(CGFloat)alpha
                         baseScale:(CGFloat)baseScaleFloat
                           toScale:(CGFloat)toScaleFloat
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
    
    CGRect drawRect = CGRectMake(0 + (imageSize.width-CGImageGetWidth(baseImage))/2,
                                 (imageSize.height-CGImageGetHeight(baseImage))/2,
                                 CGImageGetWidth(baseImage),
                                 CGImageGetHeight(baseImage));
    
    CGContextSaveGState(context);
    CGContextScaleCTM(context, baseScaleFloat, baseScaleFloat);
    CGContextDrawImage(context, drawRect, baseImage);
    CGContextRestoreGState(context);
    
    CGContextBeginTransparencyLayer(context, nil);
    CGContextSetAlpha(context, alpha);
    CGContextScaleCTM(context, toScaleFloat, toScaleFloat);
    CGContextDrawImage(context, drawRect, fadeInImage);
    CGContextEndTransparencyLayer(context);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

#pragma mark - play Animation

+ (CVPixelBufferRef)playScaleInFromImage:(CGImageRef)baseImage
                                fromSize:(CGSize)fromImageSize
                               FromScale:(CGFloat)fromScaleFloat
                                 Toscale:(CGFloat)toScaleFloat
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
    
    CGRect drawRectBase = CGRectMake(0 + (fromImageSize.width-CGImageGetWidth(baseImage))/2,
                                     (fromImageSize.height-CGImageGetHeight(baseImage))/2,
                                     CGImageGetWidth(baseImage),
                                     CGImageGetHeight(baseImage));
    
    CGContextSaveGState(context);
    CGContextScaleCTM(context, fromScaleFloat, fromScaleFloat);
    CGContextDrawImage(context, drawRectBase, baseImage);
    CGContextRestoreGState(context);
    
    
    CGContextBeginTransparencyLayer(context, nil);
    CGContextScaleCTM(context, toScaleFloat, toScaleFloat);
    CGContextDrawImage(context, drawRectBase, baseImage);
    CGContextEndTransparencyLayer(context);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

+ (CVPixelBufferRef)playLeftToRightFromImage:(CGImageRef)baseImage
                                      atSize:(CGSize)imageSize
                                   withframe:(CGPoint)point
                                   baseScale:(CGFloat)baseScaleFloat
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
    
    CGRect drawRectBase = CGRectMake(0,
                                     0,
                                     CGImageGetWidth(baseImage),
                                     CGImageGetHeight(baseImage));
    
    CGContextSaveGState(context);
    CGContextScaleCTM(context, baseScaleFloat, baseScaleFloat);
    CGContextDrawImage(context, drawRectBase, baseImage);
    CGContextRestoreGState(context);
    
    
    CGContextBeginTransparencyLayer(context, nil);
    CGContextTranslateCTM(context, -point.x, 0);
    
    CGContextSaveGState(context);
    CGContextScaleCTM(context, baseScaleFloat, baseScaleFloat);
    CGContextDrawImage(context, drawRectBase, baseImage);
    CGContextRestoreGState(context);
    
    CGContextEndTransparencyLayer(context);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

#pragma mark - cross Animation

+ (CVPixelBufferRef)crossLeftToRightFromImage:(CGImageRef)baseImage
                                      toImage:(CGImageRef)fadeInImage
                                       atSize:(CGSize)imageSize
                                    withframe:(CGPoint)point
                                    baseScale:(CGFloat)baseScaleFloat
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
    
    CGRect drawRectBase = CGRectMake(0,
                                     0,
                                     CGImageGetWidth(baseImage),
                                     CGImageGetHeight(baseImage));
    
    CGContextSaveGState(context);
    CGContextScaleCTM(context, baseScaleFloat, baseScaleFloat);
    CGContextDrawImage(context, drawRectBase, baseImage);
    CGContextRestoreGState(context);
    
    CGRect drawRectFadeIn = CGRectMake(-imageSize.width,
                                       0,
                                       imageSize.width,
                                       imageSize.height);
    
    CGContextDrawImage(context, drawRectFadeIn, fadeInImage);
    
    CGContextBeginTransparencyLayer(context, nil);
    CGContextTranslateCTM(context, point.x, 0);
    
    CGContextSaveGState(context);
    CGContextScaleCTM(context, baseScaleFloat, baseScaleFloat);
    CGContextDrawImage(context, drawRectBase, baseImage);
    CGContextRestoreGState(context);
    
    CGContextDrawImage(context, drawRectFadeIn, fadeInImage);
    CGContextEndTransparencyLayer(context);
    
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




@end
