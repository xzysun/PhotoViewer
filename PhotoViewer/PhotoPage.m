//
//  PhotoPage.m
//  PhotoViewer
//
//  Created by xzysun on 14-8-15.
//  Copyright (c) 2014年 AnyApps. All rights reserved.
//

#import "PhotoPage.h"
#import "DACircularProgressView.h"

@interface PhotoPage () <UIScrollViewDelegate>
{
    DACircularProgressView *_loadingIndicator;
    UIImageView *_photoImageView;
    UIImageView *_loadingError;
}

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
    self.zoomPhotosToFill = YES;
    // Setup
    self.backgroundColor = [UIColor blackColor];
    self.delegate = self;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.decelerationRate = UIScrollViewDecelerationRateFast;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    // Image view
    _photoImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _photoImageView.contentMode = UIViewContentModeCenter;
    _photoImageView.backgroundColor = [UIColor blackColor];
    [self addSubview:_photoImageView];
    // Loading indicator
    _loadingIndicator = [[DACircularProgressView alloc] initWithFrame:CGRectMake(140.0f, 30.0f, 40.0f, 40.0f)];
    _loadingIndicator.userInteractionEnabled = NO;
    _loadingIndicator.thicknessRatio = 0.1;
    _loadingIndicator.roundedCorners = NO;
    _loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
    UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    [self addSubview:_loadingIndicator];
    // Listen notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setProgressFromNotification:) name:PHOTO_PROGRESS_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setImageFromNotification:) name:PHOTO_LOADING_DID_END_NOTIFICATION object:nil];
    
}

#pragma mark - Image
- (void)setItem:(PhotoItem *)item
{
    // Cancel any loading on old photo
    if (_item && item == nil) {
        if ([_item respondsToSelector:@selector(cancelAnyLoading)]) {
            [_item cancelAnyLoading];
        }
    }
    _item = item;
    UIImage *img = [item underlyingImage];
    if (img) {
        [self displayImage];
    } else {
        // Will be loading so show loading
        [self showLoadingIndicator];
        [item loadUnderlyingImageAndNotify];
    }
}

-(void)setImageFromNotification:(NSNotification *)notification
{
    PhotoItem *item = [notification object];
    if (item == _item) {
        [self displayImage];
    }
}

// Get and display image
- (void)displayImage
{
	if (_item && _photoImageView.image == nil) {
		
		// Reset
		self.maximumZoomScale = 1;
		self.minimumZoomScale = 1;
		self.zoomScale = 1;
		self.contentSize = CGSizeMake(0, 0);
		
		// Get image from browser as it handles ordering of fetching
		UIImage *img = [_item underlyingImage];
		if (img) {
			
			// Hide indicator
			[self hideLoadingIndicator];
			
			// Set image
			_photoImageView.image = img;
			_photoImageView.hidden = NO;
			
			// Setup photo frame
			CGRect photoImageViewFrame;
			photoImageViewFrame.origin = CGPointZero;
			photoImageViewFrame.size = img.size;
			_photoImageView.frame = photoImageViewFrame;
			self.contentSize = photoImageViewFrame.size;
            
			// Set zoom to minimum zoom
			[self setMaxMinZoomScalesForCurrentBounds];
			
		} else {
			
			// Failed no image
            [self displayImageFailure];
			
		}
		[self setNeedsLayout];
	}
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

#pragma mark - Loading Progress
- (void)setProgressFromNotification:(NSNotification *)notification
{
    NSDictionary *dict = [notification object];
    PhotoItem *photoItem = [dict objectForKey:@"photo"];
    if (photoItem == self.item) {
        float progress = [[dict valueForKey:@"progress"] floatValue];
        _loadingIndicator.progress = MAX(MIN(1, progress), 0);
    }
}

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
	
    // Center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = _photoImageView.frame;
    
    // Horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
	} else {
        frameToCenter.origin.x = 0;
	}
    
    // Vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
	} else {
        frameToCenter.origin.y = 0;
	}
    
	// Center
	if (!CGRectEqualToRect(_photoImageView.frame, frameToCenter))
		_photoImageView.frame = frameToCenter;
	
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return _photoImageView;
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
    CGPoint pointForImage = [touch locationInView:_photoImageView];
    if (pointForImage.x>0&&pointForImage.x <CGRectGetWidth(_photoImageView.frame)&&pointForImage.y>0&&pointForImage.y<CGRectGetHeight(_photoImageView.frame)) {
        //点击在图片里面
        return pointForImage;
    }
    //点击在图片外面
    CGFloat touchX = [touch locationInView:self].x;
    CGFloat touchY = [touch locationInView:self].y;
    touchX *= 1/self.zoomScale;
    touchY *= 1/self.zoomScale;
    touchX += self.contentOffset.x;
    touchY += self.contentOffset.y;
    return CGPointMake(touchX, touchY);
}
@end
