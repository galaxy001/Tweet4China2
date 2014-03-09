//
//  HSUServerList.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-18.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUServerList.h"

@implementation HSUServerList

- (id)init
{
    self = [super init];
    if (self) {
        self.responseData = [NSMutableData data];
    }
    return self;
}

- (void)updateServerList
{
    GCDAsyncSocket *socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    self.socket = socket;
    [socket connectToHost:@"tuoxie.me" onPort:80 withTimeout:10 error:nil];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
#ifdef DEBUG
    NSString *requestString = @"GET /tw.ss.json.test "
#else
    NSString *requestString = @"GET /tw.ss.json "
#endif
    @"HTTP/1.1\r\nHost: tuoxie.me\r\nConnection: close\r\n\r\n";
    NSData *requestData = [requestString dataUsingEncoding:NSUTF8StringEncoding];
    [sock writeData:requestData withTimeout:10 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    [sock readDataWithTimeout:10 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    [self.responseData appendData:data];
    [sock readDataWithTimeout:10 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSString *responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    NSUInteger loc = [responseString rangeOfString:@"\r\n\r\n"].location;
    if (loc != NSNotFound) {
        NSData *jsonData = [self.responseData subdataWithRange:NSMakeRange(loc, self.responseData.length-loc)];
        if (jsonData) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
            if (json) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ShadowsocksServerListUpdatedNotification" object:json];
            }
        }
    }
}

@end
