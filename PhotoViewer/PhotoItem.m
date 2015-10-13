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
@end
