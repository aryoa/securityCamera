//
//  ViewingViewController.m
//  securityCamera
//
//  Created by ryo on 2014/08/12.
//  Copyright (c) 2014年 ryo. All rights reserved.
//

#import "ViewingViewController.h"

@import AVFoundation;

#define MAX_INDEX 5

@interface ViewingViewController ()
@property (weak, nonatomic) IBOutlet UIView *previewView;
// 1
@property (strong, nonatomic) AVQueuePlayer *player;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
// 2
@property (strong, nonatomic) NSMutableArray *playItems;

- (IBAction)reloadClick:(id)sender;
- (IBAction)topClick:(id)sender;

- (IBAction)rotationClick:(id)sender;

@property int video_index;
@property int last_index;


@end

@implementation ViewingViewController

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
    // Do any additional setup after loading the view.
    
    self.player = [[AVQueuePlayer alloc] init];
    self.video_index = 0;
    
    self.previewView.frame = CGRectMake(0, 0, 300, 245);
    self.previewView.transform = CGAffineTransformMakeRotation(M_PI/2);


}

- (void)didReceiveMemoryWarning
{
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
- (void)setupPlayer
{
    NSLog(@"%s", __func__);

    int index = 0;
    NSString *indexStr = [self getIndexFromSever];
    if (indexStr == nil){
        NSLog(@"ファイルインデックスの取得失敗");
        return;
    }else{
        index = [indexStr intValue];
   
    }
    if (index == 0){
        NSLog(@"準備中");
        UIAlertView *alert =
        [[UIAlertView alloc]
         initWithTitle:@"タイトル"
         message:@"準備"
         delegate:nil
         cancelButtonTitle:nil
         otherButtonTitles:@"OK", nil
         ];
        [alert show];
        return;
    }
    
    if (index == self.video_index){
        UIAlertView *alert =
        [[UIAlertView alloc]
         initWithTitle:@"タイトル"
         message:@"再ロード/監視停止"
         delegate:nil
         cancelButtonTitle:nil
         otherButtonTitles:@"OK", nil
         ];
        [alert show];
        return;
    }
    
    self.video_index = index;
    

    self.video_index = index;
    if (self.playItems  == nil){
        // 1
        self.playItems = [[NSMutableArray alloc] init];
    }else{
        [self.playItems removeAllObjects];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *server = [defaults stringForKey:@"SERVER"];
    
    

    NSString *path = [NSString stringWithFormat:@"%@/updateVideo/videos/output%d.MOV", server, index];
    NSURL *url = [NSURL URLWithString:path];
    
    // 2
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    [self.playItems addObject:item];

//    for (int i = 0; i < MAX_INDEX; i++)
//    {
//        if ((index + i) >  MAX_INDEX){
//            index = 1 - i;
//        }
//        NSString *path = [NSString stringWithFormat:@"http://192.168.1.5/updateVideo/videos/output%d.MOV", index + i];
//        NSURL *url = [NSURL URLWithString:path];
//        
//        // 2
//        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
//        [self.playItems addObject:item];
//    }
    
    
    // 1
    [self.player removeAllItems];
    for (AVPlayerItem *item in self.playItems)
    {
        [item seekToTime:kCMTimeZero];
        [self.player insertItem:item afterItem:nil];
    }
    
    // 2
    if (self.playerLayer)
    {
        [self.playerLayer removeFromSuperlayer];
    }
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = self.previewView.bounds;
//    self.playerLayer.frame = CGRectMake(0, 0, 220, 220);
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [self.previewView.layer addSublayer:self.playerLayer];
    
    [self.playerLayer addObserver:self
                       forKeyPath:@"readyForDisplay"
                          options:NSKeyValueObservingOptionNew
                          context:nil];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"%s", __func__);
    // 1
    if ([keyPath isEqualToString:@"readyForDisplay"])
    {
        // 2
        [self.playerLayer removeObserver:self forKeyPath:@"readyForDisplay"];
        
        // 3
        [self.player play];
    }
}

- (void)onVideoEnd
{
    NSLog(@"video end:%d", self.video_index);
//    self.video_index++;
//
//    if (self.video_index > MAX_INDEX){
//        self.video_index = 1;
//    }
    [self setupPlayer];

}


-(void)videoFail
{
    NSLog(@"%s", __func__);
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onVideoEnd)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoFail)
                                                 name:AVPlayerItemFailedToPlayToEndTimeNotification
                                               object:nil];
    
    

    
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [self setupPlayer];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemFailedToPlayToEndTimeNotification
                                                  object:nil];
    
    
    
}


- (IBAction)reloadClick:(id)sender {
    [self setupPlayer];

}

- (IBAction)topClick:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(NSString *)getIndexFromSever
{
    // 送信するリクエストを作成する。
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *server = [defaults stringForKey:@"SERVER"];
    
    NSString *urlString = [NSString stringWithFormat:@"%@/updateVideo/videos/index.txt",server];
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    
    // リクエストを送信する。
    NSError *error;
    NSURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    
    if (error != nil){
        UIAlertView *alert =
        [[UIAlertView alloc]
         initWithTitle:@"タイトル"
         message:[error localizedDescription]
         delegate:nil
         cancelButtonTitle:nil
         otherButtonTitles:@"OK", nil
         ];
        [alert show];
        return nil;

    }
    // リクエスト結果を表示する
    NSLog(@"request finished!!");
    NSLog(@"error = %@", error);
    NSLog(@"statusCode = %ld", (long)((NSHTTPURLResponse *)response).statusCode);
    NSLog(@"responseText = %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

}

- (IBAction)rotationClick:(id)sender
{
    self.previewView.transform = CGAffineTransformMakeRotation(M_PI/2);
}

@end
