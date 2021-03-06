//
//  StalkListViewController.m
//  Instalker
//
//  Created by umut on 1/26/16.
//  Copyright © 2016 SmartClick. All rights reserved.
//

#import "StalkListViewController.h"
#import "ServiceManager.h"
#import "StalkProfileViewController.h"


@interface StalkListViewController ()

@property (nonatomic,strong) UIGestureRecognizer *gest;
@end

@implementation StalkListViewController

#pragma mark - Life

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setDelegates];
    [self addProtector];
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self getSearchHistory];
    self.navigationController.title = NSLocalizedString(@"Search",nil);
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Search"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    [self configureNavigationProperties];
}
-(void)configureNavigationProperties
{
    self.navigationItem.titleView.tintColor = [UIColor whiteColor];
    
    self.navigationController.navigationBar.backItem.titleView.tintColor= [UIColor whiteColor];
    self.navigationController.navigationBar.backItem.title = NSLocalizedString(@"Back",nil);
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Animations
-(void)startLoadingAnimation
{


}

-(void)removeLoadingAnimation
{


}
#pragma mark - View configuration
-(void)setDelegates
{
    _tableView.delegate = self;
    _searchBar.delegate = self;
    _tableView.dataSource = self;

}



#pragma mark - Service Actions
-(void)getSearchHistory
{
    _arraySearchList = (NSMutableArray *)[[[Singleton sharedInstance].arraySearchHistory reverseObjectEnumerator] allObjects];;
    [_tableView reloadData];
    
}
-(void)updateSearchHistory:(InstagramUser *)user
{
    
    if ([[Singleton sharedInstance].arraySearchHistory containsObject:user]) {
        [[Singleton sharedInstance].arraySearchHistory removeObject:user];
        [[Singleton sharedInstance] addArraySearchHistoryObjectAndUpdate:user];
    }else
    {
        [[Singleton sharedInstance] addArraySearchHistoryObjectAndUpdate:user];
    }
//    if ([Singleton sharedInstance].arraySearchHistory) {
//        NSMutableArray *array = [NSMutableArray arrayWithArray:[Singleton sharedInstance].arraySearchHistory];
//        [[NSUserDefaults standardUserDefaults] setObject:array forKey:k_Search_History_List];
//    }


}

-(void)searchUsersWithKeyword:(NSString *)keyword
{
    [[ServiceManager sharedManager] searchUsersWithKeyword:keyword completion:^(NSMutableArray *result) {
        _arraySearchList = result;
        [_tableView reloadData];
    } failed:^(NSError *error) {
        
        
    }];

}

#pragma mark - Search Bar Delegates
-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    

}



#pragma mark - Keyboard

-(void)addProtector
{

    _gest = [[UIGestureRecognizer alloc]initWithTarget:self action:@selector(closeKeyboard)];
    _gest.delegate=self;
    _gest.cancelsTouchesInView=NO;

    [self.tableView addGestureRecognizer:_gest];
    

}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    [self closeKeyboard];
    return YES;
}
-(void)closeKeyboard
{
    [_searchBar resignFirstResponder];
    [self.view endEditing:YES];
}





#pragma mark - TableView Methods
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SearchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"searchCell" forIndexPath:indexPath];
    
    [cell configureViews:[_arraySearchList objectAtIndex:indexPath.row]];
    
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    InstagramUser *user = [_arraySearchList objectAtIndex:indexPath.row ];
    [self updateSearchHistory:user];
   
    
    
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    return _arraySearchList.count;

}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self searchUsersWithKeyword:searchText];

}
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self searchUsersWithKeyword:searchBar.text];
    [_searchBar resignFirstResponder];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self getSearchHistory];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"stalk"]) {
        StalkProfileViewController *destinationViewController = segue.destinationViewController;
        UserLikeTableViewCell *cell = (UserLikeTableViewCell *)sender;
        destinationViewController.user = cell.user;


    }

}
-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"stalk"]) {
        if ([InAppHelper isSubscriptionAvailable]) {
            return YES;
        }else
        {
            
            [PopUpManager showSubscriptionPopupWith:self];
        }
    }
    return NO;
}


@end
