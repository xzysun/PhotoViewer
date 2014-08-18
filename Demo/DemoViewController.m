//
//  DemoViewController.m
//  PhotoViewer
//
//  Created by xzysun on 14-8-15.
//  Copyright (c) 2014年 AnyApps. All rights reserved.
//

#import "DemoViewController.h"
#import "PhotoViewer.h"

@interface DemoViewController () <PhotoViewerDatasurce>

@property (weak, nonatomic) IBOutlet UIButton *showImageButton1;
@property (weak, nonatomic) IBOutlet UIImageView *imageView1;
@property (strong, nonatomic) NSArray *list;
@end

@implementation DemoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.list = @[@"http://img3.cache.netease.com/cnews/2014/8/15/20140815131859749f4.jpg", @"http://img3.cache.netease.com/auto/2014/8/15/20140815092747edc4b.jpg", @"http://img4.cache.netease.com/house/2014/8/14/20140814175001decc7.jpg"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)button1Action:(id)sender
{
    NSLog(@"Button1!");
    PhotoViewer *viewer = [PhotoViewer ViewerInWindow];
    viewer.datasource = self;
}

-(NSInteger)numbersOfPhotos
{
    return self.list.count;
}

-(PhotoItem *)photoItemForIndex:(NSInteger)index
{
    NSString *url = [self.list objectAtIndex:index];
    PhotoItem *item = [PhotoItem photoWithURL:[NSURL URLWithString:url]];
    return item;
}
@end
