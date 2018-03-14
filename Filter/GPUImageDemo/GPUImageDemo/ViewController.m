//
//  ViewController.m
//  GPUImageDemo
//
//  Created by angle on 13/03/2018.
//  Copyright © 2018 angle. All rights reserved.
//

#import "ViewController.h"

#import <GPUImage/GPUImage.h>
#import "BeautifyViewController.h"

@interface ViewController ()

@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;

@property (nonatomic, strong) GPUImageBrightnessFilter *brightnessFilter;

@property (nonatomic, strong) GPUImageBilateralFilter *bilateralFilter;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self WhiteningSkinGrinding];
}
//美白+磨皮
- (void)WhiteningSkinGrinding {
    // 创建视频源
    // SessionPreset:屏幕分辨率，AVCaptureSessionPresetHigh会自适应高分辨率
    // cameraPosition:摄像头方向
    GPUImageVideoCamera *videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionFront];
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    _videoCamera = videoCamera;
    
    // 创建最终预览View
    GPUImageView *captureVideoPreview = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    [self.view insertSubview:captureVideoPreview atIndex:0];
    
    // 创建滤镜：磨皮，美白，组合滤镜
    GPUImageFilterGroup *groupFilter = [[GPUImageFilterGroup alloc] init];
    
    // 磨皮滤镜
    GPUImageBilateralFilter *bilateralFilter = [[GPUImageBilateralFilter alloc] init];
    [groupFilter addTarget:bilateralFilter];
    _bilateralFilter = bilateralFilter;
    
    // 美白滤镜
    GPUImageBrightnessFilter *brightnessFilter = [[GPUImageBrightnessFilter alloc] init];
    [groupFilter addTarget:brightnessFilter];
    _brightnessFilter = brightnessFilter;
    
    // 设置滤镜组链
    [bilateralFilter addTarget:brightnessFilter];
    [groupFilter setInitialFilters:@[bilateralFilter]];
    groupFilter.terminalFilter = brightnessFilter;
    
    // 设置GPUImage响应链，从数据源 => 滤镜 => 最终界面效果
    [videoCamera addTarget:groupFilter];
    [groupFilter addTarget:captureVideoPreview];
    
    // 必须调用startCameraCapture，底层才会把采集到的视频源，渲染到GPUImageView中，就能显示了。
    // 开始采集视频
    [videoCamera startCameraCapture];
}

- (IBAction)brightnessFilter:(UISlider *)sender {
    _brightnessFilter.brightness = sender.value;
    
}

- (IBAction)bilateralFilter:(UISlider *)sender {
    // 值越小，磨皮效果越好
    CGFloat maxValue = 10;
    [_bilateralFilter setDistanceNormalizationFactor:(maxValue - sender.value)];
}
- (IBAction)openBeautifyFilter:(id)sender {
    [self.navigationController pushViewController:[[BeautifyViewController alloc] init] animated:YES];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
