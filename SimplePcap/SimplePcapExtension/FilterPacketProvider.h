//
//  FilterPacketProvider.h
//  SimplePcapExtension
//
//  Created by Yamin Tian on 6/8/20.
//  Copyright © 2020 Demo. All rights reserved.
//

#import <NetworkExtension/NetworkExtension.h>

@interface FilterPacketProvider : NEFilterPacketProvider

+ (void)handlePacketwithContext: (NEFilterPacketContext *_Nonnull) context
                  fromInterface: (nw_interface_t _Nonnull) interface
                      direction: (NETrafficDirection) direction
                   withRawBytes: (const void *_Nonnull) packetBytes
                         length: (const size_t) packetLength;

@end
