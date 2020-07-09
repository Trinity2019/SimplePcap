//
//  IPCConnection.h
//  SimplePcapExtension
//
//  Created by Yamin Tian on 7/6/20.
//  Copyright © 2020 Demo. All rights reserved.
//

#ifndef IPCConnection_h
#define IPCConnection_h

#import <Foundation/Foundation.h>

/// SimplePcap app --> SimplePcapExtension communication
@protocol ProviderCommunication<NSObject>

- (void)registerWithCompletionHandler:(void (^_Nonnull)(bool success))completionHandler;

@end

/// SimplePcapExtension --> SimplePcap app communication
@protocol AppCommunication<NSObject>

// This method shows the information about a packet on the UI
- (void)showPacketInfoWithInfo:(NSString *_Nonnull)pktInfo
             completionHandler:(void (^_Nonnull)(bool success))reply;

- (void)showTextMessageWithMessage:(NSString *_Nonnull)message
                 completionHandler:(void (^_Nonnull)(bool success))reply;

- (void)showPcapSizeWithSize:(const size_t)pcapSize
           completionHandler:(void (^_Nonnull)(bool success))reply;
@end

/// IPCConnection class is shared by both SimplePcap app and SimplePcapExtension to communicate with each other
@interface IPCConnection : NSObject<NSXPCListenerDelegate, ProviderCommunication>

@property(nonatomic, retain) NSXPCListener *_Nonnull listener;

@property(nonatomic, retain) NSXPCConnection *_Nullable currentConnection;

@property(nonatomic, weak) NSObject<AppCommunication> *_Nullable delegate;

+ (IPCConnection *_Nonnull)shared;

- (void)startListener;

- (NSString *_Nullable)extensionMachServiceNameFromBundle:(NSBundle *_Nonnull)bundle;

/// This method is called by SimplePcap app to register with the IPC provider running in the system extension.
- (void)registerWithExtension:(NSBundle *_Nonnull)bundle
              withDelegate:(NSObject<AppCommunication> *_Nonnull)delegate
     withCompletionHandler:(void (^_Nonnull)(bool success))completionHandler;

- (BOOL)listener:(NSXPCListener *_Nonnull)listener
    shouldAcceptNewConnection:(NSXPCConnection *_Nonnull)newConnection;

- (void)sendPacketToAppWithInterface:(NSString *_Nonnull)interface
                       withTimeStamp:(long)timeSeconds
                     withPacketBytes:(const void *_Nonnull)packetBytes
                          withLength:(const size_t)packetLength
               withCompletionHandler:(void (^_Nonnull)(bool success))reply;

- (void)sendTextMessageToAppWithMessage:(NSString *_Nonnull)message
                  withCompletionHandler:(void (^_Nonnull)(bool success))reply;

@end

extern NSString * _Nonnull myPcapFileName;

#endif /* IPCConnection_h */
