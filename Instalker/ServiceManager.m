//
//  ServiceManager.m
//  Instalker
//
//  Created by umut on 1/26/16.
//  Copyright © 2016 SmartClick. All rights reserved.
//

#import "ServiceManager.h"

#import <AFNetworking/AFNetworking.h>
#import <InstagramKit/InstagramKit.h>
#import "UserLikeCountModel.h"



@implementation ServiceManager


#pragma mark - Inıt
+(ServiceManager *)sharedManager
{
    static ServiceManager *_sharedManager = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate,^{ _sharedManager = [[ServiceManager alloc]init];});
    return  _sharedManager;
}

-(id)init
{
    
    if (self) {
        _followerList=[NSMutableArray array];
    }
    return self;
}

-(void)clean{
    _arrayLikes = nil;
    _followerList = nil;
    _reducedLikeList = nil;
    _arrayLikes = nil;
    
    _totalLikesCount = nil;
    _follewersCount = nil;
    _follewingsCount = nil;
    _totalPostCount = nil;
    _userName = nil;
    _profileImageURL = nil;
    
    
    
    
}

#pragma mark - Profile

-(void)getMyProfileInfoWithCompletion:(completionRaw)completion
{
    [[InstagramEngine sharedEngine] getSelfUserDetailsWithSuccess:^(InstagramUser * _Nonnull user) {
        
        _follewersCount =[NSNumber numberWithInteger:user.followedByCount];
        _follewingsCount = [NSNumber numberWithInteger:user.followsCount];
        _totalPostCount = [NSNumber numberWithInteger:user.mediaCount];
        _profileImageURL = user.profilePictureURL;
        if (completion) {
            completion();
        }
        
    } failure:^(NSError * _Nonnull error, NSInteger serverStatusCode) {
        
    }];
    
}
-(void)getProfileInfoWith:(NSString *)userID
{
    [[InstagramEngine sharedEngine]getUserDetails:userID withSuccess:^(InstagramUser * _Nonnull user) {
        
    } failure:^(NSError * _Nonnull error, NSInteger serverStatusCode) {
        
    }];
}


#pragma mark - Follewers
-(void)getFollowersOfUser:(NSString *)userID
{
    [[InstagramEngine sharedEngine]getFollowersOfUser:userID withSuccess:^(NSArray<InstagramUser *> * _Nonnull users, InstagramPaginationInfo * _Nonnull paginationInfo) {
        _follewersCount=[NSNumber numberWithInt:(int) users.count];
        
    } failure:^(NSError * _Nonnull error, NSInteger serverStatusCode) {
        
    }];
    
}

#pragma mark - Followings
-(void )getFollowsOfUser:(NSString *)userID{
    
    [[InstagramEngine sharedEngine] getUsersFollowedByUser:userID withSuccess:^(NSArray<InstagramUser *> * _Nonnull users, InstagramPaginationInfo * _Nonnull paginationInfo) {
        _follewingsCount =[NSNumber numberWithInt:(int)users.count];
        
    } failure:^(NSError * _Nonnull error, NSInteger serverStatusCode) {
        
    }];
    
}

#pragma  mark - Get medias of user
-(void)getmediaOfUser:(NSString *)userID forMonths:(NSInteger)numberOfMonth withCompletion:(completion)completion
{
    [[InstagramEngine sharedEngine] getMediaForUser:userID withSuccess:^(NSArray<InstagramMedia *> * _Nonnull media, InstagramPaginationInfo * _Nonnull paginationInfo) {
        
        [self getLikesForMedias:media withCompletion:^(NSMutableArray *result) {
            if (completion) {
                completion(result);
            }
            
        }];
    } failure:^(NSError * _Nonnull error, NSInteger serverStatusCode) {
        
        
    }];
    
}


-(void )getMediasWithCompletion:(completion)completion{
    
    
    [[InstagramEngine sharedEngine] getSelfRecentMediaWithSuccess:^(NSArray<InstagramMedia *> * _Nonnull media, InstagramPaginationInfo * _Nonnull paginationInfo) {
        if (completion) {
            completion(media);
        }
        
    } failure:^(NSError * _Nonnull error, NSInteger serverStatusCode) {
        
    }];
}


#pragma mark - Sort Media By Date Intervals
-(NSArray *)sortMedia:(NSArray *)media from:(NSInteger )numberOfDays to:(NSInteger)endDayNumber
{
    //daily start
    NSDate *date = [NSDate date];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setDay:-numberOfDays];
    date = [[NSCalendar currentCalendar] dateByAddingComponents:dateComponents toDate:date options:0];
    
    //end date
    NSDate *endDate = [NSDate date];
    NSDateComponents *endDateComponents = [[NSDateComponents alloc] init];
    [endDateComponents setDay:-endDayNumber];
    endDate = [[NSCalendar currentCalendar] dateByAddingComponents:endDateComponents toDate:endDate options:0];
    
    
    
    NSMutableArray *result = [NSMutableArray array];
    
    for (InstagramMedia* photo in media ) {
        if ([photo.createdDate laterDate:date] && [photo.createdDate earlierDate:endDate]) {
            [result addObject:photo];
        }
    }
    
    
    return result;
}

-(NSArray *)sortMedia:(NSArray *)media forMonth:(NSInteger)numberOfMonths toMonth:(NSInteger)endNumberOfMonths
{
    //one month
    NSDate *date = [NSDate date];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setMonth:-numberOfMonths];
    date = [[NSCalendar currentCalendar] dateByAddingComponents:dateComponents toDate:date options:0];
    
    //end date
    NSDate *endDate = [NSDate date];
    NSDateComponents *endDateComponents = [[NSDateComponents alloc] init];
    [endDateComponents setMonth:-endNumberOfMonths];
    endDate = [[NSCalendar currentCalendar] dateByAddingComponents:endDateComponents toDate:endDate options:0];
    
    
    
    
    NSMutableArray *result = [NSMutableArray array];
    
    for (InstagramMedia* photo in media ) {
        if ([photo.createdDate laterDate:date] && [photo.createdDate earlierDate:endDate]) {
            [result addObject:photo];
        }
    }
    
    return result;
}

#pragma mark - Likes For Medias

-(void)getLikesForMedias:(NSArray *)media withCompletion:(completion)completion
{
    _arrayLikes = [NSMutableArray array];
    _reducedLikeList = [NSMutableDictionary dictionary];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        __block int ready=0;
        
        for (InstagramMedia *dict in media) {
            
            NSString *mediaID = dict.Id;
            
            [[InstagramEngine sharedEngine] getLikesOnMedia:mediaID withSuccess:^(NSArray<InstagramUser *> * _Nonnull users, InstagramPaginationInfo * _Nonnull paginationInfo) {
                
                
                [_arrayLikes addObjectsFromArray:users];
                ready++;
                
                if (ready+1 > media.count) {
                    dispatch_semaphore_signal(sema);
                }
                
                
            } failure:^(NSError * _Nonnull error, NSInteger serverStatusCode) {
                dispatch_semaphore_signal(sema);
            }];
            
        }
        
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        NSMutableDictionary *users = [NSMutableDictionary dictionary];
        
        
        for (InstagramUser *usr  in _arrayLikes) {
            
            if( [_reducedLikeList objectForKey:usr.username] )
            {
                NSNumber *count = [_reducedLikeList objectForKey:usr.username];
                NSNumber *updated= [NSNumber numberWithInt:count.intValue+1];
                [_reducedLikeList setObject:updated forKey:usr.username];
            }
            else
            {
                NSNumber *one = [NSNumber numberWithInt:1];
                [_reducedLikeList setObject:one forKey:usr.username];
                [users setObject:usr forKey:usr.username];
            }
            
        }
        
        
        NSArray *orderedKeys = [_reducedLikeList keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2){
            
            return [obj2 compare:obj1];
            
        }];
        
        NSMutableArray *orderedUserLike = [NSMutableArray array];
        
        for (NSString *key in orderedKeys) {
            
            UserLikeCountModel *obj = [[UserLikeCountModel alloc]initWithUser:[users objectForKey:key] withLike:[_reducedLikeList objectForKey:key]];
            [orderedUserLike addObject:obj];
            
            
            
        }
        
        //reduce th array
        if (completion) {
            completion(orderedUserLike);
        }
        
    });
    
}

#pragma mark - Comments

-(void)getCommentsForMedia:(NSArray *)media withCompletion:(completionRaw)completion
{
    _arrayComments = [NSMutableArray array];
    _totalComments = [NSNumber numberWithInt:0];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        __block int ready=0;
        for (InstagramMedia *dict in media) {
            NSString *mediaID = dict.Id;
            
            [[InstagramEngine sharedEngine] getCommentsOnMedia:mediaID withSuccess:^(NSArray<InstagramComment *> * _Nonnull comments, InstagramPaginationInfo * _Nonnull paginationInfo) {
                
                
                _totalComments = [NSNumber numberWithInt:[_totalComments intValue] + (int)comments.count ];
                
                ready++;
                
                if (ready+1 > media.count) {
                    dispatch_semaphore_signal(sema);
                }
                
                
            } failure:^(NSError * _Nonnull error, NSInteger serverStatusCode) {
                
            }];
            
            
        }
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        if (completion) {
            completion();
        }
        
    });
    
    
    
    
}


#pragma mark - Final Methods

-(void)getSelfDataWithCompletion:(completionFinal)completion
{
    [self clean];
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        [self getMediasWithCompletion:^(NSMutableArray *result) {
            _allMedia = result;
            dispatch_semaphore_signal(sema);
        }];
    });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    dispatch_semaphore_t sema2 = dispatch_semaphore_create(0);
    __block int callCount = 0;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        
        [self getMyProfileInfoWithCompletion:^{
            callCount++;
            if (callCount>2) {
                dispatch_semaphore_signal(sema2);
            }
        }];
        
        [self getCommentsForMedia:_allMedia withCompletion:^{
            callCount++;
            if (callCount>2) {
                dispatch_semaphore_signal(sema2);
            }
            
        }];
        
        [self getLikesForMedias:_allMedia withCompletion:^(NSMutableArray *result) {
            
            _followerList  = result;
            
            callCount++;
            if (callCount>2) {
                dispatch_semaphore_signal(sema2);
            }
            
        }];
    });
    dispatch_semaphore_wait(sema2, DISPATCH_TIME_FOREVER);
    
    StatsModel *model = [StatsModel new];
    [model setImageURLString:_profileImageURL
                    textName:_userName
               followerCount:_follewersCount
                followsCount:_follewingsCount
                  totalLikes:_totalLikesCount
              totalPostCount:_totalPostCount
               totalComments:_totalComments];
    
    if (completion) {
        completion(_followerList,model);
    }
    
    
}



@end