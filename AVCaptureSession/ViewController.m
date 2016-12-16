//
//  ViewController.m
//  AVCaptureSession
//
//  Created by Joe_Liu on 16/12/14.
//  Copyright © 2016年 Joe_Liu. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AACEncoder.h"

#define CAPTURE_FRAMES_PER_SECOND       20
#define SAMPLE_RATE                     16000
FILE *fp;

@interface ViewController ()<AVCaptureAudioDataOutputSampleBufferDelegate>

// 负责输如何输出设备之间的数据传递
@property (nonatomic, strong) AVCaptureSession           *session;
@property (nonatomic, strong) dispatch_queue_t           AudioQueue;
@property (nonatomic, strong) AVCaptureConnection        *audioConnection;
@property (nonatomic, strong) AACEncoder                 *aacEncoder;
@property (nonatomic, strong) UIButton                   *startBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    //初始化AVCaptureSession
    self.session = [[AVCaptureSession alloc] init];

    [self initStartBtn];
}
#pragma mark - 设置音频
- (void)setupAudioCapture {
    
    self.aacEncoder = [AACEncoder new];
    
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    NSError *error = nil;
    
    AVCaptureDeviceInput *audioInput = [[AVCaptureDeviceInput alloc]initWithDevice:audioDevice error:&error];
    
    if (error) {
        
        NSLog(@"Error getting audio input device:%@",error.description);
    }
    
    if ([self.session canAddInput:audioInput]) {
        
        [self.session addInput:audioInput];
    }
    
    self.AudioQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
    
    AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    
    [audioOutput setSampleBufferDelegate:self queue:self.AudioQueue];
    
    if ([self.session canAddOutput:audioOutput]) {
        
        [self.session addOutput:audioOutput];
    }
    
    self.audioConnection = [audioOutput connectionWithMediaType:AVMediaTypeAudio];
}

#pragma mark - 实现 AVCaptureOutputDelegate：
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    CMTime pts = CMSampleBufferGetDuration(sampleBuffer);
    
    double dPTS = (double)(pts.value) / pts.timescale;
    NSLog(@"DPTS is %f",dPTS);
    
    if (connection == _audioConnection) {  // Audio
        
        //NSLog(@"这里获得audio sampleBuffer，做进一步处理（编码AAC）");
        
        [self.aacEncoder encodeSampleBuffer:sampleBuffer completionBlock:^(NSData *encodedData, NSError *error) {
            
            if (encodedData) {
    
#pragma mark -  音频数据(encodedData)
                const char *buf = encodedData.bytes;
                if (fp) {
                    fwrite(buf, 1, encodedData.length, fp);
                    NSLog(@"Audio data (%lu):%@", (unsigned long)encodedData.length,encodedData.description);
                }
                
            }else {
                
                NSLog(@"Error encoding AAC: %@", error);

            }
        }];
    }
}

#pragma mark - 录制
- (void)startBtnClicked:(UIButton *)btn
{
    btn.selected = !btn.selected;
    
    if (btn.selected)
    {
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test.aac"];
        const char * cPath = [path cStringUsingEncoding:NSUTF8StringEncoding];
        
        fp = fopen(cPath, "w+");
        
        [self startCamera];
        [self.startBtn setTitle:@"Stop" forState:UIControlStateNormal];
        
    }
    else
    {
        if (fp) {
            fclose(fp);
        }
        
        [self.startBtn setTitle:@"Start" forState:UIControlStateNormal];
        [self stopCarmera];
    }
    
}

- (void) startCamera
{
    [self setupAudioCapture];
    [self.session commitConfiguration];
    [self.session startRunning];
}

- (void) stopCarmera
{
    [_session stopRunning];
    
////    //close(fd);
//    [_fileHandle closeFile];
//    _fileHandle = NULL;
////
//    // 获取程序Documents目录路径
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    
//    NSMutableString * path = [[NSMutableString alloc]initWithString:documentsDirectory];
//    [path appendString:@"/AACFile.aac"];
//    
//    [_data writeToFile:path atomically:YES];
    
}

- (void)initStartBtn
{
    self.startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.startBtn.frame = CGRectMake(0, 0, 100, 40);
    self.startBtn.backgroundColor = [UIColor lightGrayColor];
    self.startBtn.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height - 30);
    [self.startBtn addTarget:self action:@selector(startBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.startBtn setTitle:@"Start" forState:UIControlStateNormal];
    [self.startBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:self.startBtn];
}


@end
