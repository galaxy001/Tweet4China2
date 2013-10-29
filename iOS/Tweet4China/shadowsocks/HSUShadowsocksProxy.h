//
//  HSUShadowsocksProxy.h
//  Test
//
//  Created by Jason Hsu on 13-9-7.
//  Copyright (c) 2013年 Jason Hsu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@interface HSUShadowsocksProxy : NSObject <GCDAsyncSocketDelegate>

- (id)initWithHost:(NSString *)host port:(NSInteger)port password:(NSString *)passoword method:(NSString *)method;
- (BOOL)startWithLocalPort:(NSInteger)localPort; // auto restart
- (void)stop;

@end
