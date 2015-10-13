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
/**
 *  数据源模式，根据datasource获取图片数据，与itemList不兼容
 */
@property (nonatomic, assign) id<PhotoViewerDatasurce> datasource;
/**
 *  列表数据模式，直接在itemList中传入数据，与datasource不兼容
 */
@property (nonatomic, strong) NSArray *itemList;
@property (nonatomic, assign) BOOL enableSaveImage;
+(instancetype)ViewerInWindow;

/**
 *  设置PhotoItem列表以及起始显示的pageIndex，这个方法会自动展示出PhotoViewer
 *
 *  @param itemList PhotoItem的列表
 *  @param index    起始展示的pageIndex
 */
-(void)setItemList:(NSArray *)itemList WithIndex:(NSInteger)index;
@end
