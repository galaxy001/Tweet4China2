//
//  HSUShadowsocksProxy.m
//  Test
//
//  Created by Jason Hsu on 13-9-7.
//  Copyright (c) 2013年 Jason Hsu. All rights reserved.
//

#import "HSUShadowsocksProxy.h"
#import "GCDAsyncSocket.h"
#include "encrypt.h"
#include "socks5.h"
#include <arpa/inet.h>

#define ADDR_STR_LEN 512

@interface HSUShadowsocksPipeline : NSObject
{
 @public
    struct encryption_ctx sendEncryptionContext;
    struct encryption_ctx recvEncryptionContext;
}

@property (nonatomic, strong) GCDAsyncSocket *localSocket;
@property (nonatomic, strong) GCDAsyncSocket *remoteSocket;
@property (nonatomic, assign) int stage;

- (void)disconnect;

@end

@implementation HSUShadowsocksPipeline

- (void)disconnect
{
    [self.localSocket disconnectAfterReadingAndWriting];
    [self.remoteSocket disconnectAfterReadingAndWriting];
}

@end


@implementation HSUShadowsocksProxy
{
    dispatch_queue_t _socketQueue;
    GCDAsyncSocket *_serverSocket;
    NSMutableArray *_pipelines;
    NSString *_host;
    NSInteger _port;
}

- (HSUShadowsocksPipeline *)pipelineOfLocalSocket:(GCDAsyncSocket *)localSocket
{
    __block HSUShadowsocksPipeline *ret;
    [_pipelines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        HSUShadowsocksPipeline *pipeline = obj;
        if (pipeline.localSocket == localSocket) {
            ret = pipeline;
        }
    }];
    return ret;
}

- (HSUShadowsocksPipeline *)pipelineOfRemoteSocket:(GCDAsyncSocket *)remoteSocket
{
    __block HSUShadowsocksPipeline *ret;
    [_pipelines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        HSUShadowsocksPipeline *pipeline = obj;
        if (pipeline.remoteSocket == remoteSocket) {
            ret = pipeline;
        }
    }];
    return ret;
}

- (void)dealloc
{
    _serverSocket = nil;
    _pipelines = nil;
    _host = nil;
}

- (id)initWithHost:(NSString *)host port:(NSInteger)port password:(NSString *)passoword method:(NSString *)method
{
    self = [super init];
    if (self) {
        _host = [host copy];
        _port = port;
        config_encryption([passoword cStringUsingEncoding:NSASCIIStringEncoding],
                          [method cStringUsingEncoding:NSASCIIStringEncoding]);
    }
    return self;
}

- (BOOL)startWithLocalPort:(NSInteger)localPort
{
    [self stop];
    _socketQueue = dispatch_queue_create("me.tuoxie.shadowsocks", NULL);
    _serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];
    NSError *error;
    [_serverSocket acceptOnPort:localPort error:&error];
    if (error) {
        NSLog(@"bind failed, %@", error);
        return NO;
    }
    _pipelines = [[NSMutableArray alloc] init];
    return YES;
}

- (void)stop
{
    [_serverSocket disconnect];
    [_pipelines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        HSUShadowsocksPipeline *pipeline = obj;
        [pipeline.localSocket disconnect];
        [pipeline.remoteSocket disconnect];
    }];
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    HSUShadowsocksPipeline *pipeline = [[HSUShadowsocksPipeline alloc] init];
    pipeline.localSocket = newSocket;
    
    GCDAsyncSocket *remoteSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];
    [remoteSocket connectToHost:_host onPort:_port error:nil];
    pipeline.remoteSocket = remoteSocket;
    
    init_encryption(&(pipeline->sendEncryptionContext));
    init_encryption(&(pipeline->recvEncryptionContext));
    
    [_pipelines addObject:pipeline];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    HSUShadowsocksPipeline *pipeline = [self pipelineOfRemoteSocket:sock];
    GCDAsyncSocket *localSocket = pipeline.localSocket;
    [localSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    HSUShadowsocksPipeline *pipeline =
    [self pipelineOfLocalSocket:sock] ?: [self pipelineOfRemoteSocket:sock];
    int len = data.length;
    if (tag == 0) {
        // write version + method
        [pipeline.localSocket
         writeData:[NSData dataWithBytes:"\x05\x00" length:2]
         withTimeout:-1
         tag:0];
    } else if (tag == 1) {
        struct socks5_request *request = (struct socks5_request *)data.bytes;
        if (request->cmd != SOCKS_CMD_CONNECT) {
            NSLog(@"unsupported cmd: %d", request->cmd);
            struct socks5_response response;
            response.ver = SOCKS_VERSION;
            response.rep = SOCKS_CMD_NOT_SUPPORTED;
            response.rsv = 0;
            response.atyp = SOCKS_IPV4;
            char *send_buf = (char *)&response;
            [pipeline.localSocket writeData:[NSData dataWithBytes:send_buf length:4] withTimeout:-1 tag:1];
            [pipeline disconnect];
            return;
        }
        
        char addr_to_send[ADDR_STR_LEN];
        int addr_len = 0;
        addr_to_send[addr_len++] = request->atyp;
        
        char addr_str[ADDR_STR_LEN];
        // get remote addr and port
        if (request->atyp == SOCKS_IPV4) {
            // IP V4
            size_t in_addr_len = sizeof(struct in_addr);
            memcpy(addr_to_send + addr_len, data.bytes + 4, in_addr_len + 2);
            addr_len += in_addr_len + 2;
            
            // now get it back and print it
            inet_ntop(AF_INET, data.bytes + 4, addr_str, ADDR_STR_LEN);
        } else if (request->atyp == SOCKS_DOMAIN) {
            // Domain name
            unsigned char name_len = *(unsigned char *)(data.bytes + 4);
            addr_to_send[addr_len++] = name_len;
            memcpy(addr_to_send + addr_len, data.bytes + 4 + 1, name_len);
            memcpy(addr_str, data.bytes + 4 + 1, name_len);
            addr_str[name_len] = '\0';
            addr_len += name_len;
            
            // get port
            addr_to_send[addr_len++] = *(unsigned char *)(data.bytes + 4 + 1 + name_len);
            addr_to_send[addr_len++] = *(unsigned char *)(data.bytes + 4 + 1 + name_len + 1);
        } else {
            NSLog(@"unsupported addrtype: %d", request->atyp);
            [pipeline disconnect];
            return;
        }
        
        encrypt_buf(&(pipeline->sendEncryptionContext), addr_to_send, &addr_len);
        [pipeline.remoteSocket
         writeData:[NSData dataWithBytes:addr_to_send length:addr_len]
         withTimeout:-1
         tag:2];
        
        // Fake reply
        struct socks5_response response;
        response.ver = SOCKS_VERSION;
        response.rep = 0;
        response.rsv = 0;
        response.atyp = SOCKS_IPV4;
        
        struct in_addr sin_addr;
        inet_aton("0.0.0.0", &sin_addr);
        
        int reply_size = 4 + sizeof(struct in_addr) + sizeof(unsigned short);
        char *replayBytes = (char *)malloc(reply_size);
        
        memcpy(replayBytes, &response, 4);
        memcpy(replayBytes + 4, &sin_addr, sizeof(struct in_addr));
        *((unsigned short *)(replayBytes + 4 + sizeof(struct in_addr)))
        = (unsigned short) htons(atoi("22"));
        
        [pipeline.localSocket
         writeData:[NSData dataWithBytes:replayBytes length:reply_size]
         withTimeout:-1
         tag:3];
        free(replayBytes);
    } else if (tag == 2) {
        encrypt_buf(&(pipeline->sendEncryptionContext), (char *)data.bytes, &len);
        [pipeline.remoteSocket writeData:data withTimeout:-1 tag:4];
    } else if (tag == 3) {
        decrypt_buf(&(pipeline->recvEncryptionContext), (char *)data.bytes, &len);
        [pipeline.localSocket writeData:data withTimeout:-1 tag:3];
    }
    
    return;
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    HSUShadowsocksPipeline *pipeline =
    [self pipelineOfLocalSocket:sock] ?: [self pipelineOfRemoteSocket:sock];
    
    if (tag == 0) {
        [pipeline.localSocket readDataWithTimeout:-1 tag:1];
    } else if (tag == 1) {
        
    } else if (tag == 2) {
        
    } else if (tag == 3) {
        [pipeline.remoteSocket readDataWithTimeout:-1 buffer:nil bufferOffset:0 maxLength:4096 tag:3];
        [pipeline.localSocket readDataWithTimeout:-1 buffer:nil bufferOffset:0 maxLength:4096 tag:2];
    } else if (tag == 4) {
        [pipeline.remoteSocket readDataWithTimeout:-1 buffer:nil bufferOffset:0 maxLength:4096 tag:3];
        [pipeline.localSocket readDataWithTimeout:-1 buffer:nil bufferOffset:0 maxLength:4096 tag:2];
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    HSUShadowsocksPipeline *pipeline;
    
    pipeline = [self pipelineOfRemoteSocket:sock];
    if (pipeline) { // disconnect remote
        if (pipeline.localSocket.isDisconnected) {
            [_pipelines removeObject:pipeline];
            // encrypt code
            cleanup_encryption(&(pipeline->sendEncryptionContext));
            cleanup_encryption(&(pipeline->recvEncryptionContext));
        } else {
            [pipeline.localSocket disconnectAfterReadingAndWriting];
        }
        return;
    }
    
    pipeline = [self pipelineOfLocalSocket:sock];
    if (pipeline) { // disconnect local
        if (pipeline.remoteSocket.isDisconnected) {
            [_pipelines removeObject:pipeline];
            // encrypt code
            cleanup_encryption(&(pipeline->sendEncryptionContext));
            cleanup_encryption(&(pipeline->recvEncryptionContext));
        } else {
            [pipeline.remoteSocket disconnectAfterReadingAndWriting];
        }
        return;
    }
}

@end
