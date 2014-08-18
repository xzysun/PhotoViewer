//
//  PhotoViewer.h
//  PhotoViewer
//
//  Created by xzysun on 14-8-15.
//  Copyright (c) 2014年 AnyApps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoItem.h"

@protocol PhotoViewerDatasurce <NSObject>

-(NSInteger)numbersOfPhotos;
-(PhotoItem *)photoItemForIndex:(NSInteger)index;

@end

@interface PhotoViewer : UIView
{
    
}
@property (nonatomic, readonly) NSInteger currentIndex;
@property (nonatomic, assign) id<PhotoViewerDatasurce> datasource;
+(instancetype)ViewerInWindow;
@end
