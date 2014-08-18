//
//  PhotoViewer.m
//  PhotoViewer
//
//  Created by xzysun on 14-8-15.
//  Copyright (c) 2014年 AnyApps. All rights reserved.
//

#import "PhotoViewer.h"
#import "PhotoPage.h"

#define PADDING 0.0
#define PAGE_CONTROL_HEIGHT 20.0
#define PAGE_CONTROL_BOTTOM_SPACE 80.0


@interface PhotoViewer () <UIScrollViewDelegate, PhotoPageDelegate>
{
    
}
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIPageControl *pageControl;
@property (strong, nonatomic) NSMutableArray *pages;
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
    self.scrollView.backgroundColor = [UIColor blackColor];
    [self addSubview:self.scrollView];
    self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.frame)-PAGE_CONTROL_HEIGHT-PAGE_CONTROL_BOTTOM_SPACE, CGRectGetWidth(self.frame), PAGE_CONTROL_HEIGHT)];
    self.pageControl.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
    self.pageControl.hidesForSinglePage = YES;
    self.pageControl.userInteractionEnabled = NO;
    [self addSubview:self.pageControl];
}

-(void)setDatasource:(id<PhotoViewerDatasurce>)datasource
{
    _datasource = datasource;
    NSAssert((datasource && [datasource respondsToSelector:@selector(numbersOfPhotos)] && [datasource respondsToSelector:@selector(photoItemForIndex:)]), @"图片浏览器数据源异常");
    [self loadPhotos];
}

-(void)loadPhotos
{
    if (_pages) {
        [_pages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        }];
        [_pages removeAllObjects];
    }
    NSInteger count = [_datasource numbersOfPhotos];
    if (count == 0) {
        NSLog(@"没有图片");
        return;
    }
    _pages = [NSMutableArray arrayWithCapacity:count];
    _scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.frame)*count, CGRectGetHeight(self.frame));
    _scrollView.contentOffset = CGPointZero;
    _pageControl.numberOfPages = count;
    _pageControl.currentPage = 0;
    [self loadPageAtIndex:0];
    if (count > 1) {
        [self loadPageAtIndex:1];
    }
    if (self.superview) {
        [self removeFromSuperview];
    }
    [[UIApplication sharedApplication].keyWindow addSubview:self];
}

-(void)loadPageAtIndex:(NSInteger)index
{
    NSLog(@"准备绘制照片页面%i", index);
    CGFloat width = CGRectGetWidth(self.frame);
    CGFloat height = CGRectGetHeight(self.frame);
    PhotoPage *page = [[PhotoPage alloc] initWithFrame:CGRectMake(width*index, 0, width, height)];
    [_pages addObject:page];
    [_scrollView addSubview:page];
    PhotoItem *item = [_datasource photoItemForIndex:index];
    page.item = item;
    page.index = index;
    page.photoDelegate = self;
}

#pragma mark - Scroll View Delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	
	// Calculate current page
//	CGRect visibleBounds = _scrollView.bounds;
//	NSInteger index = (NSInteger)(floorf(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds)));
    NSInteger index = _scrollView.contentOffset.x/CGRectGetWidth(_scrollView.frame);
    if (index < 0) index = 0;
	if (index > [_datasource numbersOfPhotos] - 1) {
        index = [_datasource numbersOfPhotos] - 1;
    }
	NSUInteger previousCurrentPage = _currentIndex;
	_currentIndex = index;
    _pageControl.currentPage = index;
	if (_currentIndex != previousCurrentPage) {
        //页码发生了变化
        if ([_datasource numbersOfPhotos] > _pages.count) {
            //需要加载下一张图
            [self loadPageAtIndex:index+1];
        }
    }
}

#pragma mark - Photo Page Delagte
-(void)photoPageSingleTapped
{
    NSLog(@"单击了页面，准备退出");
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        //
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        //
        [_pages removeAllObjects];
        [self removeFromSuperview];
    }];
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
@end
