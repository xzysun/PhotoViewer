PhotoViewer
===========

一个用于进行图片展示的项目，模仿了微信朋友圈的显示效果，点击退出展示，双击放大缩小，有多个图片的时候支持分页滑动查看。支持传入图片对象或者图片地址。

内部实现上使用SDWebImage来进行图片的缓存处理。同时在加载的时候，使用DACircularProgress绘制加载的进度。

使用方法
申明一个类，实现<PhotoViewerDatasource>
实现方法<br>
<code>
-(NSInteger)numbersOfPhotos;
</code>
<br>
<code>
-(PhotoItem *)photoItemForIndex:(NSInteger)index;
</code>

调用代码<br>
<code>
PhotoViewer *viewer = [PhotoViewer ViewerInWindow];
</code>
<br>
<code>
viewer.datasource = self;
</code>
