//
//  MyProfileViewController.m
//  Instalker
//
//  Created by umut on 1/26/16.
//  Copyright © 2016 SmartClick. All rights reserved.
//

#import "MyProfileViewController.h"
#import "ServiceManager.h"
#import "StatsProfileView.h"
#import "MediaViewController.h"
#import "DateSelectPopupViewController.h"
#import <STPopup/STPopup.h>


@interface MyProfileViewController () <DateSelectPopupDelegate>
@property (weak,nonatomic) IBOutlet UILabel *labelNoMediaWarning;
- (IBAction)changeDateButtonPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *buttonChangeDate;
@property (weak, nonatomic) IBOutlet UILabel *labelMediaCountInInterval;
@property (weak,nonatomic) IBOutlet StatsProfileView *viewStatsProfile;
@property (nonatomic,strong) StatsModel *statsModel;
@property (nonatomic,strong) NSMutableArray *arrayDates;
@property (nonatomic) BOOL isDataObtained;
@property (nonatomic,strong) STPopupController *popupController;
@property (nonatomic,strong) DateSelectPopupViewController *dateSelectPopup;

@end

@implementation MyProfileViewController

#pragma  mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self setDelegates];
    [self configureScrollview];
    
    _arrayDates = [NSMutableArray arrayWithObjects:NSLocalizedString(@"1 Week",nil),NSLocalizedString(@"1 Month",nil),NSLocalizedString(@"3 Months",nil),NSLocalizedString(@"6 Months",nil), NSLocalizedString(@"All Time",nil),nil];
    
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"My Profile"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    if (!_isDataObtained) {
        [self startServiceForBothWithMedia:kWeek];
        _isDataObtained = YES;
    }
    
    if (!_user ) {
        [self configureNavigationBarForMyProfile];
    }else
    {
        [self configureNavigationBarWithTitle:_user.username];
        
    }
    
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[PopUpManager sharedManager] removeAllPopups];
    
}

#pragma mark - Navigation Bar
-(void)configureNavigationBarForMyProfile
{
    self.navigationItem.title = NSLocalizedString(@"My Profile",nil);
    [self configureNavigationProperties];
}

-(void)configureNavigationBarWithTitle:(NSString *)title
{
    self.navigationItem.title = title;
    [self configureNavigationProperties];
}


-(void)configureNavigationProperties
{
    self.navigationItem.titleView.tintColor = [UIColor whiteColor];
 
    self.navigationController.navigationBar.backItem.titleView.tintColor= [UIColor whiteColor];
    self.navigationController.navigationBar.backItem.title = NSLocalizedString(@"Back",nil);
    
}

#pragma mark - Initilization
-(void)configureScrollview{
    _scrollViewMain.contentSize=CGSizeMake(_viewContentOfScroll.bounds.size.width, _viewContentOfScroll.bounds.size.height);
}
-(void)setDelegates
{
    _scrollViewMain.delegate=self;
    _tableView.delegate= self;
    _tableView.dataSource=self;
}

-(void)startServiceForBothWithMedia:(kMediaDate)date
{
    if (!_user) {
        [self startSelfServicewithDate:date];
        
    }
    else
    {
        
        [self startServiceForUser:_user withDate:date];
    }
    
    
}
-(void)startSelfServicewithDate:(kMediaDate)date {
    
    [self startLoadingAnimation];
    
    ServiceManager *manager = [ServiceManager new];
    
    [manager getSelfDataWithCompletion:^(NSMutableArray *likeList, StatsModel *stats) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _arrayData = likeList;
            [self.tableView reloadData];
            _statsModel=stats;
            [_viewStatsProfile configureViews:stats];
            _labelNameForTitle.text = stats.textName;
            if (stats.filteredPostCount <1) {
                [self setErrorLabelAsNoMedia:YES hidden:NO];
            }
            else
            {
                [self setErrorLabelAsNoMedia:YES hidden:YES];
            }
            _labelMediaCountInInterval.text= [NSString stringWithFormat:NSLocalizedString(@"%ld Media",nil),(long)stats.filteredPostCount];
            [self removeLoadingAnimation];
          
        });
        
    }failure:^(NSError *error, InstagramFailModel *errorModel) {
        
        [self removeLoadingAnimation];
        [self showError:errorModel];
    }dateinterval:date];
    
}
-(void)showError:(InstagramFailModel *)model
{
    if ([model.meta.errorType isEqualToString:k_error_null_token_count]) {
        [[PopUpManager sharedManager] showErrorPopupWithTitle:NSLocalizedString(@"Your daily Instagram token limit is accessed, Try to use tomorrow",nil) completion:^{
            [[Singleton sharedInstance].baseNavigationController popToRootViewControllerAnimated:YES];
        }from:self];
        
        
    }else
     if ([model.meta.errorType isEqualToString:k_error_private_profile]) {
         [[PopUpManager sharedManager]showErrorPopupWithTitle:NSLocalizedString(@"This profile is private, try to stalk others",nil) completion:^{
         }from:self];
         [self setErrorLabelAsNoMedia:NO hidden:NO];

     
     }else if ([model.meta.errorType isEqualToString:k_error_token_invalid]) {
         [[PopUpManager sharedManager] showErrorPopupWithTitle:NSLocalizedString(@"Your Instagram credentials invalidated by Instagram, try to login again",nil) completion:^{
             [[InstagramEngine sharedEngine]logout];
             [[Singleton sharedInstance].baseNavigationController popToRootViewControllerAnimated:YES];
         }from:self];
         
         
     }
    else
    {
        [[PopUpManager sharedManager]showErrorPopupWithTitle:model.meta.errorMessage completion:^{
            [self dismissViewControllerAnimated:YES completion:^{
                
            }];
            
        }from:self];
    
    
    }

}


-(void)startServiceForUser:(InstagramUser *)user withDate:(kMediaDate)date
{
    [self startLoadingAnimation];
    ServiceManager *manager = [ServiceManager new];
    [manager getDataForUser:user.Id mediaInterval:date withCompletion:^(NSMutableArray *likeList, StatsModel *stats) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _arrayData = likeList;
            [_viewStatsProfile configureViews:stats];
            [self.viewStatsProfile setNeedsDisplay];
            _statsModel=stats;
            [self.tableView reloadData];
            _labelNameForTitle.text = stats.textName;
            _labelMediaCountInInterval.text= [NSString stringWithFormat:NSLocalizedString(@"%ld Media",nil),(long)stats.filteredPostCount];
            [self removeLoadingAnimation];
            if (stats.filteredPostCount <1) {
                [self setErrorLabelAsNoMedia:YES hidden:NO];
            }
            else
            {
                [self setErrorLabelAsNoMedia:YES hidden:YES];
            }

        });
        
    }withCounting:^(float percentage) {
        
    } failure:^(NSError *error, InstagramFailModel *errorModel) {
        [self removeLoadingAnimation];
         [self showError:errorModel];
    }];
    
    
}


#pragma mark - Animations

-(void)startLoadingAnimation
{
    [[PopUpManager sharedManager]showLoadingPopup:self.navigationController withCancel:^{
        [self.navigationController popViewControllerAnimated:NO];
        [[PopUpManager sharedManager]hideLoading];
        [_buttonChangeDate setTitle:NSLocalizedString(@"Loading Cancelled",nil) forState:UIControlStateNormal];
    }];
}

-(void)removeLoadingAnimation
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[PopUpManager sharedManager]hideLoading];
    });
}

#pragma mark - TableView Methods
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UserLikeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"userLikeCell" forIndexPath:indexPath];
    [cell setFields:[_arrayData objectAtIndex:indexPath.row]];
    
    return cell;
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return  _arrayData.count;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"stalkMyFollower"]) {
        
        MyProfileViewController *destinationViewController = segue.destinationViewController;
        UserLikeTableViewCell *cell = (UserLikeTableViewCell *)sender;
        destinationViewController.user = cell.user;
    }
    if ([segue.identifier isEqualToString:@"showMedia"]) {
        MediaViewController *mediaVC = segue.destinationViewController;
        UserLikeTableViewCell *cell = (UserLikeTableViewCell *)[[sender superview]superview];
        mediaVC.arrayLikedMedias =cell.arrayLikedMedias;
        
    }
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"stalkMyFollower"]|| [identifier isEqualToString:@"showMedia"]) {
        if ([InAppHelper isSubscriptionAvailable]) {
            return YES;
        }else
        {
            [PopUpManager showSubscriptionPopupWith:self];
        }
    }
    return NO;
}



#pragma mark - Error Label 

-(void)setErrorLabelAsNoMedia:(BOOL)type hidden:(BOOL)hidden
{
    if (type) {
        _labelNoMediaWarning.text=NSLocalizedString(@"No media at selected interval, change date interval from above",nil);
    }else
    {
        _labelNoMediaWarning.text=NSLocalizedString(@"This profile is private!",nil);
    }
    
    _labelNoMediaWarning.hidden=hidden;
    
}


#pragma mark - Date Selection

- (IBAction)changeDateButtonPressed:(id)sender {
    [self showDateSelector];
}


-(void)showDateSelector
{

    self.useBlurForPopup=YES;
    _dateSelectPopup = [[DateSelectPopupViewController alloc]initWithNibName:@"DateSelectPopupViewController" bundle:nil];
    _dateSelectPopup.delegate=self;
    
    STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:_dateSelectPopup];
    if (NSClassFromString(@"UIBlurEffect")) {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        popupController.backgroundView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    }
    [STPopupNavigationBar appearance].barTintColor = k_color_navy;
    [STPopupNavigationBar appearance].tintColor = [UIColor whiteColor];
    [STPopupNavigationBar appearance].barStyle = UIBarStyleDefault;
    [STPopupNavigationBar appearance].titleTextAttributes = @{ NSFontAttributeName: [UIFont fontWithName:@"Cochin" size:18], NSForegroundColorAttributeName: [UIColor whiteColor] };
    [STPopupNavigationBar appearance].layer.cornerRadius = 5.0;
    popupController.backgroundView.backgroundColor=[UIColor clearColor];
    popupController.containerView.backgroundColor=[UIColor clearColor];
    [[UIBarButtonItem appearanceWhenContainedIn:[STPopupNavigationBar class], nil] setTitleTextAttributes:@{ NSFontAttributeName:[UIFont fontWithName:@"Cochin" size:17] } forState:UIControlStateNormal];
    popupController.style = STPopupStyleBottomSheet;
    
    [popupController presentInViewController:self];
//    self.popupController=popupController;
}

#pragma mark - Date Selection Delegates

-(void)dateSelectedWith:(kMediaDate)date
{
    [self startServiceForBothWithMedia:date];
    switch (date) {
        case kWeek:
            [_buttonChangeDate setTitle:[_arrayDates objectAtIndex:0] forState:UIControlStateNormal];
            break;
        case kMonth:
            [_buttonChangeDate setTitle:[_arrayDates objectAtIndex:1] forState:UIControlStateNormal];
            break;
        case kThreeMonth:
            [_buttonChangeDate setTitle:[_arrayDates objectAtIndex:2] forState:UIControlStateNormal];
            break;
        case kSixMonth:
            [_buttonChangeDate setTitle:[_arrayDates objectAtIndex:3] forState:UIControlStateNormal];
            break;
        case kAll:
            [_buttonChangeDate setTitle:[_arrayDates objectAtIndex:4] forState:UIControlStateNormal];
            break;
        default:
            [_buttonChangeDate setTitle:[_arrayDates objectAtIndex:4] forState:UIControlStateNormal];
            break;
    }
        [self.popupViewController dismissPopupViewControllerAnimated:YES completion:nil];

    
}

-(void)selectionCancelled
{
    /*
    if (self.popupController) {
        [self.popupController dismiss];
        self.popupController = nil;
    }
     */
    
}



@end
