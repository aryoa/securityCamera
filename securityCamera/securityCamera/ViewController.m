//
//  ViewController.m
//  securityCamera
//
//  Created by ryo on 2014/06/23.
//  Copyright (c) 2014年 ryo. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *myFirstWebView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    NSString* urlString = @"http://ryo-0106.mydns.jp/video/video.html";
    NSURL* myVideo = [NSURL URLWithString: urlString];
    
    NSURLRequest *myRequest = [ NSURLRequest requestWithURL:myVideo cachePolicy: NSURLRequestReloadIgnoringLocalCacheData timeoutInterval: 180.0 ];
    
    // htmlのvideoタグのautoplayを有効にするために必要
    [self.myFirstWebView setMediaPlaybackRequiresUserAction:NO];

    [self.myFirstWebView loadRequest:myRequest];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
