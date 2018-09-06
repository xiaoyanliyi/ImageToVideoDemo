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
    ImgToVideoTransitionAnimationFade = 0,              //淡入淡出
    ImgToVideoTransitionAnimationLeftToRight = 1,       //从左到右移入
    ImgToVideoTransitionAnimationRightToLeft = 2,       //从右到左移入
    ImgToVideoTransitionAnimationZoomIn = 3,            //放大
    ImgToVideoTransitionAnimationZoomOut = 4,           //缩小
    ImgToVideoTransitionAnimationTopRotate = 5          //顶部旋转

} ImgToVideoTransitionAnimationType;

typedef enum {
    //播放动画
    ImgToVideoWaitAnimationZoomIn = 0,                  //放大
    ImgToVideoWaitAnimationZoomOut = 1,                 //缩小
    ImgToVideoWaitAnimationRightToLeft = 2,             //从右至左缓慢移动
    ImgToVideoWaitAnimationLeftToRight = 3,             //从左至右缓慢移动
    ImgToVideoWaitAnimationTopToButtom = 4,             //从上至下缓慢移动
    ImgToVideoWaitAnimationButtomToTop = 5              //从下至上缓慢移动

} ImgToVideoPlayAnimationType;


typedef void(^SuccessBlock)(BOOL success);

@interface LXVideoParameter : NSObject

@property (nonatomic, assign) NSInteger showPicSecond;              //每张图片播放时间 默认2秒
@property (nonatomic, assign) NSInteger frameRate;                  //1
@property (nonatomic, assign) NSInteger transitionFrameCount;       //每秒帧数 默认60
@property (nonatomic, assign) NSInteger crossTransition;            //转场动画帧数 默认20
@property (nonatomic, assign) BOOL transitionShouldAnimate;         //是否显示转场动画
@property (nonatomic, assign) CGSize frameSize;
@property (nonatomic, copy  ) NSString *videoPathStr;
@property (nonatomic, assign) CGFloat zoomRate;                     //放大、缩小系数 默认0.04

@end

@interface LXImagesToVideo : NSObject

+ (void)writeImageAsMovie:(NSArray *)imageArray
            playAnimation:(NSArray *)playAnimationArray
           crossAnimation:(NSArray *)crossAnimationArray
           videoParamater:(LXVideoParameter *)param
        withCallbackBlock:(SuccessBlock)callbackBlock;

@end
