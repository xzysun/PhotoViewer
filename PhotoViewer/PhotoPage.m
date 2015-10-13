//
//  PhotoPage.m
//  PhotoViewer
//
//  Created by xzysun on 14-8-15.
//  Copyright (c) 2014年 AnyApps. All rights reserved.
//

#import "PhotoPage.h"
#import "DACircularProgressView.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "SDWebImageManager.h"

//#define ENABLE_DEBUG_LOG

#ifdef ENABLE_DEBUG_LOG
#define DebugLog(...) NSLog(__VA_ARGS__);
#else
#define DebugLog(...);
#endif

@interface PhotoPage () <UIScrollViewDelegate>
{
    DACircularProgressView *_loadingIndicator;
    UIImageView *_photoImageView;
    UIImageView *_loadingError;
}
@property (nonatomic, strong) id<SDWebImageOperation> operation;
@end

@implementation PhotoPage

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self initView];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.operation) {
        [self.operation cancel];
        self.operation = nil;
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void)initView
{
    _index = NSIntegerMax;
    self.zoomPhotosToFill = NO;
    // Setup
    self.backgroundColor = [UIColor clearColor];
    self.delegate = self;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.decelerationRate = UIScrollViewDecelerationRateFast;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    // Image view
    _photoImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _photoImageView.contentMode = UIViewContentModeCenter;
    _photoImageView.backgroundColor = [UIColor clearColor];
    [self addSubview:_photoImageView];
    // Loading indicator
    _loadingIndicator = [[DACircularProgressView alloc] initWithFrame:CGRectMake(140.0f, 30.0f, 40.0f, 40.0f)];
    _loadingIndicator.userInteractionEnabled = NO;
    _loadingIndicator.thicknessRatio = 0.1;
    _loadingIndicator.roundedCorners = NO;
    _loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
    UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    [self addSubview:_loadingIndicator];
}

#pragma mark - Image
- (void)setItem:(PhotoItem *)item
{
    // Cancel any loading on old photo
    if (self.operation) {
        //原来有图片，尝试停止加载
        [self.operation cancel];
        self.operation = nil;
    }
    _item = item;
    [self loadImageForItem];
}

-(void)loadImageForItem
{
    __weak typeof(self) weakSelf = self;
    if (self.item.image) {//传入的是图片对象，直接使用
        [self displayImage:self.item.image];
    } else if (self.item.photoURL) {//传入的是图片，进行下载
        if ([[[self.item.photoURL scheme] lowercaseString] isEqualToString:@"assets-library"]) {
            // Load from asset library async
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @autoreleasepool {
                    @try {
                        ALAssetsLibrary *assetslibrary = [[ALAssetsLibrary alloc] init];
                        [assetslibrary assetForURL:weakSelf.item.photoURL
                                       resultBlock:^(ALAsset *asset){
                                           ALAssetRepresentation *rep = [asset defaultRepresentation];
                                           CGImageRef iref = [rep fullScreenImage];
                                           if (iref) {
                                               //加载到图片
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   [weakSelf displayImage:[UIImage imageWithCGImage:iref]];
                                               });
                                           }
                                       }
                                      failureBlock:^(NSError *error) {
                                          DebugLog(@"Photo from asset library error: %@",error);
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              [weakSelf displayImageFailure];
                                          });
                                      }];
                    } @catch (NSException *e) {
                        DebugLog(@"Photo from asset library error: %@", e);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf displayImageFailure];
                        });
                    }
                }
            });
        } else if ([self.item.photoURL isFileReferenceURL]) {
            // Load from local file async
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @autoreleasepool {
                    @try {
                        UIImage *fileImage = [UIImage imageWithContentsOfFile:weakSelf.item.photoURL.path];
                        if (!fileImage) {
                            DebugLog(@"Error loading photo from path: %@", weakSelf.item.photoURL.path);
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [weakSelf displayImageFailure];
                            });
                        } else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [weakSelf displayImage:fileImage];
                            });
                        }
                    } @catch (NSException *e) {
                         DebugLog(@"Error loading photo from path: %@", e);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf displayImageFailure];
                        });
                    }
                }
            });
            
        } else {
            // Load async from web (using SDWebImage)
            _photoImageView.frame = self.bounds;
            self.operation = [[SDWebImageManager sharedManager] downloadImageWithURL:self.item.photoURL options:SDWebImageRetryFailed|SDWebImageProgressiveDownload progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                //更新百分比
                CGFloat progress = receivedSize / (float)expectedSize;
                dispatch_async(dispatch_get_main_queue(), ^{
                    _loadingIndicator.progress = MAX(MIN(1, progress), 0);
                });
            } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                if (error) {
                    DebugLog(@"Error loading photo from web:%@", error);
                    weakSelf.operation = nil;
                    [weakSelf displayImageFailure];
                } else {
                    _photoImageView.image = image;
                    _photoImageView.contentMode = UIViewContentModeScaleAspectFit;
                    if (finished) {
                        [weakSelf displayImage:image];
                        weakSelf.operation = nil;
                    }
                }
            }];
        }
    } else {
//        @throw [NSException exceptionWithName:@"数据源错误" reason:@"没有设置图片的数据来源" userInfo:nil];
        [self displayImageFailure];
    }
}

// Get and display image
- (void)displayImage:(UIImage *)image
{
    // Reset
    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.zoomScale = 1;
    self.contentSize = CGSizeMake(0, 0);
    
    // Get image from browser as it handles ordering of fetching
    if (image) {
        
        // Hide indicator
        [self hideLoadingIndicator];
        
        // Set image
        _photoImageView.image = image;
        _photoImageView.hidden = NO;
        
        // Setup photo frame
        CGRect photoImageViewFrame;
        photoImageViewFrame.origin = CGPointZero;
        photoImageViewFrame.size = image.size;
        _photoImageView.frame = photoImageViewFrame;
        self.contentSize = photoImageViewFrame.size;
        
        // Set zoom to minimum zoom
        [self setMaxMinZoomScalesForCurrentBounds];
        
        //center image
        if (self.zoomScale == self.minimumZoomScale) {
            _photoImageView.center = CGPointMake(CGRectGetWidth(self.frame)/2.0, CGRectGetHeight(self.frame)/2.0);
        }
//        _photoImageView.center = self.center;
    } else {
        
        // Failed no image
        [self displayImageFailure];
        
    }
    [self setNeedsLayout];
}

// Image failed so just show black!
- (void)displayImageFailure
{
    [self hideLoadingIndicator];
    _photoImageView.image = nil;
    if (!_loadingError) {
        _loadingError = [UIImageView new];
        _loadingError.image = [UIImage imageNamed:@"ImageError.png"];
        _loadingError.userInteractionEnabled = NO;
		_loadingError.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        [_loadingError sizeToFit];
        [self addSubview:_loadingError];
    }
    _loadingError.frame = CGRectMake(floorf((self.bounds.size.width - _loadingError.frame.size.width) / 2.),
                                     floorf((self.bounds.size.height - _loadingError.frame.size.height) / 2),
                                     _loadingError.frame.size.width,
                                     _loadingError.frame.size.height);
}

-(UIImage *)currentImage
{
    return _photoImageView.image;
}

#pragma mark - Zoom init
- (CGFloat)initialZoomScaleWithMinScale
{
    CGFloat zoomScale = self.minimumZoomScale;
    if (_photoImageView && self.zoomPhotosToFill) {
        // Zoom image to fill if the aspect ratios are fairly similar
        CGSize boundsSize = self.bounds.size;
        CGSize imageSize = _photoImageView.image.size;
        CGFloat boundsAR = boundsSize.width / boundsSize.height;
        CGFloat imageAR = imageSize.width / imageSize.height;
        CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
        CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
        // Zooms standard portrait images on a 3.5in screen but not on a 4in screen.
        if (ABS(boundsAR - imageAR) < 0.17) {
            zoomScale = MAX(xScale, yScale);
            // Ensure we don't zoom in or out too far, just in case
            zoomScale = MIN(MAX(self.minimumZoomScale, zoomScale), self.maximumZoomScale);
        }
    }
    return zoomScale;
}

- (void)setMaxMinZoomScalesForCurrentBounds
{
	
	// Reset
	self.maximumZoomScale = 1;
	self.minimumZoomScale = 1;
	self.zoomScale = 1;
	
	// Bail if no image
	if (_photoImageView.image == nil) return;
    
	// Reset position
	_photoImageView.frame = CGRectMake(0, 0, _photoImageView.frame.size.width, _photoImageView.frame.size.height);
	
	// Sizes
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = _photoImageView.image.size;
    
    // Calculate Min
    CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
    CGFloat minScale = MIN(xScale, yScale);                 // use minimum of these to allow the image to become fully visible
    
    // Calculate Max
	CGFloat maxScale = 3;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Let them go a bit bigger on a bigger screen!
        maxScale = 4;
    }
    
    // Image is smaller than screen so no zooming!
	if (xScale >= 1 && yScale >= 1) {
		minScale = 1.0;
	}
	
	// Set min/max zoom
	self.maximumZoomScale = maxScale;
	self.minimumZoomScale = minScale;
    
    // Initial zoom
    self.zoomScale = [self initialZoomScaleWithMinScale];
    
    // If we're zooming to fill then centralise
    if (self.zoomScale != minScale) {
        // Centralise
        self.contentOffset = CGPointMake((imageSize.width * self.zoomScale - boundsSize.width) / 2.0,
                                         (imageSize.height * self.zoomScale - boundsSize.height) / 2.0);
        // Disable scrolling initially until the first pinch to fix issues with swiping on an initally zoomed in photo
        self.scrollEnabled = NO;
    }
    
    // Layout
	[self setNeedsLayout];
    
}

#pragma mark - Loading Indicator
- (void)hideLoadingIndicator
{
    _loadingIndicator.hidden = YES;
}

- (void)showLoadingIndicator
{
    self.zoomScale = 0;
    self.minimumZoomScale = 0;
    self.maximumZoomScale = 0;
    _loadingIndicator.progress = 0;
    _loadingIndicator.hidden = NO;
}

#pragma mark - Layout

- (void)layoutSubviews
{
	// Position indicators (centre does not seem to work!)
	if (!_loadingIndicator.hidden)
        _loadingIndicator.frame = CGRectMake(floorf((self.bounds.size.width - _loadingIndicator.frame.size.width) / 2.),
                                             floorf((self.bounds.size.height - _loadingIndicator.frame.size.height) / 2),
                                             _loadingIndicator.frame.size.width,
                                             _loadingIndicator.frame.size.height);
	if (_loadingError)
        _loadingError.frame = CGRectMake(floorf((self.bounds.size.width - _loadingError.frame.size.width) / 2.),
                                         floorf((self.bounds.size.height - _loadingError.frame.size.height) / 2),
                                         _loadingError.frame.size.width,
                                         _loadingError.frame.size.height);
    
	// Super
	[super layoutSubviews];
}

-(void)centerImage
{
    CGRect photoFrame = _photoImageView.frame;
    if (photoFrame.size.width > CGRectGetWidth(self.frame)) {
        photoFrame.origin.x = 0.0;
    } else {
        photoFrame.origin.x = (CGRectGetWidth(self.frame) - photoFrame.size.width)/2.0;
    }
    if (photoFrame.size.height > CGRectGetHeight(self.frame)) {
        photoFrame.origin.y = 0.0;
    } else {
        photoFrame.origin.y = (CGRectGetHeight(self.frame) - photoFrame.size.height)/2.0;
    }
    _photoImageView.frame = photoFrame;
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return _photoImageView;
}

-(void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self centerImage];
}

#pragma mark - Touches
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	NSUInteger tapCount = touch.tapCount;
	switch (tapCount) {
		case 1:
			[self handleSingleTap:touch];
			break;
		case 2:
			[self handleDoubleTap:touch];
			break;
		case 3:
			[self handleTripleTap:touch];
			break;
		default:
			break;
	}
//	[[self nextResponder] touchesEnded:touches withEvent:event];
}

- (void)handleSingleTap:(UITouch *)touch
{
    if (_photoDelegate && [_photoDelegate respondsToSelector:@selector(photoPageSingleTapped)]) {
        [self performSelector:@selector(delayPerformer) withObject:nil afterDelay:0.2];
    }
}

-(void)delayPerformer
{
    [_photoDelegate photoPageSingleTapped];
}

- (void)handleDoubleTap:(UITouch *)touch
{
	// Cancel any single tap handling
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	// Zoom
	if (self.zoomScale != self.minimumZoomScale && self.zoomScale != [self initialZoomScaleWithMinScale]) {
		// Zoom out
		[self setZoomScale:self.minimumZoomScale animated:YES];
	} else {
		// Zoom in to twice the size
        CGFloat newZoomScale = ((self.maximumZoomScale + self.minimumZoomScale) / 2);
        CGFloat xsize = self.bounds.size.width / newZoomScale;
        CGFloat ysize = self.bounds.size.height / newZoomScale;
        CGPoint touchPoint = [self convertTouchPoint:touch];
        [self zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
	}
}

- (void)handleTripleTap:(UITouch *)touch
{
	//did nothing
}

-(CGPoint)convertTouchPoint:(UITouch *)touch
{
    //转换触摸相对图片的坐标，如果在图片外围则以最接近的边作为基准
    CGPoint pointForImage = [touch locationInView:_photoImageView];
    pointForImage.x = fmaxf(0.0, pointForImage.x);
    pointForImage.x = fminf(_photoImageView.image.size.width, pointForImage.x);
    pointForImage.y = fmaxf(0.0, pointForImage.y);
    pointForImage.y = fminf(_photoImageView.image.size.height, pointForImage.y);
    return pointForImage;
}
@end
