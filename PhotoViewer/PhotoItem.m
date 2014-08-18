//
//  PhotoItem.m
//  PhotoViewer
//
//  Created by xzysun on 14-8-15.
//  Copyright (c) 2014年 AnyApps. All rights reserved.
//

#import "PhotoItem.h"
#import "SDWebImageDecoder.h"
#import "SDWebImageManager.h"
#import "SDWebImageOperation.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface PhotoItem ()
{
    BOOL _loadingInProgress;
    id <SDWebImageOperation> _webImageOperation;
}
@property (nonatomic, strong) UIImage *underlyingImage;
@end

@implementation PhotoItem

+(PhotoItem *)photoWithImage:(UIImage *)image
{
    return [[PhotoItem alloc] initWithImage:image];
}

+(PhotoItem *)photoWithURL:(NSURL *)url
{
    return [[PhotoItem alloc] initWithURL:url];
}

-(id)initWithImage:(UIImage *)image
{
    if (self = [super init]) {
        _image = image;
    }
    return self;
}

-(id)initWithURL:(NSURL *)url
{
    if (self = [super init]) {
        _photoURL = [url copy];
    }
    return self;
}

-(UIImage *)underlyingImage
{
    return _underlyingImage;
}

- (void)loadUnderlyingImageAndNotify {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    if (_loadingInProgress) return;
    _loadingInProgress = YES;
    @try {
        if (self.underlyingImage) {
            [self imageLoadingComplete];
        } else {
            [self performLoadUnderlyingImageAndNotify];
        }
    }
    @catch (NSException *exception) {
        self.underlyingImage = nil;
        _loadingInProgress = NO;
        [self imageLoadingComplete];
    }
    @finally {
    }
}

- (void)performLoadUnderlyingImageAndNotify
{
    if (_image) {//传入的是图片对象，直接使用
        self.underlyingImage = _image;
        [self imageLoadingComplete];
    } else if (_photoURL) {//传入的是图片，进行下载
        if ([[[_photoURL scheme] lowercaseString] isEqualToString:@"assets-library"]) {
            // Load from asset library async
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @autoreleasepool {
                    @try {
                        ALAssetsLibrary *assetslibrary = [[ALAssetsLibrary alloc] init];
                        [assetslibrary assetForURL:_photoURL
                                       resultBlock:^(ALAsset *asset){
                                           ALAssetRepresentation *rep = [asset defaultRepresentation];
                                           CGImageRef iref = [rep fullScreenImage];
                                           if (iref) {
                                               self.underlyingImage = [UIImage imageWithCGImage:iref];
                                           }
                                           [self performSelectorOnMainThread:@selector(imageLoadingComplete) withObject:nil waitUntilDone:NO];
                                       }
                                      failureBlock:^(NSError *error) {
                                          self.underlyingImage = nil;
                                          NSLog(@"Photo from asset library error: %@",error);
                                          [self performSelectorOnMainThread:@selector(imageLoadingComplete) withObject:nil waitUntilDone:NO];
                                      }];
                    } @catch (NSException *e) {
                        NSLog(@"Photo from asset library error: %@", e);
                        [self performSelectorOnMainThread:@selector(imageLoadingComplete) withObject:nil waitUntilDone:NO];
                    }
                }
            });
        } else if ([_photoURL isFileReferenceURL]) {
            // Load from local file async
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @autoreleasepool {
                    @try {
                        self.underlyingImage = [UIImage imageWithContentsOfFile:_photoURL.path];
                        if (!_underlyingImage) {
                            NSLog(@"Error loading photo from path: %@", _photoURL.path);
                        }
                    } @finally {
                        [self performSelectorOnMainThread:@selector(imageLoadingComplete) withObject:nil waitUntilDone:NO];
                    }
                }
            });
            
        } else {
            // Load async from web (using SDWebImage)
            @try {
                SDWebImageManager *manager = [SDWebImageManager sharedManager];
                _webImageOperation = [manager downloadImageWithURL:_photoURL options:SDWebImageProgressiveDownload progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                    if (expectedSize > 0) {
                        float progress = receivedSize / (float)expectedSize;
                        NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithFloat:progress], @"progress", self, @"photo", nil];
                        [[NSNotificationCenter defaultCenter] postNotificationName:PHOTO_PROGRESS_NOTIFICATION object:dict];
                    }
                } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                    if (error) {
                        NSLog(@"SDWebImage failed to download image: %@", error);
                    }
                    _webImageOperation = nil;
                    self.underlyingImage = image;
                    [self imageLoadingComplete];
                }];
            } @catch (NSException *e) {
                NSLog(@"Photo from web: %@", e);
                _webImageOperation = nil;
                [self imageLoadingComplete];
            }
            
        }
        
    } else {
        @throw [NSException exceptionWithName:@"数据源错误" reason:@"没有设置图片的数据来源" userInfo:nil];
    }
}

- (void)imageLoadingComplete {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    // Complete so notify
    _loadingInProgress = NO;
    // Notify on next run loop
    [self performSelector:@selector(postCompleteNotification) withObject:nil afterDelay:0];
}

- (void)postCompleteNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:PHOTO_LOADING_DID_END_NOTIFICATION object:self];
}

- (void)cancelAnyLoading {
    if (_webImageOperation) {
        [_webImageOperation cancel];
        _loadingInProgress = NO;
    }
}
@end
