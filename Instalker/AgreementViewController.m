//
//  AgreementViewController.m
//  Instalker
//
//  Created by umut on 13/03/16.
//  Copyright © 2016 SmartClick. All rights reserved.
//

#import "AgreementViewController.h"

@interface AgreementViewController ()<UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webview;

@end

@implementation AgreementViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden=YES;
    
    self.webview.delegate = self;
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL: [NSURL URLWithString: @"https://www.iubenda.com/privacy-policy/7817174"] cachePolicy: NSURLRequestUseProtocolCachePolicy timeoutInterval: 30.0];
    [self.webview loadRequest: request];
    // Do any additional setup after loading the view.
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Agreement"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden=NO;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)configureNavigationProperties
{
    
    self.navigationItem.titleView.tintColor = [UIColor whiteColor];
    
    self.navigationController.navigationBar.backItem.titleView.tintColor= [UIColor whiteColor];
    self.navigationController.navigationBar.backItem.title =NSLocalizedString( @"Back",nil);
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
