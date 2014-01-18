//
//  HSUAboutViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-18.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUAboutViewController.h"
#import <RETableViewManager/RETableViewManager.h>
#import <RETableViewManager/RETableViewOptionsController.h>
#import "HSUProfileViewController.h"

@interface HSUAboutViewController ()

@end

@implementation HSUAboutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    __weak typeof(self)weakSelf = self;
    RETableViewSection *section = [RETableViewSection section];
    [self.manager addSection:section];
    [section addItem:
     [RETableViewItem itemWithTitle:_("Developer @tuoxie007")
                      accessoryType:UITableViewCellAccessoryNone
                   selectionHandler:^(RETableViewItem *item)
      {
          HSUProfileViewController *profileVC = [[HSUProfileViewController alloc] initWithScreenName:@"tuoxie007"];
          [weakSelf.navigationController pushViewController:profileVC animated:YES];
          [item deselectRowAnimated:YES];
      }]];
    [section addItem:
     [RETableViewItem itemWithTitle:_("OpenSource Tweet4China2")
                      accessoryType:UITableViewCellAccessoryNone
                   selectionHandler:^(RETableViewItem *item)
      {
          NSString *url = @"https://github.com/tuoxie007/tweet4china2";
          [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
          [item deselectRowAnimated:YES];
      }]];
    [section addItem:
     [RETableViewItem itemWithTitle:_("OpenSource OpenCam")
                      accessoryType:UITableViewCellAccessoryNone
                   selectionHandler:^(RETableViewItem *item)
      {
          NSString *url = @"https://github.com/tuoxie007/OpenCam";
          [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
          [item deselectRowAnimated:YES];
      }]];
    [section addItem:
     [RETableViewItem itemWithTitle:_("Official Blog")
                      accessoryType:UITableViewCellAccessoryNone
                   selectionHandler:^(RETableViewItem *item)
      {
          NSString *url = @"http://tweet4china.tumblr.com";
          [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
          [item deselectRowAnimated:YES];
      }]];
    RETableViewItem *item =
    [RETableViewItem itemWithTitle:[HSUCommonTools version]
                     accessoryType:UITableViewCellAccessoryNone
                  selectionHandler:nil];
    item.selectionStyle = UITableViewCellSelectionStyleNone;
    [section addItem:item];
}

@end
