//
//  IPCConnection.m
//  SimplePcapExtension
//
//  Created by Yamin Tian on 7/6/20.
//  Copyright © 2020 Demo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IPCConnection.h"

NSString *myPcapFileName = @"/tmp/mySimplePcap.pcap";
long lastUpdateTime = 0;
size_t pcapSize = 0;

@implementation IPCConnection

static IPCConnection *_sharedInstance;

+ (IPCConnection *)shared
{
    if (_sharedInstance == nil)
    {
        _sharedInstance = [IPCConnection new];
    }

    return _sharedInstance;
}

- (NSString *)extensionMachServiceNameFromBundle:(NSBundle *_Nonnull)bundle
{
    NSDictionary *networkExtensionKeys = [bundle objectForInfoDictionaryKey:@"NetworkExtension"];
    if (nil != networkExtensionKeys)
    {
        NSString *machServiceName = networkExtensionKeys[@"NEMachServiceName"];
        if (nil == machServiceName)
        {
            NSLog(@"Mach service name is missing from the Info.plist");
        }
        return machServiceName;
    }

    return nil;
}

- (void)startListener
{
    NSString *machServiceName = [self extensionMachServiceNameFromBundle:[NSBundle mainBundle]];

    if (machServiceName != nil)
    {
        NSLog(@"Starting XPC listener for mach service: %@", machServiceName);
        NSXPCListener *newListener =
            [[NSXPCListener alloc] initWithMachServiceName:machServiceName];
        newListener.delegate = self;
        [newListener resume];
        self.listener = newListener;
    }
}

- (void)registerWithExtension:(NSBundle *)bundle
                 withDelegate:(NSObject<AppCommunication> *)delegate
        withCompletionHandler:(void (^)(bool success))completionHandler
{
    self.delegate = delegate;

    if (nil != self.currentConnection)
    {
        NSLog(@"Already registered with the provider");
        completionHandler(true);
        return;
    }

    NSXPCConnectionOptions options = {0};
    NSString *machServiceName = [self extensionMachServiceNameFromBundle:bundle];

    NSXPCConnection *newConnection = [[NSXPCConnection alloc] initWithMachServiceName:machServiceName options:options];

    // The exported object is the delegate.
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(AppCommunication)];
    newConnection.exportedObject = delegate;

    // The remote object is the provider's IPCConnection instance.
    newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(ProviderCommunication)];

    self.currentConnection = newConnection;
    [newConnection resume];

    NSObject<ProviderCommunication> *providerProxy =
    [newConnection remoteObjectProxyWithErrorHandler:^(NSError *_Nonnull registerError) {
        NSLog(@"Failed to register with the provider: %@", [registerError localizedDescription]);
        if (self.currentConnection != nil)
        {
            [self.currentConnection invalidate];
            self.currentConnection = nil;
        }
        completionHandler(false);
    }];
    if (nil == providerProxy)
    {
        NSLog(@"Failed to create a remote object proxy for the provider");
    }
    else
    {
        [providerProxy registerWithCompletionHandler:completionHandler];
    }
}

- (BOOL)listener:(NSXPCListener *_Nonnull)listener
shouldAcceptNewConnection:(NSXPCConnection *_Nonnull)newConnection
{
    // The exported object is this IPCConnection instance
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(ProviderCommunication)];
    newConnection.exportedObject = self;

    // The remote object is the delegate of the app's IPCConnection instnace
    newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(AppCommunication)];

    newConnection.invalidationHandler = ^{
        self.currentConnection = nil;
    };

    newConnection.interruptionHandler = ^{
        self.currentConnection = nil;
    };

    self.currentConnection = newConnection;
    [newConnection resume];

    return TRUE;
}

- (void)registerWithCompletionHandler:(void (^_Nonnull)(bool success))completionHandler
{
    NSLog(@"App registered");
    completionHandler(true);
}

- (void)sendPacketToAppWithInterface:(NSString *_Nonnull)interface
                       withTimeStamp:(long)timeSeconds
                     withPacketBytes:(const void *_Nonnull)packetBytes
                          withLength:(const size_t)packetLength
               withCompletionHandler:(void (^_Nonnull)(bool success))reply
{
    if (nil == self.currentConnection)
    {
        reply(false);
        return;
    }

    NSObject<AppCommunication> *appProxy =
        [self.currentConnection remoteObjectProxyWithErrorHandler:^(NSError *_Nonnull error) {
            NSLog(@"Failed to send data to app, err: %@", [error localizedDescription]);
            self.currentConnection = nil;
            reply(false);
        }];

    if (nil == appProxy)
    {
        reply(false);
        return;
    }
    
    // For simplicity, only send a small part of packet info for display on the UI
    uint8_t *p = (uint8_t *)packetBytes;
    NSMutableString *pktInfoString = [NSMutableString stringWithFormat:@"%@: ", interface];
    size_t len = 32;
    bool bAppend = true;
    if (len > packetLength)
    {
        len = packetLength;
        bAppend = false;
    }

    for (int i = 0; i < len; i++)
    {
        NSString *digit = [NSString stringWithFormat:@"%02x ", *p];
        [pktInfoString appendString:digit];

        p++;
    }
    
    if (bAppend)
    {
        [pktInfoString appendString:@"...\n"];
    }
    else
    {
        [pktInfoString appendString:@"\n"];
    }
    
    if (timeSeconds - lastUpdateTime > 5) // limit update frequency
    {
        [appProxy showPcapSizeWithSize:pcapSize
                     completionHandler:^(bool success) {
                         if (!success)
                         {
                             NSLog(@"Unable to update pcap size with app.");
                         }
                     }];

        // So far I don't try to update every packet with the UI
        [appProxy showPacketInfoWithInfo:pktInfoString
                       completionHandler:reply];

        lastUpdateTime = timeSeconds;

        NSLog(@"Update to pcap size = %lu", pcapSize);
    }
    
}

- (void)sendTextMessageToAppWithMessage:(NSString *_Nonnull)message
                   withCompletionHandler:(void (^_Nonnull)(bool success))reply
{
    if (nil == self.currentConnection)
    {
        return;
    }

    NSObject<AppCommunication> *appProxy =
        [self.currentConnection remoteObjectProxyWithErrorHandler:^(NSError *_Nonnull error) {
            NSLog(@"Failed to send message to app, err: %@", [error localizedDescription]);
            self.currentConnection = nil;
            reply(false);
        }];

    if (nil != appProxy)
    {
        [appProxy showTextMessageWithMessage:message
                           completionHandler:reply];
    }
}

@end
