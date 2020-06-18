//
//  FilterPacketProvider.m
//  SimplePcapExtension
//
//  Created by Yamin Tian on 6/8/20.
//  Copyright © 2020 Demo. All rights reserved.
//

#include <sys/time.h>
#import "FilterPacketProvider.h"
typedef struct pcap_hdr_s {
        uint32_t magic_number;   /* magic number */
        uint16_t version_major;  /* major version number */
        uint16_t version_minor;  /* minor version number */
        int32_t  thiszone;       /* GMT to local correction */
        uint32_t sigfigs;        /* accuracy of timestamps */
        uint32_t snaplen;        /* max length of captured packets, in octets */
        uint32_t network;        /* data link type */
} pcap_hdr_t;

typedef struct pcaprec_hdr_s {
        uint32_t ts_sec;         /* timestamp seconds */
        uint32_t ts_usec;        /* timestamp microseconds */
        uint32_t incl_len;       /* number of octets of packet saved in file */
        uint32_t orig_len;       /* actual length of packet */
} pcaprec_hdr_t;

@implementation FilterPacketProvider

- (void)startFilterWithCompletionHandler:(void (^)(NSError *error))completionHandler {

    // pcap initialization
    NSFileManager *filemgr;
    pcap_hdr_t pcapHeader = {0};
    NSData *databuffer = nil;
    BOOL res = NO;

    pcapHeader.magic_number = 0xa1b2c3d4;
    pcapHeader.version_major = 2;
    pcapHeader.version_minor = 4;
    pcapHeader.thiszone = 0; // Set to GMT for now
    pcapHeader.sigfigs = 0;
    pcapHeader.snaplen = 65535;
    pcapHeader.network = 1; // Ethernet for now

    databuffer = [NSData dataWithBytes: &pcapHeader length: (sizeof pcapHeader)];
    filemgr = [NSFileManager defaultManager];

    res = [filemgr createFileAtPath: @"/tmp/mytest.pcap" contents: databuffer attributes: nil];
    if (NO == res)
    {
        NSLog(@"Failed to create pcap file");
    }
    // end pcap initialization

    NSLog(@"startFilterWithCompletionHandler");

	self.packetHandler = ^NEFilterPacketProviderVerdict(NEFilterPacketContext * _Nonnull context, nw_interface_t  _Nonnull interface, NETrafficDirection direction, const void * _Nonnull packetBytes, const size_t packetLength) {

        (void)[FilterPacketProvider handlePacketwithContext: context
                                              fromInterface: interface
                                                  direction: direction
                                               withRawBytes: packetBytes
                                                     length: packetLength];

		return NEFilterPacketProviderVerdictAllow;
	};
    
    completionHandler(nil);
}

- (void)stopFilterWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler {
    // Add code to clean up filter resources.
    completionHandler();
}

+ (void)handlePacketwithContext: (NEFilterPacketContext *_Nonnull) context
                  fromInterface: (nw_interface_t _Nonnull) interface
                      direction: (NETrafficDirection) direction
                   withRawBytes: (const void *_Nonnull) packetBytes
                         length: (const size_t) packetLength
{
    nw_interface_type_t nicType = nw_interface_get_type(interface);
    NSLog(@"Got packet on interface %s, type = %u, index = %u, direction: %ld, length: %zu", nw_interface_get_name(interface), nicType, nw_interface_get_index(interface), direction, packetLength);

    // write pcap
    NSFileHandle *file;
    NSMutableData *data;
    struct timeval tv = {0};

    pcaprec_hdr_t pktHeader = {0};

    gettimeofday(&tv, NULL);

    pktHeader.ts_sec = (uint32_t)tv.tv_sec;
    pktHeader.ts_usec = tv.tv_usec;
    pktHeader.incl_len = (uint32_t)packetLength;
    pktHeader.orig_len = (uint32_t)packetLength;

    data = [NSMutableData dataWithBytes: &pktHeader length: sizeof(pktHeader)];
    [data appendBytes: packetBytes length: packetLength];

    file = [NSFileHandle fileHandleForUpdatingAtPath: @"/tmp/mytest.pcap"];

    if (file != nil)
    {
        [file seekToEndOfFile];

        [file writeData: data];

        [file closeFile];

        NSLog(@"Wrote %lu bytes to file.", packetLength);
    }
    else
    {
        NSLog(@"Failed to open file");
    }
    // end write pcap
}

@end
