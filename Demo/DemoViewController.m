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
    self.list = @[@"http://file.ynet.com/2/1510/13/10444105-500.jpg", @"http://file.ynet.com/2/1510/13/10444107-500.jpg", @"http://file.ynet.com/2/1510/13/10444120-500.jpg", @"http://file.ynet.com/2/1510/13/10444123-500.jpg"];
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
