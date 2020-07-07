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

- (void)showPacketWithInterface:(NSString *_Nonnull)interface
                withPacketBytes:(NSData * _Nonnull)packetBytes
          withCompletionHandler:(void (^_Nonnull)(bool success))reply;

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

/// This method implements protocol ProviderCommunication
- (void)registerWithCompletionHandler:(void (^_Nonnull)(bool success))completionHandler;

@end

#endif /* IPCConnection_h */
