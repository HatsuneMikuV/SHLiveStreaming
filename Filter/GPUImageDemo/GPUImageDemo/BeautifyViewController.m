//
//  BeautifyViewController.m
//  GPUImageDemo
//
//  Created by angle on 13/03/2018.
//  Copyright © 2018 angle. All rights reserved.
//

#import "BeautifyViewController.h"
#import "GPUImageBeautifyFilter.h"

@interface BeautifyViewController ()

@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;

@property (nonatomic, strong) GPUImageView *captureVideoPreview;

@end

@implementation BeautifyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self beautifySkin];
    
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(300, 250, 50, 30)];
    sw.on = NO;
    
    [sw addTarget:self action:@selector(openBeautifyFilter:) forControlEvents:UIControlEventValueChanged];
    
    [self.view addSubview:sw];
    
}
//美颜
- (void)beautifySkin {
    // 创建视频源
    // SessionPreset:屏幕分辨率，AVCaptureSessionPresetHigh会自适应高分辨率
    // cameraPosition:摄像头方向
    GPUImageVideoCamera *videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionFront];
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    _videoCamera = videoCamera;
    
    // 创建最终预览View
    GPUImageView *captureVideoPreview = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    [self.view insertSubview:captureVideoPreview atIndex:0];
    _captureVideoPreview = captureVideoPreview;
    
    // 设置处理链
    [_videoCamera addTarget:_captureVideoPreview];
    
    // 必须调用startCameraCapture，底层才会把采集到的视频源，渲染到GPUImageView中，就能显示了。
    // 开始采集视频
    [videoCamera startCameraCapture];
}
- (void)openBeautifyFilter:(UISwitch *)sender {
    
    // 切换美颜效果原理：移除之前所有处理链，重新设置处理链
    if (sender.on) {
        
        // 移除之前所有处理链
        [_videoCamera removeAllTargets];
        
        // 创建美颜滤镜
        GPUImageBeautifyFilter *beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
        
        // 设置GPUImage处理链，从数据源 => 滤镜 => 最终界面效果
        [_videoCamera addTarget:beautifyFilter];
        [beautifyFilter addTarget:_captureVideoPreview];
        
    } else {
        
        // 移除之前所有处理链
        [_videoCamera removeAllTargets];
        [_videoCamera addTarget:_captureVideoPreview];
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
