//
//  LXImagesToVideoManager.h
//  ImageToVideoDemo
//
//  Created by lx on 2018/9/5.
//  Copyright © 2018年 lx. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

typedef void(^LXImageToVideoCallBackBlock)(BOOL success, NSString *videoPath);

@interface LXImagesToVideoManager : NSObject


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
                   onComplete:(LXImageToVideoCallBackBlock)callBackBlock;

@end
