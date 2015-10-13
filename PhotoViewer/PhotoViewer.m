//
//  PhotoViewer.m
//  PhotoViewer
//
//  Created by xzysun on 14-8-15.
//  Copyright (c) 2014年 AnyApps. All rights reserved.
//

#import "PhotoViewer.h"
#import "PhotoPage.h"

//#define ENABLE_DEBUG_LOG

#ifdef ENABLE_DEBUG_LOG
#define DebugLog(...) NSLog(__VA_ARGS__);
#else
#define DebugLog(...);
#endif

#define PADDING 5.0
#define PAGE_CONTROL_HEIGHT 20.0
#define PAGE_CONTROL_BOTTOM_SPACE 80.0


@interface PhotoViewer () <UIScrollViewDelegate, PhotoPageDelegate>
{
    
}
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIPageControl *pageControl;
@property (strong, nonatomic) NSMutableArray *pages;
@property (strong, nonatomic) UIButton *saveButton;
@end


@implementation PhotoViewer

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self initView];
    }
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    [self initView];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

+(instancetype)ViewerInWindow
{
    return [[PhotoViewer alloc] initWithFrame:[UIApplication sharedApplication].keyWindow.frame];
}

-(void)initView
{
    //初始化控件
    self.scrollView = [[UIScrollView alloc] initWithFrame:[self frameForPagingScrollView]];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.scrollView];
    self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.frame)-PAGE_CONTROL_HEIGHT-PAGE_CONTROL_BOTTOM_SPACE, CGRectGetWidth(self.frame), PAGE_CONTROL_HEIGHT)];
    self.pageControl.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
    self.pageControl.hidesForSinglePage = YES;
    self.pageControl.userInteractionEnabled = NO;
    [self addSubview:self.pageControl];
    self.saveButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.frame) - 50.0, CGRectGetMaxY(self.frame)-30.0, 40.0, 20.0)];
    [self.saveButton setTitle:@"保存" forState:UIControlStateNormal];
    self.saveButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin;
    [self.saveButton addTarget:self action:@selector(saveImageButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.saveButton];
    self.backgroundColor = [UIColor blackColor];
    self.enableSaveImage = YES;
}

-(void)setDatasource:(id<PhotoViewerDatasurce>)datasource
{
    _datasource = datasource;
    NSAssert((datasource && [datasource respondsToSelector:@selector(numbersOfPhotos)] && [datasource respondsToSelector:@selector(photoItemForIndex:)]), @"图片浏览器数据源异常");
    [self loadPhotos];
}

-(void)setItemList:(NSArray *)itemList
{
    _itemList = itemList;
    NSAssert(itemList , @"图片浏览器数据源异常");
    [self loadPhotos];
}

-(void)setItemList:(NSArray *)itemList WithIndex:(NSInteger)index
{
    _currentIndex = index;
    self.itemList = itemList;
}

-(void)setEnableSaveImage:(BOOL)enableSaveImage
{
    _enableSaveImage = enableSaveImage;
    self.saveButton.hidden = !enableSaveImage;
}

-(void)loadPhotos
{
    if (_pages) {
        [_pages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        }];
        [_pages removeAllObjects];
    }
    NSInteger count = self.itemList?self.itemList.count:[_datasource numbersOfPhotos];
    if (count == 0) {
        DebugLog(@"没有图片");
        return;
    }
    _pages = [NSMutableArray arrayWithCapacity:count];
    _scrollView.contentSize = CGSizeMake(CGRectGetWidth(_scrollView.frame)*count, CGRectGetHeight(_scrollView.frame));
    _scrollView.contentOffset = CGPointMake(CGRectGetWidth(_scrollView.frame)*_currentIndex, 0);
    _pageControl.numberOfPages = count;
    _pageControl.currentPage = _currentIndex;
    [self loadPageAtIndex:_currentIndex];
    if (count > _currentIndex+1) {
        [self loadPageAtIndex:_currentIndex+1];
    }
    if (_currentIndex>0) {
        [self loadPageAtIndex:_currentIndex-1];
    }
    if (self.superview) {
        [self removeFromSuperview];
    }
    [[UIApplication sharedApplication].keyWindow addSubview:self];
}

-(void)loadPageAtIndex:(NSInteger)index
{
    DebugLog(@"准备绘制照片页面%ld", (long)index);
    for (PhotoPage *page in _pages) {
        if (page.index == index) {
            return;//已经有这个页面了
        }
    }
    CGFloat width = CGRectGetWidth(_scrollView.frame);
    CGFloat height = CGRectGetHeight(_scrollView.frame);
    PhotoPage *page = [[PhotoPage alloc] initWithFrame:CGRectMake(width*index+PADDING, 0, width-PADDING*2, height)];
    [_pages addObject:page];
    [_scrollView addSubview:page];
    PhotoItem *item = self.itemList?[self.itemList objectAtIndex:index]:[_datasource photoItemForIndex:index];
    page.item = item;
    page.index = index;
    page.photoDelegate = self;
}

#pragma mark - Scroll View Delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	
	// Calculate current page
    NSInteger pageCount = self.itemList?self.itemList.count:[_datasource numbersOfPhotos];
    NSInteger index = round(_scrollView.contentOffset.x/CGRectGetWidth(_scrollView.frame));
    if (index < 0) index = 0;
	if (index > pageCount - 1) {
        index = pageCount - 1;
    }
    if (_currentIndex != index) {
        //页码发生了变化
        NSUInteger previousCurrentPage = _currentIndex;
        _currentIndex = index;
        _pageControl.currentPage = index;
        if (previousCurrentPage < index && index+1 < pageCount) {
            //变大了且有下一页
            [self loadPageAtIndex:index+1];
        } else if (previousCurrentPage > index && index > 0) {
            //变小了且有前一页
            [self loadPageAtIndex:index-1];
        }
    }
}

#pragma mark - Photo Page Delagte
-(void)photoPageSingleTapped
{
    DebugLog(@"单击了页面，准备退出");
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        //
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        //
        [_pages removeAllObjects];
        [self removeFromSuperview];
    }];
}

#pragma mark - Save Image Button
-(void)saveImageButtonAction:(id)sender
{
    DebugLog(@"点击了保存");
    PhotoPage *page = [_pages objectAtIndex:_currentIndex];
    UIImage *image = page.currentImage;
    if (image == nil) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误" message:@"图片还在加载，请图片加载完成后再保存" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        [alert show];
    } else {
        [self saveImageToPhotos:image];
    }
}

#pragma mark - private method
- (CGRect)frameForPagingScrollView
{
    CGRect frame = self.bounds;// [[UIScreen mainScreen] bounds];
//    CGRect frame = [UIApplication sharedApplication].keyWindow.bounds;
    frame.origin.x -= PADDING;
    frame.size.width += (2 * PADDING);
    return CGRectIntegral(frame);
}

-(void)saveImageToPhotos:(UIImage *)imageToSave
{
    UIImageWriteToSavedPhotosAlbum(imageToSave, self, @selector(saveImageFinished:Error:ContextInfo:), NULL);
}

-(void)saveImageFinished:(UIImage *)image Error:(NSError *)error ContextInfo:(void *)contextInfo
{
    if (error != nil) {
        NSString *msg = [NSString stringWithFormat:@"保存图片失败,系统返回错误信息:%@", [error localizedDescription]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误" message:msg delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        [alert show];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"保存图片成功，请到系统照片应用中查看" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        [alert show];
    }
}
@end
