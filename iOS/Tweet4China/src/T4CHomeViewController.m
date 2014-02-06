//
//  T4CHomeViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-25.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CHomeViewController.h"

@interface T4CHomeViewController ()

@end

@implementation T4CHomeViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.showUnreadCount = YES;
    }
    return self;
}

- (NSString *)apiString
{
    return @"statuses/home_timeline";
}

//#ifdef DEBUG
//- (NSUInteger)requestCount
//{
//    return 3;
//}
//#endif

- (void)requestDidFinishRefreshWithData:(NSArray *)dataArr
{
    [super requestDidFinishRefreshWithData:dataArr];
    
    [[HSUAppDelegate shared] askFollowAuthor];
    [[HSUAppDelegate shared] buyProAppIfOverCount];
}

- (void)requestDidFinishRefreshWithError:(NSError *)error
{
    [super requestDidFinishRefreshWithError:error];
    
    if (!error || error.code == 204) { // no err, no data
        [[HSUAppDelegate shared] buyProAppIfOverCount];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.actionBarButton;
    self.navigationItem.rightBarButtonItems = @[self.composeBarButton, self.searchBarButton];
}

@end
