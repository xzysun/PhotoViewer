//
//  PhotoPage.h
//  PhotoViewer
//
//  Created by xzysun on 14-8-15.
//  Copyright (c) 2014年 AnyApps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoItem.h"

@protocol PhotoPageDelegate <NSObject>

-(void)photoPageSingleTapped;

@end

@interface PhotoPage : UIScrollView
{
    
}
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) PhotoItem *item;
@property (nonatomic, assign) BOOL zoomPhotosToFill;
@property (nonatomic, strong, readonly) UIImage *currentImage;
@property (nonatomic, assign) id<PhotoPageDelegate> photoDelegate;
@end
