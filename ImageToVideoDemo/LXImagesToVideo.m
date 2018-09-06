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


@implementation LXVideoParameter

@end


@implementation LXImagesToVideo

#pragma mark - Public Method

+ (void)writeImageAsMovie:(NSArray *)imageArray
            playAnimation:(NSArray *)playAnimationArray
           crossAnimation:(NSArray *)crossAnimationArray
           videoParamater:(LXVideoParameter *)param
        withCallbackBlock:(SuccessBlock)callbackBlock {
    
    NSLog(@"path : %@", param.videoPathStr);
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:param.videoPathStr]
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
                                    AVVideoWidthKey: [NSNumber numberWithInt:param.frameSize.width],
                                    AVVideoHeightKey: [NSNumber numberWithInt:param.frameSize.height]};
    
    AVAssetWriterInput* writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                         outputSettings:videoSettings];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                                                                                     sourcePixelBufferAttributes:nil];
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    [videoWriter addInput:writerInput];
    
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    CVPixelBufferRef buffer;
    CVPixelBufferPoolCreatePixelBuffer(NULL, adaptor.pixelBufferPool, &buffer);
    
    CMTime presentTime = CMTimeMake(0, (int)param.frameRate);
    
    NSInteger framesToWaitBeforeTransition = param.transitionFrameCount - param.crossTransition;
    
    CGRect playBaseFrame;
    CGRect playToFrame;
    CGRect crossBaseFrame;
    CGRect crossToFrame;
    
    //ImgToVideoWaitAnimationType
    switch ((ImgToVideoPlayAnimationType)[playAnimationArray[0] integerValue]) {
        case ImgToVideoWaitAnimationZoomIn:
            playBaseFrame = CGRectMake(0, 0, param.frameSize.width, param.frameSize.height);
            playToFrame = CGRectMake(-param.frameSize.width * param.zoomRate / 2, -param.frameSize.height * param.zoomRate / 2, param.frameSize.width * (1 + param.zoomRate), param.frameSize.height * (1 + param.zoomRate));
            break;
        case ImgToVideoWaitAnimationZoomOut:
            playBaseFrame = CGRectMake(-param.frameSize.width * param.zoomRate / 2, -param.frameSize.height * param.zoomRate / 2, param.frameSize.width * (1 + param.zoomRate), param.frameSize.height * (1 + param.zoomRate));
            playToFrame = CGRectMake(0, 0, param.frameSize.width, param.frameSize.height);
            break;
        case ImgToVideoWaitAnimationRightToLeft:
            playBaseFrame = CGRectMake(0, 0, param.frameSize.width * (1 + param.zoomRate), param.frameSize.height * (1 + param.zoomRate));
            playToFrame = CGRectMake(-param.frameSize.width * param.zoomRate, 0, param.frameSize.width * (1 + param.zoomRate), param.frameSize.height * (1 + param.zoomRate));
            break;
        case ImgToVideoWaitAnimationLeftToRight:
            playBaseFrame = CGRectMake(-param.frameSize.width * param.zoomRate, 0, param.frameSize.width * (1 + param.zoomRate), param.frameSize.height * (1 + param.zoomRate));
            playToFrame = CGRectMake(0, 0, param.frameSize.width * (1 + param.zoomRate), param.frameSize.height * (1 + param.zoomRate));
            break;
        case ImgToVideoWaitAnimationTopToButtom:
            playBaseFrame = CGRectMake(0, 0, param.frameSize.width * (1 + param.zoomRate), param.frameSize.height * (1 + param.zoomRate));
            playToFrame = CGRectMake(0, -param.frameSize.height * param.zoomRate, param.frameSize.width * (1 + param.zoomRate), param.frameSize.height * (1 + param.zoomRate));
            break;
        case ImgToVideoWaitAnimationButtomToTop:
            playBaseFrame = CGRectMake(0, -param.frameSize.height * param.zoomRate, param.frameSize.width * (1 + param.zoomRate), param.frameSize.height * (1 + param.zoomRate));
            playToFrame = CGRectMake(0, 0, param.frameSize.width * (1 + param.zoomRate), param.frameSize.height * (1 + param.zoomRate));
            break;
            
        default:
            playBaseFrame = CGRectMake(0, 0, param.frameSize.width, param.frameSize.height);
            playToFrame = CGRectMake(0, 0, param.frameSize.width, param.frameSize.height);
            break;
    }
    
    int i = 0;
    while (1)
    {
        
        if(writerInput.readyForMoreMediaData){
            
            presentTime = CMTimeMake(i * param.showPicSecond, (int)param.frameRate);
            
            if (i >= [imageArray count]) {
                buffer = NULL;
            } else {
                CMTime fadeTime = CMTimeMake(param.showPicSecond, (int)(param.frameRate * param.transitionFrameCount));
                //画面不动
//                buffer = [LXImagesToVideo pixelBufferFromCGImage:[imageArray[i] CGImage] size:param.frameSize];
                
                playToFrame = [LXImagesToVideo playToFrameWithAnimation:(ImgToVideoPlayAnimationType)[playAnimationArray[i] integerValue] param:param];
                
                //播放动画
                for (int j = 0; j < framesToWaitBeforeTransition; j++) {
                    
                    if ([playAnimationArray[i] integerValue] <= 1) {//放大缩小效果
                        buffer = [LXImagesToVideo playScaleInFromImage:[imageArray[i] CGImage]
                                                             baseFrame:playBaseFrame
                                                               toFrame:playToFrame
                                                                   ctm:j
                                                                 param:param];
                                  
                    }
                    else {
                        buffer = [LXImagesToVideo playMoveFromImage:[imageArray[i] CGImage]
                                                          baseFrame:playBaseFrame
                                                            toFrame:playToFrame
                                                                ctm:j
                                                              param:param];
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
                if (param.transitionShouldAnimate && i + 1 < imageArray.count) {
                    
                    CMTime fadeTime = CMTimeMake(param.showPicSecond, (int)(param.frameRate * param.transitionFrameCount));
                    
                    crossBaseFrame = playToFrame;
                    
                    switch ([playAnimationArray[i+1] integerValue]) {
                        case 0:
                            crossToFrame = CGRectMake(0, 0, param.frameSize.width, param.frameSize.height);
                            break;
                        case 1:
                            crossToFrame = CGRectMake(-param.frameSize.width * param.zoomRate / 2, -param.frameSize.height * param.zoomRate / 2, param.frameSize.width * (1 + param.zoomRate), param.frameSize.height * (1 + param.zoomRate));
                            break;
                        case 2:
                            crossToFrame = CGRectMake(0, 0, param.frameSize.width * (1 + param.zoomRate), param.frameSize.height * (1 + param.zoomRate));
                            break;
                        case 3:
                            crossToFrame = CGRectMake(-param.frameSize.width * param.zoomRate, 0, param.frameSize.width * (1 + param.zoomRate), param.frameSize.height * (1 + param.zoomRate));
                            break;
                        case 4:
                            crossToFrame = CGRectMake(0, 0, param.frameSize.width * (1 + param.zoomRate), param.frameSize.height * (1 + param.zoomRate));
                            break;
                        case 5:
                            crossToFrame = CGRectMake(0, -param.frameSize.height * param.zoomRate, param.frameSize.width * (1 + param.zoomRate), param.frameSize.height * (1 + param.zoomRate));
                            break;
                            
                        default:
                            crossToFrame = CGRectMake(0, 0, param.frameSize.width, param.frameSize.height);
                            break;
                    }

                    //转场动画
                    for (double j = 0; j < param.crossTransition; j++) {
                        if ([crossAnimationArray[i] integerValue] == 0) {
                            buffer = [LXImagesToVideo crossFadeImage:[imageArray[i] CGImage]
                                                             toImage:[imageArray[i + 1] CGImage]
                                                           baseFrame:crossBaseFrame
                                                             toframe:crossToFrame
                                                                 ctm:j
                                                               param:param];
                        }
                        else if ([crossAnimationArray[i] integerValue] == 1) {
                            buffer = [LXImagesToVideo crossLeftToRightFromImage:[imageArray[i] CGImage]
                                                                        toImage:[imageArray[i+1] CGImage]
                                                                      baseFrame:crossBaseFrame
                                                                        toframe:crossToFrame
                                                                            ctm:j
                                                                          param:param];
                        }
                        else if ([crossAnimationArray[i] integerValue] == 2) {
                            buffer = [LXImagesToVideo crossLeftToRightFromImage:[imageArray[i] CGImage]
                                                                        toImage:[imageArray[i+1] CGImage]
                                                                      baseFrame:crossBaseFrame
                                                                        toframe:crossToFrame
                                                                            ctm:j
                                                                          param:param];

                        }
                        else if ([crossAnimationArray[i] integerValue] == 3) {
                            buffer = [LXImagesToVideo crossZoomInImage:[imageArray[i] CGImage]
                                                               toImage:[imageArray[i + 1] CGImage]
                                                             baseFrame:crossBaseFrame
                                                               toframe:crossToFrame
                                                                  zoom:j
                                                                 param:param];

                        }
                        else if ([crossAnimationArray[i] integerValue] == 4) {
                            buffer = [LXImagesToVideo crossZoomOutImage:[imageArray[i] CGImage]
                                                                toImage:[imageArray[i + 1] CGImage]
                                                              baseFrame:crossBaseFrame
                                                                toframe:crossToFrame
                                                                   zoom:j
                                                                  param:param];
                        }
                        else if ([crossAnimationArray[i] integerValue] == 5) {
                            buffer = [LXImagesToVideo crossTopRotateFromImage:[imageArray[i] CGImage]
                                                                      toImage:[imageArray[i + 1] CGImage]
                                                                    baseFrame:crossBaseFrame
                                                                      toframe:crossToFrame
                                                                          ctm:j
                                                                        param:param];
                        }
                        else {
                            buffer = [LXImagesToVideo crossFadeImage:[imageArray[i] CGImage]
                                                             toImage:[imageArray[i + 1] CGImage]
                                                           baseFrame:crossBaseFrame
                                                             toframe:crossToFrame
                                                                 ctm:j
                                                               param:param];
                        }
                        
                        playBaseFrame = crossToFrame;

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

#pragma mark - Private Method

+ (CGRect)playToFrameWithAnimation:(ImgToVideoPlayAnimationType)type
                             param:(LXVideoParameter *)param
{
    CGRect playToFrame;
    switch (type) {
        case ImgToVideoWaitAnimationZoomIn:
            playToFrame = CGRectMake(-param.frameSize.width * param.zoomRate / 2, -param.frameSize.height * param.zoomRate / 2, param.frameSize.width * (1 + param.zoomRate), param.frameSize.height * (1 + param.zoomRate));
            break;
        case ImgToVideoWaitAnimationZoomOut:
            playToFrame = CGRectMake(0, 0, param.frameSize.width, param.frameSize.height);
            break;
        case ImgToVideoWaitAnimationRightToLeft:
            playToFrame = CGRectMake(-param.frameSize.width * param.zoomRate, 0, param.frameSize.width * (1 + param.zoomRate), param.frameSize.height * (1 + param.zoomRate));
            break;
        case ImgToVideoWaitAnimationLeftToRight:
            playToFrame = CGRectMake(0, 0, param.frameSize.width * (1 + param.zoomRate), param.frameSize.height * (1 + param.zoomRate));
            break;
        case ImgToVideoWaitAnimationTopToButtom:
            playToFrame = CGRectMake(0, -param.frameSize.height * param.zoomRate, param.frameSize.width * (1 + param.zoomRate), param.frameSize.height * (1 + param.zoomRate));
            break;
        case ImgToVideoWaitAnimationButtomToTop:
            playToFrame = CGRectMake(0, 0, param.frameSize.width * (1 + param.zoomRate), param.frameSize.height * (1 + param.zoomRate));
            break;
        default:
            break;
    }
    return playToFrame;
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
              withInput:(AVAssetWriterInput*)writerInput {
    while (!writerInput.readyForMoreMediaData) {
        usleep(1);
    }
    
    return [adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
}

#pragma mark - play Animation

+ (CVPixelBufferRef)playScaleInFromImage:(CGImageRef)baseImage
                               baseFrame:(CGRect)baseFrame
                                 toFrame:(CGRect)toFrame
                                     ctm:(NSInteger)ctm
                                   param:(LXVideoParameter *)param
{
    NSDictionary *options = @{(id)kCVPixelBufferCGImageCompatibilityKey: @YES,
                              (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES};
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, param.frameSize.width,
                                          param.frameSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, param.frameSize.width,
                                                 param.frameSize.height, 8, 4*param.frameSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    NSInteger FramesToWaitBeforeTransition = param.transitionFrameCount - param.crossTransition;
    
    CGRect drawRect;
    if (baseFrame.size.width > toFrame.size.width) { //缩小效果
        drawRect = CGRectMake((baseFrame.origin.x - toFrame.origin.x) / FramesToWaitBeforeTransition * (FramesToWaitBeforeTransition - ctm),
                              (baseFrame.origin.y - toFrame.origin.y) / FramesToWaitBeforeTransition * (FramesToWaitBeforeTransition - ctm),
                              (baseFrame.size.width - toFrame.size.width) / FramesToWaitBeforeTransition * (FramesToWaitBeforeTransition - ctm) + toFrame.size.width,
                              (baseFrame.size.height - toFrame.size.height) / FramesToWaitBeforeTransition * (FramesToWaitBeforeTransition - ctm) + toFrame.size.height);
    }
    else { //放大
        drawRect = CGRectMake((toFrame.origin.x - baseFrame.origin.x) / FramesToWaitBeforeTransition * ctm,
                              (toFrame.origin.y - baseFrame.origin.y) / FramesToWaitBeforeTransition * ctm,
                              (toFrame.size.width - baseFrame.size.width) / FramesToWaitBeforeTransition * ctm + baseFrame.size.width,
                              (toFrame.size.height - baseFrame.size.height) / FramesToWaitBeforeTransition * ctm + baseFrame.size.height);
    }
    
    CGContextBeginTransparencyLayer(context, nil);
    CGContextDrawImage(context, drawRect, baseImage);
    CGContextEndTransparencyLayer(context);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

+ (CVPixelBufferRef)playMoveFromImage:(CGImageRef)baseImage
                            baseFrame:(CGRect)baseFrame
                              toFrame:(CGRect)toFrame
                                  ctm:(NSInteger)ctm
                                param:(LXVideoParameter *)param

{
    NSDictionary *options = @{(id)kCVPixelBufferCGImageCompatibilityKey: @YES,
                              (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES};
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, param.frameSize.width,
                                          param.frameSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, param.frameSize.width,
                                                 param.frameSize.height, 8, 4 * param.frameSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    NSInteger framesToWaitBeforeTransition = param.transitionFrameCount - param.crossTransition;
    
    CGRect drawRectBase = baseFrame;
    
    CGContextBeginTransparencyLayer(context, nil);
    CGContextTranslateCTM(context, (toFrame.origin.x - baseFrame.origin.x) / framesToWaitBeforeTransition * ctm, (toFrame.origin.y - baseFrame.origin.y) /framesToWaitBeforeTransition * ctm);
    CGContextDrawImage(context, drawRectBase, baseImage);
    CGContextEndTransparencyLayer(context);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

+ (CVPixelBufferRef)playTopToBottomFromImage:(CGImageRef)baseImage
                                   baseFrame:(CGRect)baseFrame
                                     toFrame:(CGRect)toFrame
                                         ctm:(NSInteger)ctm
                                       param:(LXVideoParameter *)param

{
    NSDictionary *options = @{(id)kCVPixelBufferCGImageCompatibilityKey: @YES,
                              (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES};
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, param.frameSize.width,
                                          param.frameSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, param.frameSize.width,
                                                 param.frameSize.height, 8, 4 * param.frameSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    NSInteger framesToWaitBeforeTransition = param.transitionFrameCount - param.crossTransition;
    
    CGRect drawRectBase = baseFrame;
    
    CGContextBeginTransparencyLayer(context, nil);
    CGContextTranslateCTM(context, (toFrame.origin.x - baseFrame.origin.x) / framesToWaitBeforeTransition * ctm, (toFrame.origin.y - baseFrame.origin.y) / framesToWaitBeforeTransition * ctm);
    
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
                         baseFrame:(CGRect)baseFrame
                           toframe:(CGRect)toFrame
                               ctm:(NSInteger)ctm
                             param:(LXVideoParameter *)param
{
    NSDictionary *options = @{(id)kCVPixelBufferCGImageCompatibilityKey: @YES,
                              (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES};
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, param.frameSize.width,
                                          param.frameSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, param.frameSize.width,
                                                 param.frameSize.height, 8, 4 * param.frameSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    CGRect drawRectBase = baseFrame;
    
    CGRect drawRectFadeIn = toFrame;
    
    CGContextDrawImage(context, drawRectBase, baseImage);
   
    CGContextBeginTransparencyLayer(context, nil);
    CGContextSetAlpha(context, (CGFloat)ctm/param.crossTransition);
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
                                    baseFrame:(CGRect)baseFrame
                                      toframe:(CGRect)toFrame
                                          ctm:(NSInteger)ctm
                                        param:(LXVideoParameter *)param
{
    NSDictionary *options = @{(id)kCVPixelBufferCGImageCompatibilityKey: @YES,
                              (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES};
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, param.frameSize.width,
                                          param.frameSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, param.frameSize.width,
                                                 param.frameSize.height, 8, 4 * param.frameSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    CGRect drawRectBase = baseFrame;
    
    CGRect drawRectFadeIn = CGRectMake(-toFrame.size.width,
                                       toFrame.origin.y,
                                       toFrame.size.width,
                                       toFrame.size.height);
    
    CGContextBeginTransparencyLayer(context, nil);
    CGContextTranslateCTM(context, (toFrame.size.width + toFrame.origin.x) / param.crossTransition * ctm, 0);
    
    CGContextDrawImage(context, drawRectBase, baseImage);
    
    CGContextDrawImage(context, drawRectFadeIn, fadeInImage);
    CGContextEndTransparencyLayer(context);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

//缩小
+ (CVPixelBufferRef)crossZoomOutImage:(CGImageRef)baseImage
                              toImage:(CGImageRef)fadeInImage
                            baseFrame:(CGRect)baseFrame
                              toframe:(CGRect)toFrame
                                 zoom:(NSInteger)zoom //缩放系数 帧率
                                param:(LXVideoParameter *)param
{
    NSDictionary *options = @{(id)kCVPixelBufferCGImageCompatibilityKey: @YES,
                              (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES};
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, param.frameSize.width,
                                          param.frameSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, param.frameSize.width,
                                                 param.frameSize.height, 8, 4 * param.frameSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    CGRect drawRectBase = CGRectMake(baseFrame.size.width / 2 * ((CGFloat)zoom / param.crossTransition),
                                     baseFrame.size.height / 2 * ((CGFloat)zoom / param.crossTransition),
                                     baseFrame.size.width * ((CGFloat)(param.crossTransition - zoom) / param.crossTransition),
                                     baseFrame.size.height * ((CGFloat)(param.crossTransition - zoom) / param.crossTransition));
    
    CGRect drawRectFadeIn = toFrame;
    
    CGContextDrawImage(context, drawRectFadeIn, fadeInImage);
    
    CGContextBeginTransparencyLayer(context, nil);
    CGContextDrawImage(context, drawRectBase, baseImage);
    CGContextEndTransparencyLayer(context);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

//放大
+ (CVPixelBufferRef)crossZoomInImage:(CGImageRef)baseImage
                             toImage:(CGImageRef)fadeInImage
                           baseFrame:(CGRect)baseFrame
                             toframe:(CGRect)toFrame
                                zoom:(NSInteger)zoom //缩放系数 帧率
                               param:(LXVideoParameter *)param
{
    NSDictionary *options = @{(id)kCVPixelBufferCGImageCompatibilityKey: @YES,
                              (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES};
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, param.frameSize.width,
                                          param.frameSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, param.frameSize.width,
                                                 param.frameSize.height, 8, 4 * param.frameSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    CGRect drawRectBase = baseFrame;
    
    CGRect drawRectFadeIn = CGRectMake(baseFrame.size.width / 2 * ((CGFloat)(param.crossTransition - zoom) / param.crossTransition),
                                       baseFrame.size.height / 2 * ((CGFloat)(param.crossTransition - zoom) / param.crossTransition),
                                       baseFrame.size.width * ((CGFloat)zoom / param.crossTransition),
                                       baseFrame.size.height * ((CGFloat)zoom / param.crossTransition));;
    
    CGContextDrawImage(context, drawRectBase, baseImage);

    CGContextBeginTransparencyLayer(context, nil);
    CGContextDrawImage(context, drawRectFadeIn, fadeInImage);
    CGContextEndTransparencyLayer(context);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

+ (CVPixelBufferRef)crossTopRotateFromImage:(CGImageRef)baseImage
                                    toImage:(CGImageRef)fadeInImage
                                  baseFrame:(CGRect)baseFrame
                                    toframe:(CGRect)toFrame
                                        ctm:(NSInteger)ctm
                                      param:(LXVideoParameter *)param
{
    NSDictionary *options = @{(id)kCVPixelBufferCGImageCompatibilityKey: @YES,
                              (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES};
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, param.frameSize.width,
                                          param.frameSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, param.frameSize.width,
                                                 param.frameSize.height, 8, 4 * param.frameSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    CGRect drawRectBase = baseFrame;
    CGRect drawRectFadeIn = CGRectMake(-toFrame.size.width/2, -toFrame.size.height, toFrame.size.width, toFrame.size.height);
    
    CGContextDrawImage(context, drawRectBase, baseImage);
    
    
    CGContextTranslateCTM(context, param.frameSize.width/2, param.frameSize.height); //平移坐标系 设置旋转的中心点
    CGContextRotateCTM(context, (180 * M_PI / 180));

    CGContextBeginTransparencyLayer(context, nil);
    
    CGContextRotateCTM(context, (-180 * M_PI / 180) * ((CGFloat)ctm / param.crossTransition));
    
    CGContextDrawImage(context, drawRectFadeIn, fadeInImage);
    CGContextEndTransparencyLayer(context);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}


@end
