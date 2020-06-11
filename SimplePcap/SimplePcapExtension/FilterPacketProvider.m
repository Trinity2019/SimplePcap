//
//  FilterPacketProvider.m
//  SimplePcapExtension
//
//  Created by Yamin Tian on 6/8/20.
//  Copyright © 2020 Demo. All rights reserved.
//

#import "FilterPacketProvider.h"

@implementation FilterPacketProvider

- (void)startFilterWithCompletionHandler:(void (^)(NSError *error))completionHandler {

    NSLog(@"startFilterWithCompletionHandler");

	self.packetHandler = ^NEFilterPacketProviderVerdict(NEFilterPacketContext * _Nonnull context, nw_interface_t  _Nonnull interface, NETrafficDirection direction, const void * _Nonnull packetBytes, const size_t packetLength) {
		return NEFilterPacketProviderVerdictAllow;
	};
    
    completionHandler(nil);
}

- (void)stopFilterWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler {
    // Add code to clean up filter resources.
    completionHandler();
}

@end
