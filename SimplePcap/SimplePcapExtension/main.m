//
//  main.m
//  SimplePcapExtension
//
//  Created by Yamin Tian on 6/8/20.
//  Copyright © 2020 Demo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NetworkExtension/NetworkExtension.h>

int main(int argc, char *argv[])
{
    @autoreleasepool {
        [NEProvider startSystemExtensionMode];
    }
    
    dispatch_main();
}
