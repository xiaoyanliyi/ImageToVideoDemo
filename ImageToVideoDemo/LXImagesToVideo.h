//
//  LXImagesToVideo.h
//  ImageToVideoDemo
//
//  Created by lx on 2018/8/17.
//  Copyright © 2018年 lx. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AssetsLibrary/AssetsLibrary.h>


typedef enum {
    //转场动画
    ImgToVideoTransitionAnimationLeftToRight = 0,   //下一张图片从左到右移入
    ImgToVideoTransitionAnimationLeftToRight2,      //本张图片从左到右移出
    ImgToVideoTransitionAnimationRightToLeft,       //下一张图片从右到左移入
    ImgToVideoTransitionAnimationRightToLeft2       //本张图片从右到左移出

} ImgToVideoTransitionAnimationType;

typedef enum {
    //播放动画
    ImgToVideoWaitAnimationZoomIn = 0,              //放大
    ImgToVideoWaitAnimationZoomOut,                 //缩小
    ImgToVideoWaitAnimationRightToLeft,             //图片从右至左缓慢移动
    ImgToVideoWaitAnimationLeftToRight              //图片从左至右缓慢移动

} ImgToVideoWaitAnimationType;


FOUNDATION_EXPORT BOOL const DefaultTransitionShouldAnimate;
FOUNDATION_EXPORT CGSize const DefaultFrameSize;
FOUNDATION_EXPORT NSInteger const DefaultFrameRate;
FOUNDATION_EXPORT NSInteger const TransitionFrameCount;
FOUNDATION_EXPORT NSInteger const FramesToWaitBeforeTransition;


typedef void(^SuccessBlock)(BOOL success);


@interface LXImagesToVideo : NSObject


+ (void)videoFromImages:(NSArray *)images
                 toPath:(NSString *)path
               withSize:(CGSize)size
                withFPS:(int)fps
     animateTransitions:(BOOL)animate
      withCallbackBlock:(SuccessBlock)callbackBlock;

+ (void)videoFromImages:(NSArray *)images
                 toPath:(NSString *)path
                withFPS:(int)fps
     animateTransitions:(BOOL)animate
      withCallbackBlock:(SuccessBlock)callbackBlock;

+ (void)videoFromImages:(NSArray *)images
                 toPath:(NSString *)path
               withSize:(CGSize)size
     animateTransitions:(BOOL)animate
      withCallbackBlock:(SuccessBlock)callbackBlock;

+ (void)videoFromImages:(NSArray *)images
                 toPath:(NSString *)path
     animateTransitions:(BOOL)animate
      withCallbackBlock:(SuccessBlock)callbackBlock;

+ (void)videoFromImages:(NSArray *)images
                 toPath:(NSString *)path
      withCallbackBlock:(SuccessBlock)callbackBlock;


+ (void)saveVideoToPhotosWithImages:(NSArray *)images
                           withSize:(CGSize)size
                            withFPS:(int)fps
                 animateTransitions:(BOOL)animate
                  withCallbackBlock:(SuccessBlock)callbackBlock;

+ (void)saveVideoToPhotosWithImages:(NSArray *)images
                           withSize:(CGSize)size
                 animateTransitions:(BOOL)animate
                  withCallbackBlock:(SuccessBlock)callbackBlock;

+ (void)saveVideoToPhotosWithImages:(NSArray *)images
                            withFPS:(int)fps
                 animateTransitions:(BOOL)animate
                  withCallbackBlock:(SuccessBlock)callbackBlock;

+ (void)saveVideoToPhotosWithImages:(NSArray *)images
                 animateTransitions:(BOOL)animate
                  withCallbackBlock:(SuccessBlock)callbackBlock;

+ (void)saveVideoToPhotosWithImages:(NSArray *)images
                  withCallbackBlock:(SuccessBlock)callbackBlock;


@end
