//
//  ViewController.m
//  CaptureVideoDemo
//
//  Created by angle on 12/03/2018.
//  Copyright © 2018 angle. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>


@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDeviceInput *currentVideoDeviceInput;
@property (nonatomic, weak) UIImageView *focusCursorImageView;
@property (nonatomic, weak) AVCaptureVideoPreviewLayer *previedLayer;
@property (nonatomic, weak) AVCaptureConnection *videoConnection;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setupCaputureManger];
    
}
//捕获视频
- (AVCaptureDeviceInput *)setupCaputureVideo {
    
    AVCaptureDevice *videoDevice = [self getDeviceWithMediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
    return [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
}
//捕获音频
- (AVCaptureDeviceInput *)setupCaputureAudio {
    // 3.获取声音设备
    AVCaptureDevice *audioDevice = [self getDeviceWithMediaType:AVMediaTypeAudio position:AVCaptureDevicePositionUnspecified];
    
    return [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
}
//音视频捕获管理
- (void)setupCaputureManger {
    
    // 创建捕获会话,必须要强引用，否则会被释放
    AVCaptureSession *caputureManger = [[AVCaptureSession alloc] init];
    self.captureSession = caputureManger;
    // 创建对应视频设备输入对象
    AVCaptureDeviceInput *videoDeviceInput = [self setupCaputureVideo];
    self.currentVideoDeviceInput = videoDeviceInput;
    // 创建对应音频设备输入对象
    AVCaptureDeviceInput *audioDeviceInput = [self setupCaputureAudio];
    
    // 添加到会话中
    // 注意“最好要判断是否能添加输入，会话不能添加空的
    
    // 添加视频
    if ([caputureManger canAddInput:videoDeviceInput]) {
        [caputureManger addInput:videoDeviceInput];
    }
    // 添加音频
    if ([caputureManger canAddInput:audioDeviceInput]) {
        [caputureManger addInput:audioDeviceInput];
    }
    
    // 获取视频数据输出设备
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    // 获取视频输入与输出连接，用于分辨音视频数据
    self.videoConnection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
    // 设置代理，捕获视频样品数据
    // 注意：队列必须是串行队列，才能获取到数据，而且不能为空
    dispatch_queue_t videoQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
    [videoOutput setSampleBufferDelegate:self queue:videoQueue];
    [videoOutput setAlwaysDiscardsLateVideoFrames:YES];
    [videoOutput setVideoSettings:@{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
                                             }];
    if ([caputureManger canAddOutput:videoOutput]) {
        [caputureManger addOutput:videoOutput];
    }
    
    // 获取音频数据输出设备
    AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    // 设置代理，捕获视频样品数据
    // 注意：队列必须是串行队列，才能获取到数据，而且不能为空
    dispatch_queue_t audioQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
    [audioOutput setSampleBufferDelegate:self queue:audioQueue];
    if ([caputureManger canAddOutput:audioOutput]) {
        [caputureManger addOutput:audioOutput];
    }
    
    // 添加视频预览图层
    AVCaptureVideoPreviewLayer *previedLayer = [AVCaptureVideoPreviewLayer layerWithSession:caputureManger];
    previedLayer.frame = [UIScreen mainScreen].bounds;
    [self.view.layer insertSublayer:previedLayer atIndex:0];
    self.previedLayer = previedLayer;
    // 启动会话
    [caputureManger startRunning];
}
//获取指定设备（前、后摄像头、麦克风等）
- (AVCaptureDevice *)getDeviceWithMediaType:(AVMediaType)mediaType position:(AVCaptureDevicePosition)position {
    AVCaptureDevice *captureDevice = nil;
    if (@available(iOS 10.0, *)) {
        AVCaptureDeviceDiscoverySession *videoDeviceSession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInMicrophone,AVCaptureDeviceTypeBuiltInWideAngleCamera,AVCaptureDeviceTypeBuiltInTelephotoCamera,AVCaptureDeviceTypeBuiltInDualCamera,AVCaptureDeviceTypeBuiltInTrueDepthCamera] mediaType:mediaType position:position];
        captureDevice = [videoDeviceSession.devices firstObject];
    }else {
        if (mediaType == AVMediaTypeAudio) {
            captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:mediaType];
        }else {
            NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
            for (AVCaptureDevice *device in devices) {
                if (device.position == position) {
                    captureDevice = device;
                }
            }
        }
    }
    return captureDevice;
}
#pragma mark -
#pragma mark   ==============AVCaptureVideoDataOutputSampleBufferDelegate==============
#pragma mark   ==============AVCaptureAudioDataOutputSampleBufferDelegate==============
// 获取输入设备数据，有可能是音频有可能是视频
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (connection == self.videoConnection) {
        NSLog(@"采集到视频数据");
    }else {
        NSLog(@"采集到音频数据");
    }
}
#pragma mark -
#pragma mark   ==============切换摄像头==============
- (IBAction)toggleCapture:(id)sender {
    
    // 获取当前设备方向
    AVCaptureDevicePosition curPosition = self.currentVideoDeviceInput.device.position;
    
    // 获取需要改变的方向
    AVCaptureDevicePosition togglePosition = curPosition == AVCaptureDevicePositionFront?AVCaptureDevicePositionBack:AVCaptureDevicePositionFront;
    
    // 获取改变的摄像头设备
    AVCaptureDevice *toggleDevice = [self getDeviceWithMediaType:AVMediaTypeVideo position:togglePosition];
    
    // 获取改变的摄像头输入设备
    AVCaptureDeviceInput *toggleDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:toggleDevice error:nil];
    
    [self.captureSession beginConfiguration];
    // 移除之前摄像头输入设备
    [self.captureSession removeInput:self.currentVideoDeviceInput];
    
    // 添加新的摄像头输入设备
    [self.captureSession addInput:toggleDeviceInput];
    
    [self.captureSession commitConfiguration];
    // 记录当前摄像头输入设备
    self.currentVideoDeviceInput = toggleDeviceInput;
}
// 点击屏幕，出现聚焦视图
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    // 获取点击位置
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    
    // 把当前位置转换为摄像头点上的位置
    CGPoint cameraPoint = [self.previedLayer captureDevicePointOfInterestForPoint:point];
    
    // 设置聚焦点光标位置
    [self setFocusCursorWithPoint:point];
    
    // 设置聚焦
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}

/**
 *  设置聚焦光标位置
 *
 *  @param point 光标位置
 */
-(void)setFocusCursorWithPoint:(CGPoint)point{
    self.focusCursorImageView.center=point;
    self.focusCursorImageView.transform=CGAffineTransformMakeScale(1.5, 1.5);
    self.focusCursorImageView.alpha=1.0;
    [UIView animateWithDuration:1.0 animations:^{
        self.focusCursorImageView.transform=CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusCursorImageView.alpha=0;
        
    }];
}

/**
 *  设置聚焦
 */
-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point{
    
    AVCaptureDevice *captureDevice = self.currentVideoDeviceInput.device;
    // 锁定配置
    [captureDevice lockForConfiguration:nil];
    
    // 设置聚焦
    if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
    }
    if ([captureDevice isFocusPointOfInterestSupported]) {
        [captureDevice setFocusPointOfInterest:point];
    }
    
    // 设置曝光
    if ([captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
        [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
    }
    if ([captureDevice isExposurePointOfInterestSupported]) {
        [captureDevice setExposurePointOfInterest:point];
    }
    
    // 解锁配置
    [captureDevice unlockForConfiguration];
}
/**
 *  懒加载聚焦视图
 *
 */
- (UIImageView *)focusCursorImageView {
    if (_focusCursorImageView == nil) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"focus"]];
        _focusCursorImageView = imageView;
        [self.view addSubview:_focusCursorImageView];
    }
    return _focusCursorImageView;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
