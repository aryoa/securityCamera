//
//  SettingViewController.m
//  securityCamera
//
//  Created by ryo on 2014/08/12.
//  Copyright (c) 2014年 ryo. All rights reserved.
//

#import "SettingViewController.h"
#import "Toolbox.h"

@interface SettingViewController ()
@property (weak, nonatomic) IBOutlet UITextField *SettingText;
- (IBAction)DoneClick:(id)sender;

@end

@implementation SettingViewController

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

- (IBAction)DoneClick:(id)sender {
    NSLog(@"%s", __func__);
    NSLog(@"%@", self.SettingText.text );
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.SettingText.text forKey:@"SERVER"];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}
@end
