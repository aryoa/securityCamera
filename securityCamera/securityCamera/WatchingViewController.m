//
//  WatchingViewController.m
//  securityCamera
//
//  Created by ryo on 2014/08/11.
//  Copyright (c) 2014年 ryo. All rights reserved.
//

#import "WatchingViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <dispatch/dispatch.h>
#import <MediaPlayer/MediaPlayer.h>


@interface WatchingViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>


@property AVCaptureSession *captureSession;
@property AVCaptureVideoPreviewLayer *previewLayer;
@property NSMutableDictionary *videoSettings;
@property AVAssetWriterInput *assetWriterInputVideo;

@property CMTime recordStartTime;

@property dispatch_queue_t movieWritingQueue;
@property AVAssetWriter *assetWriter;


@property NSURL *outputURL;
@property NSTimer *timer;


@property int faceCount;
@property int outFileIndex;

@property (weak, nonatomic) IBOutlet UIImageView *previewImageView;

- (IBAction)topClick:(id)sender;



-(void)startRecord;

@end

@implementation WatchingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSLog(@"%s", __func__);
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    NSLog(@"%s", __func__);

    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.faceCount = 0;
    self.outFileIndex = 0;
    
    
    // タイマーを作成してスタート
    self.timer = [NSTimer scheduledTimerWithTimeInterval:20.0f
                                     target:self
                                   selector:@selector(writeData)
                                    userInfo:nil
                                    repeats:YES];
    
    
    self.recordStartTime        = kCMTimeZero;
    
    // device
    AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Video
    AVCaptureDeviceInput* videoInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:NULL];
    AVCaptureVideoDataOutput* videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    [videoOutput setVideoSettings: [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey,
                                    nil]];
    
    // Setting Camera
    AVCaptureConnection *videoConnection = NULL;
    [self.captureSession beginConfiguration];
    
    for ( AVCaptureConnection *connection in [videoOutput connections] ) {
        for ( AVCaptureInputPort *port in [connection inputPorts] ) {
            
            NSLog(@"%@", port);
            if ( [[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
            }
        }
    }
    
    // portrait orientation
    [videoConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    
    // initialize capture session
    self.captureSession = [[AVCaptureSession alloc] init];
    if ([self.captureSession canAddInput:videoInput]) {
        [self.captureSession addInput:videoInput];
    }
    if ([self.captureSession canAddOutput:videoOutput]) {
        [self.captureSession addOutput:videoOutput];
    }
    
    
    [self.captureSession setSessionPreset: AVCaptureSessionPreset352x288];
    
    
    // PreviewLayer
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    
    [self.captureSession commitConfiguration];
    
    // session start
    [self.captureSession startRunning];
    
    
    // video setting
//    self.videoSettings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
//                          AVVideoCodecH264, AVVideoCodecKey,
//                          @1280, AVVideoWidthKey,
//                          @720,  AVVideoHeightKey,
//                          [NSDictionary dictionaryWithObjectsAndKeys:
//                           @30, AVVideoMaxKeyFrameIntervalKey,
//                           nil], AVVideoCompressionPropertiesKey,
//                          nil];
    self.videoSettings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                          AVVideoCodecH264, AVVideoCodecKey,
                          @352, AVVideoWidthKey,
                          @288,  AVVideoHeightKey,
                          [NSDictionary dictionaryWithObjectsAndKeys:
                           @30, AVVideoMaxKeyFrameIntervalKey,
                           nil], AVVideoCompressionPropertiesKey,
                          nil];
    
    [self startRecord];
    
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"%s", __func__);

    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (void)captureOutput:(AVCaptureOutput*)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection*)connection
{
    NSLog(@"%s\n",__func__);
    
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        NSLog(@"sampleBuffer data is not ready");
    }
    
    CMTime currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    
    // Video
    if ([captureOutput isKindOfClass:[AVCaptureVideoDataOutput class]]) {
        [self addSamplebuffer:sampleBuffer withWriterInput:(AVAssetWriterInput *)self.assetWriterInputVideo];
    }
    self.recordStartTime = currentTime;

    
    
    CVImageBufferRef    buffer;
    buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // イメージバッファのロック
    CVPixelBufferLockBaseAddress(buffer, 0);
    
    // イメージバッファ情報の取得
    uint8_t*    base;
    size_t      width, height, bytesPerRow;
    base = CVPixelBufferGetBaseAddress(buffer);
    width = CVPixelBufferGetWidth(buffer);
    height = CVPixelBufferGetHeight(buffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    
    // ビットマップコンテキストの作成
    CGColorSpaceRef colorSpace;
    CGContextRef    cgContext;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate(
                                      base, width, height, 8, bytesPerRow, colorSpace,
                                      kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    // 画像の作成
    CGImageRef  cgImage;
    UIImage*    image;
    cgImage = CGBitmapContextCreateImage(cgContext);
    image = [UIImage imageWithCGImage:cgImage scale:1.0f
                          orientation:UIImageOrientationRight];
    CGImageRelease(cgImage);
    CGContextRelease(cgContext);
    
    
    // イメージバッファのアンロック
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    
    
    // 顔検出
    // 検出器生成
    NSDictionary *options = [NSDictionary dictionaryWithObject:CIDetectorAccuracyLow forKey:CIDetectorAccuracy];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:options];
    
    // 検出
    CIImage *ciImage = [[CIImage alloc] initWithCGImage:image.CGImage];
    NSDictionary *imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:6] forKey:CIDetectorImageOrientation];
    NSArray *array = [detector featuresInImage:ciImage options:imageOptions];
    
    // 検出されたデータを取得
    if ([array count] > self.faceCount){
        self.faceCount = [array count];
        NSLog(@"顔検出");
        
        [self sendApplePushNotification];
        
        
        UIAlertView *alert =
        [[UIAlertView alloc]
         initWithTitle:@"タイトル"
         message:@"顔検出"
         delegate:nil
         cancelButtonTitle:nil
         otherButtonTitles:@"OK", nil
         ];
        [alert show];

    }
    //        for (CIFaceFeature *faceFeature in array) {
    //            if ([array count] > self.faceCount){
    //                self.faceCount++;
    //                NSLog(@"顔検出");
    //            }
    //        }
    
    // 画像の表示
    self.previewImageView.image = image;
}

- (void)addSamplebuffer:(CMSampleBufferRef)sampleBuffer withWriterInput:(AVAssetWriterInput *)assetWriterInput
{
    NSLog(@"%s", __func__);

    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    
    CFRetain(sampleBuffer);
    CFRetain(formatDescription);
    dispatch_async(self.movieWritingQueue, ^{
        if (![assetWriterInput isReadyForMoreMediaData]) {
            NSLog(@"Not ready for data :(");
        }
        //NSLog(@"Trying to append");
        
        if (_assetWriter.status == AVAssetWriterStatusUnknown) {
            NSLog(@"AVAssetWriterStatusUnknown");
        }
        if (_assetWriter.status == AVAssetWriterStatusWriting) {
            //NSLog(@"AVAssetWriterStatusWriting");
            
            if (assetWriterInput.readyForMoreMediaData) {
                
                if (![assetWriterInput appendSampleBuffer:sampleBuffer]) {
                    NSLog(@"%@",[self.assetWriter error]);
                }
                
            }
        }
        else if (_assetWriter.status == AVAssetWriterStatusFailed) {
            NSLog(@"AVAssetWriterStatusFailed");
            NSLog(@"%@",[self.assetWriter error]);
        }
        else if (_assetWriter.status == AVAssetWriterStatusCancelled) {
            NSLog(@"AVAssetWriterStatusCancelled");
        }
        else if (_assetWriter.status == AVAssetWriterStatusCompleted) {
            NSLog(@"AVAssetWriterStatusCompleted");
        }
        
        CFRelease(sampleBuffer);
        CFRelease(formatDescription);
    });
}

-(void)startRecord
{
    NSLog(@"%s", __func__);
    
    // Output
    NSError *error;
    //    NSString *fileName   = [NSString stringWithFormat:@"output%2d.mov", (int)[self.movieURLs count] + 1];
    if (self.outFileIndex > 5){
        self.outFileIndex = 1;
    }
    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@%d.MOV", NSTemporaryDirectory(), @"output", self.outFileIndex];
    self.outFileIndex++;
    self.outputURL       = [[NSURL alloc] initFileURLWithPath:outputPath];
    NSLog(@"outputPath = %@", outputPath);
    
    // delete file before save the one
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:outputPath]) {
        
        if ([fileManager removeItemAtPath:outputPath error:&error] == NO) {
            //NSLog(@"failed deleting file");
        }
        
    }
    
    // AVAssetWriter
    self.assetWriter = [AVAssetWriter assetWriterWithURL:self.outputURL fileType:AVFileTypeQuickTimeMovie error:&error];
    if (error != nil) {
        //NSLog(@"Creation of assetWriter resulting in a non-nil error");
    }
    
    // movie
    NSDictionary *videoSetting = self.videoSettings;
    self.assetWriterInputVideo = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSetting];
    [self.assetWriterInputVideo setExpectsMediaDataInRealTime:YES];
    if (self.assetWriterInputVideo == nil) {
        NSLog(@"assetWriterInput is nil");
    }
    
    [self.assetWriter addInput:self.assetWriterInputVideo];
    
    // queue
    self.movieWritingQueue = dispatch_queue_create("Movie Writing Queue", DISPATCH_QUEUE_SERIAL);
    
    // Record
    NSLog(@"[Starting to record]");
    dispatch_async(self.movieWritingQueue, ^{
        [self.assetWriter startWriting];
        [self.assetWriter startSessionAtSourceTime:self.recordStartTime];
    });
    
}

/**
 タイマーによって呼び出される
 撮影データを動画ファイルにし、serverに送る
 */
-(void)writeData
{
    NSLog(@"%s",__func__);
    [self.captureSession stopRunning];

    NSLog(@"[Stopping recording] duration : %f", CMTimeGetSeconds(self.recordStartTime));
    
    [self.assetWriterInputVideo markAsFinished];
    [self.assetWriter endSessionAtSourceTime:self.recordStartTime];
    [self.assetWriter finishWritingWithCompletionHandler:^{
        NSLog(@"self.assetWriter finishWritingWithCompletionHandler");
        [self sendDataToServer];
        [self.captureSession startRunning];
        [self startRecord];
    }];
    
    
}
-(void)sendDataToServer
{
    NSLog(@"%s", __func__);

    NSURL *fileURL = self.outputURL;
    NSString *filePath = [fileURL path];
    NSData *movData = [NSData dataWithContentsOfFile:filePath];
    
    
    //送信先URL
    // 送信するリクエストを作成する。
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *server = [defaults stringForKey:@"SERVER"];
    
    
    NSString *urlString = [NSString stringWithFormat:@"%@/updateVideo/updateVideo.php",server];
    
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    
    //multipart/form-dataのバウンダリ文字列生成
    CFUUIDRef uuid = CFUUIDCreate(nil);
    CFStringRef uuidString = CFUUIDCreateString(nil, uuid);
    CFRelease(uuid);
    NSString *boundary = [NSString stringWithFormat:@"0xKhTmLbOuNdArY-%@",uuidString];
    
    
    
    //アップロードする際のパラメーター名
    NSString *parameter = @"movie";
    //アップロードするファイルの名前
    NSString *fileName = [[filePath componentsSeparatedByString:@"/"] lastObject];
    //アップロードするファイルの種類
    NSString *contentType = @"video/mov";
    NSMutableData *postBody = [NSMutableData data];
    
    
    //HTTPBody
    [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n",parameter,fileName] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", contentType] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:movData];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    //リクエストヘッダー
    NSString *header = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request addValue:header forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postBody];
    
    
    [NSURLConnection connectionWithRequest:request delegate:self];
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSLog(@"%s", __func__);

    if(httpResponse.statusCode == 200) {
        NSLog(@"Success ٩꒰๑ ´∇`๑꒱۶✧");
    } else {
        NSLog(@"Failed (´；ω；｀)");
    }
}


-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSLog(@"%s", __func__);

    NSArray *jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSLog(@"%@", jsonObject);
}


-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"%@", error);
}

// 録画開始
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    NSLog(@"%s", __func__);
    
    NSLog(@"rec start.");
    
}
/// http://www.ios-developer.net/iphone-ipad-programmer/development/camera/record-video-with-avcapturesession-2
/// http://qiita.com/Lewuathe/items/517185293ccf520f14f7


///http://www.slideshare.net/himaratsu/6-vine
// 録画停止
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    NSLog(@"%s", __func__);
    NSLog(@"%@", [error localizedDescription]);
    
    NSLog(@"rec end.");
    
    // 出力ファイルをしていしておく
    MPMoviePlayerViewController *moviePlayerView = [[MPMoviePlayerViewController alloc] initWithContentURL:outputFileURL];
    MPMoviePlayerController *p = moviePlayerView.moviePlayer;
    p.shouldAutoplay=YES;
    
    // 再生してみる
    [p play];
    
    // モーダルとして表示させる
    [self presentMoviePlayerViewControllerAnimated:moviePlayerView];
    
    //    [player.view setFrame:CGRectMake(0, 0, 320, 200)];
    //    [self.view addSubview:player.view];
    //    // 再生開始
    //    [player prepareToPlay];
    
}

- (IBAction)topClick:(id)sender {
    [self.timer invalidate];
    [self.captureSession stopRunning];

    [self dismissViewControllerAnimated:YES completion:nil];
}


-(void)sendApplePushNotification
{
    // 送信するリクエストを作成する。
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *server = [defaults stringForKey:@"SERVER"];
    
    
    NSString *urlString = [NSString stringWithFormat:@"%@/securityCamera/sample_push.php",server];

    
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    
    // リクエストを送信する。
    NSError *error;
    NSURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    // リクエスト結果を表示する。
    // エラー処理は、上の非同期リクエストと同じ感じで。
    NSLog(@"request finished!!");
    NSLog(@"error = %@", error);
    NSLog(@"statusCode = %ld", (long)((NSHTTPURLResponse *)response).statusCode);
    NSLog(@"responseText = %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
}


@end
