//
//  PhotoItem.h
//  PhotoViewer
//
//  Created by xzysun on 14-8-15.
//  Copyright (c) 2014年 AnyApps. All rights reserved.
//

#import <Foundation/Foundation.h>
#define PHOTO_LOADING_DID_END_NOTIFICATION @"PhotoLoadingDidEndNotification"
#define PHOTO_PROGRESS_NOTIFICATION @"PhotoProgressNotification"

@interface PhotoItem : NSObject
{
    
}
@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) NSURL *photoURL;

+ (PhotoItem *)photoWithImage:(UIImage *)image;
+ (PhotoItem *)photoWithURL:(NSURL *)url;

- (id)initWithImage:(UIImage *)image;
- (id)initWithURL:(NSURL *)url;

//最终实际显示的照片
- (UIImage *)underlyingImage;
//加载照片并进行通知
- (void)loadUnderlyingImageAndNotify;
//取消加载
- (void)cancelAnyLoading;
@end
